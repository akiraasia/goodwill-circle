import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/models/user_stats.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';

class ImpactGraph extends StatelessWidget {
  final UserStats stats;

  const ImpactGraph({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ImpactMetric(
        label: 'Helped',
        value: stats.helpCount,
        color: AppColors.red,
        icon: Icons.volunteer_activism,
      ),
      _ImpactMetric(
        label: 'Earned',
        value: stats.creditsEarned,
        color: AppColors.yellow,
        icon: Icons.savings_outlined,
      ),
      _ImpactMetric(
        label: 'Donated',
        value: stats.creditsDonated,
        color: AppColors.redSoft,
        icon: Icons.favorite_outline,
      ),
      _ImpactMetric(
        label: 'Supported',
        value: stats.campaignsSupported,
        color: AppColors.tan3,
        icon: Icons.campaign_outlined,
      ),
    ];
    final maxValue = items
        .map((item) => item.value)
        .fold<int>(1, (max, value) => value > max ? value : max);

    return AppCard(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: AppColors.textDark),
              const SizedBox(width: AppSpacing.sm),
              Text('Impact Made', style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 156,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in items) ...[
                  Expanded(
                    child: _ImpactBar(item: item, maxValue: maxValue),
                  ),
                  if (item != items.last) const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _ImpactMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _ImpactBar extends StatelessWidget {
  final _ImpactMetric item;
  final int maxValue;

  const _ImpactBar({required this.item, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final barHeight = 24.0 + (item.value / maxValue) * 72.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${item.value}',
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          height: barHeight,
          width: 42,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(item.icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
