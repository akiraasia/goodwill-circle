import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goodwill_circle/features/gamification/models/achievement_badge.dart';
import 'package:goodwill_circle/features/gamification/models/badge_tier.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final AchievementBadge badge;
  final bool isUnlocked;
  final double size;

  const AchievementBadgeWidget({
    super.key,
    required this.badge,
    required this.isUnlocked,
    this.size = 64,
  });

  static const _grayscaleMatrix = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.4, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final tierStyle = BadgeTierStyle.forTier(badge.tier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: isUnlocked
              ? SvgPicture.asset(
                  badge.assetPath,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                )
              : ColorFiltered(
                  colorFilter: _grayscaleMatrix,
                  child: Opacity(
                    opacity: 0.85,
                    child: SvgPicture.asset(
                      badge.assetPath,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: tierStyle.chipBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tierStyle.label.toUpperCase(),
            style: AppTypography.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: tierStyle.primary,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
