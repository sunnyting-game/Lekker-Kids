import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/daily_status.dart';
import '../../../services/student_service.dart';

/// Dialog to display attendance details for a specific student on a specific date.
class AttendanceDetailsDialog extends StatelessWidget {
  final UserModel student;
  final String date;
  final StudentService studentService;

  const AttendanceDetailsDialog({
    super.key,
    required this.student,
    required this.date,
    required this.studentService,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${student.name ?? student.username} - $date'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<DailyStatus?>(
          future: studentService.getDailyStatus(student.uid, date),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final status = snapshot.data;

            if (status == null || status.sessions.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No attendance record for this date'),
                    ],
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatDuration(status.totalDuration),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Sessions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${status.sessions.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Sessions list
                ...status.sessions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final session = entry.value;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: session.checkOut != null
                            ? Colors.green
                            : Colors.orange,
                        child: Text('${index + 1}'),
                      ),
                      title: Row(
                        children: [
                          const Icon(Icons.login, size: 16),
                          const SizedBox(width: 4),
                          Text(_formatTime(session.checkIn)),
                          const SizedBox(width: 16),
                          const Icon(Icons.logout, size: 16),
                          const SizedBox(width: 4),
                          Text(session.checkOut != null
                              ? _formatTime(session.checkOut!)
                              : 'Active'),
                        ],
                      ),
                      subtitle: Text(
                        'Duration: ${_formatDuration(session.duration)}',
                      ),
                    ),
                  );
                }),
              ],
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
