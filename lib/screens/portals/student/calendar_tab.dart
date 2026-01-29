import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.marginMedium),
          Text(
            'Calendar Coming Soon',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
