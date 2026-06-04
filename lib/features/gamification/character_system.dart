class CharacterLevel {
  final int level;
  final String title;
  final int minScore;
  final int maxScore;

  CharacterLevel({
    required this.level,
    required this.title,
    required this.minScore,
    required this.maxScore,
  });

  double getProgress(int currentScore) {
    if (currentScore >= maxScore && maxScore != -1) return 1.0;
    if (currentScore <= minScore) return 0.0;

    // Calculate progress within current level
    return (currentScore - minScore) / (maxScore - minScore);
  }
}

class CharacterSystem {
  static final List<CharacterLevel> levels = [
    CharacterLevel(level: 1, title: 'Helper', minScore: 0, maxScore: 99),
    CharacterLevel(
      level: 2,
      title: 'Contributor',
      minScore: 100,
      maxScore: 499,
    ),
    CharacterLevel(level: 3, title: 'Supporter', minScore: 500, maxScore: 999),
    CharacterLevel(
      level: 4,
      title: 'Community Builder',
      minScore: 1000,
      maxScore: 2499,
    ),
    CharacterLevel(
      level: 5,
      title: 'Changemaker',
      minScore: 2500,
      maxScore: 4999,
    ),
    CharacterLevel(level: 6, title: 'Leader', minScore: 5000, maxScore: 9999),
    CharacterLevel(
      level: 7,
      title: 'Beacon',
      minScore: 10000,
      maxScore: 999999,
    ), // effectively max
  ];

  static CharacterLevel getLevelForScore(int score) {
    for (var level in levels) {
      if (score >= level.minScore && score <= level.maxScore) {
        return level;
      }
    }
    // Fallback to highest level if somehow above
    return levels.last;
  }
}
