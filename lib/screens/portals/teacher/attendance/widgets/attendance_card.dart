import 'package:flutter/material.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../models/user_model.dart';
import '../../../../../viewmodels/attendance_view_model.dart';

/// Card widget for displaying student attendance information
class AttendanceCard extends StatelessWidget {
  final UserModel student;
  final AttendanceViewModel viewModel;

  const AttendanceCard({
    super.key,
    required this.student,
    required this.viewModel,
  });

  /// Get status text from denormalized todayStatus field
  String _getStatusText() {
    final status = _getCurrentStatus();
    switch (status) {
      case 'CheckedIn':
        return AppStrings.attendanceCheckedIn;
      case 'CheckedOut':
        return AppStrings.attendanceCheckedOut;
      case 'Absent':
        return AppStrings.attendanceAbsent;
      default:
        return AppStrings.attendanceNotArrived;
    }
  }

  /// Get current status (handles stale status)
  String _getCurrentStatus() {
    // If todayDate doesn't match, status is stale
    if (student.todayDate != viewModel.currentDate) {
      return 'NotArrived';
    }
    return student.todayStatus ?? 'NotArrived';
  }

  /// Get status color
  Color _getStatusColor() {
    final status = _getCurrentStatus();
    switch (status) {
      case 'CheckedIn':
        return AppColors.attendancePresent;
      case 'CheckedOut':
        return Colors.orange;
      case 'Absent':
        return AppColors.attendanceAbsent;
      default:
        return AppColors.textHint;
    }
  }

  /// Determine if check-in button should be disabled
  bool get _checkInDisabled {
    final status = _getCurrentStatus();
    return status != 'NotArrived';
  }

  /// Determine if check-out button should be disabled
  bool get _checkOutDisabled {
    final status = _getCurrentStatus();
    return status != 'CheckedIn';
  }

  /// Determine if absent button should be disabled
  bool get _absentDisabled {
    final status = _getCurrentStatus();
    return status != 'NotArrived';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusText();
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.marginMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: student.avatarUrl != null
                      ? NetworkImage(student.avatarUrl!)
                      : null,
                  child: student.avatarUrl == null
                      ? Text(
                          (student.name ?? student.username)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.paddingMedium),
                // Student name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name ?? student.username,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status text
                      Text(
                        statusText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.marginMedium),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkInDisabled
                        ? null
                        : () => viewModel.checkIn(student.uid),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(AppStrings.attendanceCheckIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.attendancePresent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.disabledBackground,
                      disabledForegroundColor: AppColors.disabledText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkOutDisabled
                        ? null
                        : () => viewModel.checkOut(student.uid),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(AppStrings.attendanceCheckOut),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.disabledBackground,
                      disabledForegroundColor: AppColors.disabledText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _absentDisabled
                        ? null
                        : () => viewModel.markAbsent(student.uid),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text(AppStrings.attendanceMarkAbsent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.attendanceAbsent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.disabledBackground,
                      disabledForegroundColor: AppColors.disabledText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
