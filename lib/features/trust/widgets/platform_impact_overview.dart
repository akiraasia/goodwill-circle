import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/trust/trust_repository.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';

class PlatformImpactOverview extends ConsumerWidget {
  const PlatformImpactOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(platformImpactProvider);

    return summary.when(
      data: (metrics) {
        final visible = metrics
            .where((metric) => const {
                  'users',
                  'trusted_accounts',
                  'completed_requests',
                  'campaigns',
                }.contains(metric.metric))
            .toList();
        final maxValue = visible.fold<int>(
          1,
          (max, metric) => metric.value > max ? metric.value : max,
        );

        return AppCard(
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights, color: AppColors.red),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Circle Impact', style: AppTypography.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final metric in visible) ...[
                _ImpactBar(metric: metric, maxValue: maxValue),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
      loading: () => const AppCard(
        color: AppColors.white,
        child: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ImpactBar extends StatelessWidget {
  final ImpactMetric metric;
  final int maxValue;

  const _ImpactBar({required this.metric, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final value = maxValue == 0 ? 0.0 : metric.value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _labelFor(metric.metric),
                style: AppTypography.textTheme.labelMedium,
              ),
            ),
            Text(
              metric.value.toString(),
              style: AppTypography.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: value.clamp(0.06, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.tan1,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
          ),
        ),
      ],
    );
  }

  String _labelFor(String metric) {
    switch (metric) {
      case 'users':
        return 'Members';
      case 'trusted_accounts':
        return 'Trusted accounts';
      case 'completed_requests':
        return 'Help completed';
      case 'campaigns':
        return 'Campaigns';
      default:
        return metric.replaceAll('_', ' ');
    }
  }
}
