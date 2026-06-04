import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool isUrgent;
  final bool isFeatured;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.isUrgent = false,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color ?? AppColors.cream,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.tan1, width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isUrgent) Container(width: 4, color: AppColors.red),
              if (isFeatured) Container(width: 4, color: AppColors.yellow),
              Expanded(
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
