import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/gamification/badge_catalog.dart';
import 'package:goodwill_circle/features/gamification/gamification_controller.dart';
import 'package:goodwill_circle/features/gamification/widgets/badge_achievements_grid.dart';
import 'package:goodwill_circle/shared/models/user_stats.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

class BadgesSection extends StatelessWidget {
  final UserStats stats;
  final GamificationState gamificationState;

  const BadgesSection({
    super.key,
    required this.stats,
    required this.gamificationState,
  });

  @override
  Widget build(BuildContext context) {
    final earnedDbBadgeIds = gamificationState.badges
        .map((userBadge) => userBadge.badgeId)
        .toSet();

    final earned = _countUnlocked(earnedDbBadgeIds);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$earned of 10 earned',
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: AppColors.tan3,
                ),
              ),
              if (gamificationState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (gamificationState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Could not sync badges: ${gamificationState.error}',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.red,
                ),
              ),
            ),
          BadgeAchievementsGrid(
            stats: stats,
            chainSummary: gamificationState.chainSummary,
            earnedDbBadgeIds: earnedDbBadgeIds,
          ),
          if (gamificationState.chainSummary != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Goodwill Chain',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ChainStat(
                    label: 'People Helped',
                    value: '${gamificationState.chainSummary!.peopleHelped}',
                  ),
                ),
                Expanded(
                  child: _ChainStat(
                    label: 'Campaigns Influenced',
                    value:
                        '${gamificationState.chainSummary!.campaignsInfluenced}',
                  ),
                ),
                Expanded(
                  child: _ChainStat(
                    label: 'Credits Propagated',
                    value:
                        '${gamificationState.chainSummary!.creditsPropagated}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int _countUnlocked(Set<String> earnedDbBadgeIds) {
    var count = 0;
    for (final badge in BadgeCatalog.all) {
      if (badge.isUnlocked(
        stats: stats,
        chainSummary: gamificationState.chainSummary,
        earnedDbBadgeIds: earnedDbBadgeIds,
      )) {
        count++;
      }
    }
    return count;
  }
}

class _ChainStat extends StatelessWidget {
  final String label;
  final String value;

  const _ChainStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.red,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.tan3,
          ),
        ),
      ],
    );
  }
}
