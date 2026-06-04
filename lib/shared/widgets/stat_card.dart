import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.tan1, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.textTheme.displayMedium?.copyWith(
              color: textColor ?? AppColors.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label.toUpperCase(),
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: textColor?.withValues(alpha: 0.8) ?? AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
