import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_status.dart';
import '../models/user_model.dart';
import 'student_service.dart';

// Conditional import for web
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as download_helper;

/// Service for generating attendance reports.
class AttendanceReportService {
  final StudentService _studentService;

  AttendanceReportService({required StudentService studentService})
      : _studentService = studentService;

  /// Generate a monthly CSV report for multiple students (all students in a school).
  /// On web: triggers browser download. On mobile: opens share sheet.
  Future<void> generateMonthlyCSVForMultipleStudents({
    required List<UserModel> students,
    required String schoolName,
  }) async {
    // Calculate date range: 1st of current month to today
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);

    // Build CSV rows
    final List<List<String>> rows = [
      ['Student Name', 'Date', 'Check-In', 'Check-Out', 'Total Hours', 'Sessions'],
    ];

    // Fetch records for each student
    for (final student in students) {
      final studentName = student.name ?? student.username;
      
      for (var date = firstOfMonth;
          date.isBefore(now) || date.isAtSameMomentAs(now);
          date = date.add(const Duration(days: 1))) {
        final dateString = _formatDate(date);
        final status = await _studentService.getDailyStatus(student.uid, dateString);
        
        if (status != null && status.sessions.isNotEmpty) {
          rows.add([
            studentName,
            status.date,
            _formatTime(status.checkInTime),
            _formatTime(status.checkOutTime),
            _formatDuration(status.totalDuration),
            '${status.sessions.length}',
          ]);
        }
      }
    }

    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(rows);

    // Generate filename
    final monthName = _getMonthName(now.month);
    final filename = '${schoolName.replaceAll(' ', '_')}_All_Students_Attendance_${monthName}_${now.year}.csv';

    if (kIsWeb) {
      // Web: Use browser download
      download_helper.downloadFile(csvString, filename);
    } else {
      // Mobile: Save to app documents directory and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvString);

      debugPrint('CSV saved to: ${file.path}');

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report - $schoolName',
      );

      debugPrint('Share result: ${result.status}');
    }
  }

  /// Generate a monthly CSV report for a student.
  /// On web: triggers browser download. On mobile: opens share sheet.
  Future<void> generateMonthlyCSV({
    required String studentId,
    required String studentName,
  }) async {
    // Calculate date range: 1st of current month to today
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);

    // Fetch all daily status records for the month
    final records = <DailyStatus>[];
    
    for (var date = firstOfMonth;
        date.isBefore(now) || date.isAtSameMomentAs(now);
        date = date.add(const Duration(days: 1))) {
      final dateString = _formatDate(date);
      final status = await _studentService.getDailyStatus(studentId, dateString);
      if (status != null) {
        records.add(status);
      }
    }

    // Build CSV rows
    final List<List<String>> rows = [
      ['Date', 'Check-In', 'Check-Out', 'Total Hours', 'Sessions'],
    ];

    for (final record in records) {
      rows.add([
        record.date,
        _formatTime(record.checkInTime),
        _formatTime(record.checkOutTime),
        _formatDuration(record.totalDuration),
        '${record.sessions.length}',
      ]);
    }

    // Add summary row
    final totalDuration = records.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.totalDuration,
    );
    rows.add([]);
    rows.add(['Total', '', '', _formatDuration(totalDuration), '']);

    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(rows);

    // Generate filename
    final monthName = _getMonthName(now.month);
    final filename = '${studentName.replaceAll(' ', '_')}_Attendance_${monthName}_${now.year}.csv';

    if (kIsWeb) {
      // Web: Use browser download
      download_helper.downloadFile(csvString, filename);
    } else {
      // Mobile: Save to temp directory and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvString);

      debugPrint('CSV saved to: ${file.path}');

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report - $studentName',
      );

      debugPrint('Share result: ${result.status}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

