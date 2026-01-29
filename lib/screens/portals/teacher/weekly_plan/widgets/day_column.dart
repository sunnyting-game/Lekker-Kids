import 'package:flutter/material.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../models/weekly_plan.dart';
import '../../../../../utils/week_utils.dart';
import 'plan_card.dart';

class DayColumn extends StatelessWidget {
  final String day;
  final DateTime date;
  final List<WeeklyPlan> plans;

  const DayColumn({
    super.key,
    required this.day,
    required this.date,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth / 5;

    return Container(
      width: columnWidth,
      padding: const EdgeInsets.all(AppSpacing.paddingSmall),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AppColors.textHint,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with date
          Container(
            padding: const EdgeInsets.all(AppSpacing.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.paddingXSmall),
                Text(
                  WeekUtils.formatDate(date),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.marginMedium),
          // Plan items
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingMedium),
              child: Text(
                AppStrings.weeklyPlanNoPlans,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...plans.map((plan) => PlanCard(plan: plan)),
        ],
      ),
    );
  }
}
