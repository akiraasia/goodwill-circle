import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.lg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: AppIcons.help,
            label: 'Requests',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: AppIcons.campaign,
            label: 'Campaigns',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: AppIcons.profile,
            label: 'Profile',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.red : AppColors.textLight;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: color,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
