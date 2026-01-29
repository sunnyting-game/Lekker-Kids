import 'package:flutter/material.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../models/weekly_plan.dart';

class PlanCard extends StatelessWidget {
  final WeeklyPlan plan;

  const PlanCard({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.marginSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.paddingXSmall),
              Text(
                plan.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
