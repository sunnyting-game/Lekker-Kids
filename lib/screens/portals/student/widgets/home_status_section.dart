import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../constants/app_strings.dart';
import '../../../../constants/app_theme.dart';
import '../../../../models/daily_status.dart';

/// Status section for the Home Tab
/// 
/// Displays today's activities (meal, toilet, sleep) as status cards.
class HomeStatusSection extends StatelessWidget {
  final DailyStatus? status;

  const HomeStatusSection({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Activities',
            style: AppTextStyles.titleLarge,
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: AppSpacing.marginMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _StatusCard(
                  emoji: AppStrings.studentHomeMealEmoji,
                  label: AppStrings.studentHomeMealLabel,
                  isCompleted: status?.mealStatus ?? false,
                  delay: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.marginMedium),
              Expanded(
                child: _StatusCard(
                  emoji: AppStrings.studentHomeToiletEmoji,
                  label: AppStrings.studentHomeToiletLabel,
                  isCompleted: status?.toiletStatus ?? false,
                  delay: 100,
                ),
              ),
              const SizedBox(width: AppSpacing.marginMedium),
              Expanded(
                child: _StatusCard(
                  emoji: AppStrings.studentHomeSleepEmoji,
                  label: AppStrings.studentHomeSleepLabel,
                  isCompleted: status?.sleepStatus ?? false,
                  delay: 200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isCompleted;
  final int delay;

  const _StatusCard({
    required this.emoji,
    required this.label,
    required this.isCompleted,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isCompleted 
        ? AppDecorations.activeCard 
        : AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          onTap: () {
            // Show status message when clicked
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isCompleted 
                    ? '$label completed' 
                    : '$label not completed yet',
                ),
                backgroundColor: isCompleted ? AppColors.success : AppColors.textSecondary,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.paddingLarge,
              horizontal: AppSpacing.paddingSmall,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ).animate(target: isCompleted ? 1 : 0)
                 .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 12),
                
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 24,
                  color: isCompleted ? AppColors.success : AppColors.disabledText,
                ).animate(target: isCompleted ? 1 : 0)
                 .fadeIn(duration: 200.ms)
                 .scale(duration: 300.ms, curve: Curves.elasticOut),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}
