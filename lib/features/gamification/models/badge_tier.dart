import 'package:flutter/material.dart';

enum BadgeTier { bronze, silver, gold, platinum, diamond }

class BadgeTierStyle {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color chipBackground;
  final String label;

  const BadgeTierStyle({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.chipBackground,
    required this.label,
  });

  static BadgeTierStyle forTier(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const BadgeTierStyle(
          primary: Color(0xFFCD7F4A),
          secondary: Color(0xFFE8A87C),
          background: Color(0xFFF5D5B8),
          chipBackground: Color(0xFFFFF5EE),
          label: 'Bronze',
        );
      case BadgeTier.silver:
        return const BadgeTierStyle(
          primary: Color(0xFF8C9BAE),
          secondary: Color(0xFFB8C5D4),
          background: Color(0xFFDDE5EE),
          chipBackground: Color(0xFFF0F4F8),
          label: 'Silver',
        );
      case BadgeTier.gold:
        return const BadgeTierStyle(
          primary: Color(0xFFC9923A),
          secondary: Color(0xFFE8B86D),
          background: Color(0xFFF5D99A),
          chipBackground: Color(0xFFFFFBF0),
          label: 'Gold',
        );
      case BadgeTier.platinum:
        return const BadgeTierStyle(
          primary: Color(0xFF7A8FAF),
          secondary: Color(0xFFA8BCCF),
          background: Color(0xFFD4E0EC),
          chipBackground: Color(0xFFF0F5FA),
          label: 'Platinum',
        );
      case BadgeTier.diamond:
        return const BadgeTierStyle(
          primary: Color(0xFF8B6BAE),
          secondary: Color(0xFFB89ACC),
          background: Color(0xFFDDD0EE),
          chipBackground: Color(0xFFF8F4FF),
          label: 'Diamond',
        );
    }
  }
}
