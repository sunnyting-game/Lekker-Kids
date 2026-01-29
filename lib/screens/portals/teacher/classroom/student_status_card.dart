import 'package:flutter/material.dart';
import '../../../../constants/app_strings.dart';
import '../../../../constants/app_theme.dart';
import '../../../../models/today_display_status.dart';
import '../../../../models/user_model.dart';
import '../../../../viewmodels/classroom_viewmodel.dart';
import 'widgets/camera_button.dart';
import 'widgets/chat_button.dart';
import 'widgets/photo_count_badge.dart';
import 'widgets/status_button.dart';

/// Student card - NO StreamBuilder needed!
/// All display data comes from UserModel (denormalized)
class StudentStatusCard extends StatelessWidget {
  final UserModel student;
  final ClassroomViewModel viewModel;

  const StudentStatusCard({
    super.key,
    required this.student,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // Get display status from denormalized data
    final displayStatus = student.todayDisplayStatus ?? TodayDisplayStatus.empty();
    final isPresent = student.isPresent;
    final isAbsent = student.isAbsent;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.marginMedium),
      color: isPresent ? null : AppColors.disabledBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name and status label
            StudentHeader(
              student: student,
              isPresent: isPresent,
              isAbsent: isAbsent,
            ),
            const SizedBox(height: AppSpacing.marginMedium),
            // Status indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatusButton(
                  emoji: AppStrings.classroomMealEmoji,
                  label: AppStrings.classroomMealLabel,
                  isActive: displayStatus.mealStatus,
                  isEnabled: isPresent,
                  onTap: isPresent
                      ? () => viewModel.toggleMealStatus(student)
                      : null,
                ),
                StatusButton(
                  emoji: AppStrings.classroomToiletEmoji,
                  label: AppStrings.classroomToiletLabel,
                  isActive: displayStatus.toiletStatus,
                  isEnabled: isPresent,
                  onTap: isPresent
                      ? () => viewModel.toggleToiletStatus(student)
                      : null,
                ),
                StatusButton(
                  emoji: AppStrings.classroomSleepEmoji,
                  label: AppStrings.classroomSleepLabel,
                  isActive: displayStatus.sleepStatus,
                  isEnabled: isPresent,
                  onTap: isPresent
                      ? () => viewModel.toggleSleepStatus(student)
                      : null,
                ),
                // Camera button and photo count
                if (isPresent) ...[
                  CameraButton(
                    student: student,
                    date: viewModel.currentDate,
                  ),
                  // Chat button - NO StreamBuilder! Uses denormalized flag
                  ChatButton(
                    student: student,
                    hasUnread: student.hasUnreadFromStudent,
                  ),
                  // Photo count badge - NO StreamBuilder! Uses denormalized count
                  if (displayStatus.photosCount > 0)
                    PhotoCountBadge(
                      count: displayStatus.photosCount,
                      student: student,
                      viewModel: viewModel,
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudentHeader extends StatelessWidget {
  final UserModel student;
  final bool isPresent;
  final bool isAbsent;

  const StudentHeader({
    super.key,
    required this.student,
    required this.isPresent,
    required this.isAbsent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLight,
          backgroundImage:
              student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
          child: student.avatarUrl == null
              ? Text(
                  (student.name ?? student.username).substring(0, 1).toUpperCase(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.paddingSmall),
        Expanded(
          child: Text(
            student.name ?? student.username,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: isPresent ? AppColors.textPrimary : AppColors.disabledText,
            ),
          ),
        ),
        if (!isPresent)
          Text(
            isAbsent ? AppStrings.classroomAbsentLabel : AppStrings.attendanceNotArrived,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.attendanceAbsent,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
