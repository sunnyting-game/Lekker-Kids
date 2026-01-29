import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/today_display_status.dart';
import '../services/student_service.dart';

/// ViewModel for Attendance Tab
/// Handles staleness check, sorting, and business logic
class AttendanceViewModel extends ChangeNotifier {
  final StudentService _studentService;
  
  // State
  List<UserModel> _students = [];
  String _currentDate = '';
  StreamSubscription<List<UserModel>>? _studentsSubscription;
  
  AttendanceViewModel({
    required StudentService studentService,
  }) : _studentService = studentService {
    _currentDate = _studentService.getTodayDate();
    _initialize();
  }
  
  // Getters
  List<UserModel> get students => _students;
  String get currentDate => _currentDate;
  
  /// Initialize: Start listening to student stream
  void _initialize() {
    _studentsSubscription = _studentService
        .getStudentsWithDisplayDataStream()
        .listen((studentList) {
      // Apply staleness check then sorting
      final processedStudents = _handleStaleness(studentList);
      _students = _sortForAttendance(processedStudents);
      notifyListeners();
    });
  }
  
  /// Handle stale status data
  /// If todayDate doesn't match currentDate, reset status to NotArrived
  List<UserModel> _handleStaleness(List<UserModel> students) {
    return students.map((student) {
      if (student.todayDate != _currentDate) {
        return student.copyWith(
          clearTodayStatus: true,
          todayDisplayStatus: TodayDisplayStatus.empty(),
        );
      }
      return student;
    }).toList();
  }
  
  /// Attendance-specific sorting:
  /// 1. NotArrived students on top (highest priority)
  /// 2. Then CheckedIn
  /// 3. Then CheckedOut
  /// 4. Absent at bottom
  /// (Different from classroom tab which shows CheckedIn first)
  List<UserModel> _sortForAttendance(List<UserModel> students) {
    students.sort((a, b) {
      // Primary sort: attendance priority
      final priorityA = _getAttendancePriority(a);
      final priorityB = _getAttendancePriority(b);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Secondary sort: alphabetical by name
      final nameA = (a.name ?? a.username).toLowerCase();
      final nameB = (b.name ?? b.username).toLowerCase();
      return nameA.compareTo(nameB);
    });
    return students;
  }
  
  /// Get sort priority for attendance view:
  /// - NotArrived = 0 (top)
  /// - CheckedIn = 1
  /// - CheckedOut = 2
  /// - Absent = 3 (bottom)
  int _getAttendancePriority(UserModel student) {
    if (student.isNotArrived) return 0;    // NotArrived first
    if (student.isPresent) return 1;       // CheckedIn second
    if (student.isCheckedOut) return 2;    // CheckedOut third
    if (student.isAbsent) return 3;        // Absent last
    return 0;                              // Fallback to NotArrived
  }
  
  // Actions
  Future<void> checkIn(String studentId) async {
    await _studentService.checkInStudent(studentId, _currentDate);
  }
  
  Future<void> checkOut(String studentId) async {
    await _studentService.checkOutStudent(studentId, _currentDate);
  }
  
  Future<void> markAbsent(String studentId) async {
    await _studentService.markAbsent(studentId, _currentDate);
  }
  
  @override
  void dispose() {
    _studentsSubscription?.cancel();
    super.dispose();
  }
}
