import 'package:goodwill_circle/features/gamification/models/achievement_badge.dart';
import 'package:goodwill_circle/features/gamification/models/badge_tier.dart';

/// All 10 badges from `goodwill_circle_badge_system.html`.
class BadgeCatalog {
  BadgeCatalog._();

  static const List<AchievementBadge> all = [
    AchievementBadge(
      id: 'first_helper',
      name: 'First Helper',
      description:
          'First act of kindness — two warm hands outstretched in a gesture of offering and support.',
      tier: BadgeTier.bronze,
      assetPath: 'assets/badges/first_helper.svg',
    ),
    AchievementBadge(
      id: 'kind_heart',
      name: 'Kind Heart',
      description:
          'Layered heart with soft radial glow — depth achieved through three stacked heart paths in silver tones.',
      tier: BadgeTier.silver,
      assetPath: 'assets/badges/kind_heart.svg',
    ),
    AchievementBadge(
      id: 'community_builder',
      name: 'Community Builder',
      description:
          'Three stylized figures connected by lines in a triangular arrangement — network of mutual support.',
      tier: BadgeTier.silver,
      assetPath: 'assets/badges/community_builder.svg',
    ),
    AchievementBadge(
      id: 'trusted_helper',
      name: 'Trusted Helper',
      description:
          'Layered shield in gold tones with a warm heart inset — emblem of reliability and care.',
      tier: BadgeTier.gold,
      assetPath: 'assets/badges/trusted_helper.svg',
    ),
    AchievementBadge(
      id: 'mentor',
      name: 'Mentor',
      description:
          'Open book with a 5-point star above — knowledge shared creates light for others.',
      tier: BadgeTier.gold,
      assetPath: 'assets/badges/mentor.svg',
    ),
    AchievementBadge(
      id: 'lifesaver',
      name: 'Lifesaver',
      description:
          'Medical cross layered over a soft warm heart — emergency care meets compassion.',
      tier: BadgeTier.gold,
      assetPath: 'assets/badges/lifesaver.svg',
    ),
    AchievementBadge(
      id: 'campaign_champion',
      name: 'Campaign Champion',
      description:
          'Megaphone emitting expanding rays — amplifying impact across the community.',
      tier: BadgeTier.platinum,
      assetPath: 'assets/badges/campaign_champion.svg',
    ),
    AchievementBadge(
      id: 'chain_builder',
      name: 'Chain Builder',
      description:
          'Five interlocked chain rings in an arc — unbroken goodwill passed forward.',
      tier: BadgeTier.platinum,
      assetPath: 'assets/badges/chain_builder.svg',
    ),
    AchievementBadge(
      id: 'goodwill_ambassador',
      name: 'Goodwill Ambassador',
      description:
          'Globe held in two cupped hands — world-scale compassion and global positive impact.',
      tier: BadgeTier.diamond,
      assetPath: 'assets/badges/goodwill_ambassador.svg',
    ),
    AchievementBadge(
      id: 'community_legend',
      name: 'Community Legend',
      description:
          'Triple-layered shield with tri-layer starburst inside — surrounded by ambient glow and corner sparkles. Highest achievement.',
      tier: BadgeTier.diamond,
      assetPath: 'assets/badges/community_legend.svg',
    ),
  ];
}
