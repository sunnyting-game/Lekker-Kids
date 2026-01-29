import 'package:flutter/material.dart';
import '../../../../../constants/app_theme.dart';

class StatusButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onTap;

  const StatusButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingSmall),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: AppSpacing.emojiLarge,
                color: !isEnabled
                    ? AppColors.disabledText
                    : (isActive ? null : AppColors.textHint),
              ),
            ),
            const SizedBox(height: AppSpacing.paddingXSmall),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: !isEnabled
                    ? AppColors.disabledText
                    : (isActive ? AppColors.textPrimary : AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
