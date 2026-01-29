import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/student_service.dart';
import '../../../services/attendance_report_service.dart';
import 'attendance_details_dialog.dart';

/// Dialog to display list of students for a dayhome and allow
/// the admin to select a student to view attendance records.
class StudentAttendanceListDialog extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const StudentAttendanceListDialog({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<StudentAttendanceListDialog> createState() =>
      _StudentAttendanceListDialogState();
}

class _StudentAttendanceListDialogState
    extends State<StudentAttendanceListDialog> {
  late final StudentService _studentService;

  @override
  void initState() {
    super.initState();
    _studentService = StudentService()..setSchoolContext(widget.schoolId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Attendance - ${widget.schoolName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: StreamBuilder<List<UserModel>>(
          stream: _studentService.getStudentsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data!;

            if (students.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No students in this dayhome'),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
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
                  subtitle: Text(student.email),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDateAndShowDetails(student),
                );
              },
            );
          },
        ),
      ),
      actions: [
        StreamBuilder<List<UserModel>>(
          stream: _studentService.getStudentsStream(),
          builder: (context, snapshot) {
            final students = snapshot.data ?? [];
            return FilledButton.icon(
              onPressed: students.isEmpty ? null : () => _generateCSVForAll(students),
              icon: const Icon(Icons.download),
              label: const Text('Download CSV'),
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _pickDateAndShowDetails(UserModel student) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select date to view attendance',
    );

    if (pickedDate != null && mounted) {
      final dateString =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

      showDialog(
        context: context,
        builder: (context) => AttendanceDetailsDialog(
          student: student,
          date: dateString,
          studentService: _studentService,
        ),
      );
    }
  }

  Future<void> _generateCSVForAll(List<UserModel> students) async {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating report for all students...')),
    );

    try {
      final reportService = AttendanceReportService(
        studentService: _studentService,
      );

      await reportService.generateMonthlyCSVForMultipleStudents(
        students: students,
        schoolName: widget.schoolName,
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
