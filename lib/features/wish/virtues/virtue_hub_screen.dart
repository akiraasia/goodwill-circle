import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'virtue_chat_tab.dart';
import 'virtue_materials_tab.dart';

class VirtueHubScreen extends StatelessWidget {
  final String virtue;

  static const _virtueColors = {
    'Courage': AppColors.red,
    'Wisdom': Color(0xFF3B82F6),
    'Compassion': Color(0xFFEC4899),
    'Discipline': Color(0xFF10B981),
    'Integrity': Color(0xFF8B5CF6),
  };

  static const _virtueIcons = {
    'Courage': Icons.local_fire_department,
    'Wisdom': Icons.auto_stories,
    'Compassion': Icons.favorite,
    'Discipline': Icons.timer,
    'Integrity': Icons.shield,
  };

  static const _virtueDescriptions = {
    'Courage': 'Face fears, speak up, and grow bold together.',
    'Wisdom': 'Learn, reflect, and share knowledge.',
    'Compassion': 'Support each other with empathy and care.',
    'Discipline': 'Build habits and stay consistent.',
    'Integrity': 'Act honestly and hold each other accountable.',
  };

  const VirtueHubScreen({Key? key, required this.virtue}) : super(key: key);

  Color get _color => _virtueColors[virtue] ?? AppColors.red;
  IconData get _icon => _virtueIcons[virtue] ?? Icons.star;
  String get _desc =>
      _virtueDescriptions[virtue] ?? 'Grow together in $virtue.';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 160,
              backgroundColor: AppColors.cream,
              iconTheme: const IconThemeData(color: AppColors.textDark),
              flexibleSpace: FlexibleSpaceBar(
                background: _HubHeader(
                  virtue: virtue,
                  color: _color,
                  icon: _icon,
                  description: _desc,
                ),
              ),
              bottom: TabBar(
                indicatorColor: AppColors.red,
                labelColor: AppColors.red,
                unselectedLabelColor: AppColors.textLight,
                tabs: const [
                  Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat Room'),
                  Tab(icon: Icon(Icons.collections_bookmark), text: 'Materials'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              VirtueChatTab(virtue: virtue, accentColor: _color),
              VirtueMaterialsTab(virtue: virtue, accentColor: _color),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  final String virtue;
  final Color color;
  final IconData icon;
  final String description;

  const _HubHeader({
    required this.virtue,
    required this.color,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.redPale,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.redMuted),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      virtue,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
