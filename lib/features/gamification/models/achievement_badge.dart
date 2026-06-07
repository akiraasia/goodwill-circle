import 'package:goodwill_circle/features/gamification/models/badge_tier.dart';
import 'package:goodwill_circle/features/gamification/models/goodwill_chain_summary.dart';
import 'package:goodwill_circle/shared/models/user_stats.dart';

class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final BadgeTier tier;
  final String assetPath;

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.assetPath,
  });

  bool isUnlocked({
    required UserStats stats,
    required GoodwillChainSummary? chainSummary,
    required Set<String> earnedDbBadgeIds,
  }) {
    if (_dbBadgeIdsForCatalogId(id).any(earnedDbBadgeIds.contains)) {
      return true;
    }

    switch (id) {
      case 'first_helper':
        return stats.helpCount >= 1;
      case 'kind_heart':
        return stats.creditsDonated >= 1;
      case 'community_builder':
        return stats.helpCount >= 10;
      case 'trusted_helper':
        return stats.helpCount >= 25 || stats.reputationScore >= 100;
      case 'mentor':
        return stats.impactScore >= 500;
      case 'lifesaver':
        return stats.helpCount >= 50;
      case 'campaign_champion':
        return stats.campaignCount >= 1;
      case 'chain_builder':
        return (chainSummary?.peopleHelped ?? 0) >= 5;
      case 'goodwill_ambassador':
        return stats.creditsDonated >= 100;
      case 'community_legend':
        return stats.reputationScore >= 300 &&
            stats.helpCount >= 25 &&
            stats.campaignsSupported >= 3;
      default:
        return false;
    }
  }
}

/// Maps Supabase `badges.id` values to catalog badge ids.
Set<String> _dbBadgeIdsForCatalogId(String catalogId) {
  switch (catalogId) {
    case 'first_helper':
      return {'first_help', 'first_helper'};
    case 'kind_heart':
      return {'first_donation', 'kind_heart'};
    case 'community_builder':
      return {'10_helps', 'community_builder'};
    case 'trusted_helper':
      return {'trusted_helper'};
    case 'mentor':
      return {'mentor'};
    case 'lifesaver':
      return {'lifesaver'};
    case 'campaign_champion':
      return {'campaign_creator', 'campaign_champion'};
    case 'chain_builder':
      return {'chain_builder'};
    case 'goodwill_ambassador':
      return {'100_donated', 'goodwill_ambassador'};
    case 'community_legend':
      return {'community_legend'};
    default:
      return {};
  }
}
