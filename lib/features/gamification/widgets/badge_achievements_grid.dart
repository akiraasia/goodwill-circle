import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/gamification/badge_catalog.dart';
import 'package:goodwill_circle/features/gamification/models/goodwill_chain_summary.dart';
import 'package:goodwill_circle/features/gamification/widgets/achievement_badge_widget.dart';
import 'package:goodwill_circle/shared/models/user_stats.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';

class BadgeAchievementsGrid extends StatelessWidget {
  final UserStats stats;
  final GoodwillChainSummary? chainSummary;
  final Set<String> earnedDbBadgeIds;

  const BadgeAchievementsGrid({
    super.key,
    required this.stats,
    required this.chainSummary,
    required this.earnedDbBadgeIds,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.72,
      ),
      itemCount: BadgeCatalog.all.length,
      itemBuilder: (context, index) {
        final badge = BadgeCatalog.all[index];
        final unlocked = badge.isUnlocked(
          stats: stats,
          chainSummary: chainSummary,
          earnedDbBadgeIds: earnedDbBadgeIds,
        );

        return AchievementBadgeWidget(
          badge: badge,
          isUnlocked: unlocked,
        );
      },
    );
  }
}
