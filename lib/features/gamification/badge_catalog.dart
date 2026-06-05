import 'package:goodwill_circle/features/gamification/models/achievement_badge.dart';
import 'package:goodwill_circle/features/gamification/models/badge_tier.dart';

class BadgeCatalog {
  BadgeCatalog._();

  static const List<AchievementBadge> all = [
    AchievementBadge(
      id: 'first_helper',
      name: 'First Helper',
      description: 'First act of kindness with warm hands offering support.',
      tier: BadgeTier.bronze,
      assetPath: 'assets/badges/first_helper.svg',
    ),
    AchievementBadge(
      id: 'kind_heart',
      name: 'Kind Heart',
      description: 'A layered heart for steady kindness and care.',
      tier: BadgeTier.silver,
      assetPath: 'assets/badges/kind_heart.svg',
    ),
    AchievementBadge(
      id: 'community_builder',
      name: 'Community Builder',
      description: 'A small network of people building mutual support.',
      tier: BadgeTier.silver,
      assetPath: 'assets/badges/community_builder.svg',
    ),
    AchievementBadge(
      id: 'trusted_helper',
      name: 'Trusted Helper',
      description: 'A shield and heart for reliable help.',
      tier: BadgeTier.gold,
      assetPath: 'assets/badges/trusted_helper.svg',
    ),
    AchievementBadge(
      id: 'mentor',
      name: 'Mentor',
      description: 'Shared knowledge that creates light for others.',
      tier: BadgeTier.gold,
      assetPath: 'assets/badges/mentor.svg',
    ),
    AchievementBadge(
      id: 'lifesaver',
      name: 'Lifesaver',
      description: 'Emergency care meeting compassion.',
      tier: BadgeTier.gold,
      assetPath: 'assets/badges/lifesaver.svg',
    ),
    AchievementBadge(
      id: 'campaign_champion',
      name: 'Campaign Champion',
      description: 'Amplifying impact across the community.',
      tier: BadgeTier.platinum,
      assetPath: 'assets/badges/campaign_champion.svg',
    ),
    AchievementBadge(
      id: 'chain_builder',
      name: 'Chain Builder',
      description: 'Unbroken goodwill passed forward.',
      tier: BadgeTier.platinum,
      assetPath: 'assets/badges/chain_builder.svg',
    ),
    AchievementBadge(
      id: 'goodwill_ambassador',
      name: 'Goodwill Ambassador',
      description: 'World-scale compassion and positive impact.',
      tier: BadgeTier.diamond,
      assetPath: 'assets/badges/goodwill_ambassador.svg',
    ),
    AchievementBadge(
      id: 'community_legend',
      name: 'Community Legend',
      description: 'The highest achievement for sustained community impact.',
      tier: BadgeTier.diamond,
      assetPath: 'assets/badges/community_legend.svg',
    ),
  ];
}
