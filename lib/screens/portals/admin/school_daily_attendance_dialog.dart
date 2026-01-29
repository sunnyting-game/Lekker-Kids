import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/daily_status.dart';
import '../../../services/student_service.dart';
import 'attendance_details_dialog.dart';

/// Dialog to display attendance records for all students on a specific date.
class SchoolDailyAttendanceDialog extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final String date; // Format: YYYY-MM-DD

  const SchoolDailyAttendanceDialog({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.date,
  });

  @override
  State<SchoolDailyAttendanceDialog> createState() =>
      _SchoolDailyAttendanceDialogState();
}

class _SchoolDailyAttendanceDialogState
    extends State<SchoolDailyAttendanceDialog> {
  late final StudentService _studentService;
  late Future<_AttendanceData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _studentService = StudentService()..setSchoolContext(widget.schoolId);
    _dataFuture = _loadData();
  }

  Future<_AttendanceData> _loadData() async {
    final studentsFuture = _studentService.getStudentsStream().first;
    final statusesFuture = _studentService.getDailyStatusesForDate(widget.date);

    final results = await Future.wait([studentsFuture, statusesFuture]);
    final students = results[0] as List<UserModel>;
    final statuses = results[1] as List<DailyStatus>;

    // Create a map for quick lookup
    final statusMap = {for (var s in statuses) s.studentId: s};

    return _AttendanceData(students: students, statusMap: statusMap);
  }

  String _formatDisplayDate(String date) {
    // date is in YYYY-MM-DD format
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${months[month - 1]} ${parts[2]}, ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.schoolName),
          Text(
            _formatDisplayDate(widget.date),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: FutureBuilder<_AttendanceData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final students = data.students;
            final statusMap = data.statusMap;

            if (students.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No students in this school'),
                  ],
                ),
              );
            }

            // Sort students: those with records first, then alphabetically
            students.sort((a, b) {
              final aHasRecord = statusMap.containsKey(a.uid);
              final bHasRecord = statusMap.containsKey(b.uid);
              if (aHasRecord != bHasRecord) {
                return aHasRecord ? -1 : 1;
              }
              return (a.name ?? a.username)
                  .compareTo(b.name ?? b.username);
            });

            return ListView.builder(
              shrinkWrap: true,
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final status = statusMap[student.uid];

                return _StudentAttendanceCard(
                  student: student,
                  status: status,
                  onTap: () => _showDetails(student),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showDetails(UserModel student) {
    showDialog(
      context: context,
      builder: (context) => AttendanceDetailsDialog(
        student: student,
        date: widget.date,
        studentService: _studentService,
      ),
    );
  }
}

class _AttendanceData {
  final List<UserModel> students;
  final Map<String, DailyStatus> statusMap;

  _AttendanceData({required this.students, required this.statusMap});
}

class _StudentAttendanceCard extends StatelessWidget {
  final UserModel student;
  final DailyStatus? status;
  final VoidCallback onTap;

  const _StudentAttendanceCard({
    required this.student,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecord = status != null;
    final isAbsent = status?.isAbsent ?? false;
    final isPresent = hasRecord && (status?.attendance ?? false);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isAbsent) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
      statusText = 'Absent';
    } else if (isPresent) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outlined;
      statusText = 'Present';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = 'No Record';
    }

    String? timeInfo;
    if (isPresent && status != null) {
      final checkIn = status!.checkInTime;
      final checkOut = status!.checkOutTime;
      if (checkIn != null) {
        final inTime = _formatTime(checkIn);
        if (checkOut != null) {
          timeInfo = '$inTime - ${_formatTime(checkOut)}';
        } else {
          timeInfo = 'In: $inTime';
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student.avatarUrl != null
              ? NetworkImage(student.avatarUrl!)
              : null,
          child: student.avatarUrl == null
              ? Text(
                  (student.name ?? student.username)
                      .substring(0, 1)
                      .toUpperCase(),
                )
              : null,
        ),
        title: Text(student.name ?? student.username),
        subtitle: timeInfo != null ? Text(timeInfo) : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
