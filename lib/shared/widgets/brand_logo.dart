import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

class BrandLogo extends StatelessWidget {
  final bool light;

  const BrandLogo({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final foreground = light ? AppColors.cream : AppColors.textDark;
    final markForeground = light ? AppColors.textDark : AppColors.cream;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            '◯',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: markForeground,
              height: 1,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Goodwill Circle',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            color: foreground,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
