import 'package:flutter/material.dart';
import 'virtue_chat_tab.dart';
import 'virtue_materials_tab.dart';

/// The central hub for a single virtue.
/// Contains two tabs: Community Chat Room and Materials Board.
class VirtueHubScreen extends StatelessWidget {
  final String virtue;

  // Virtue → accent color
  static const _virtueColors = {
    'Courage': Color(0xFFFF6B6B),
    'Wisdom': Color(0xFF4ECDC4),
    'Compassion': Color(0xFFFFE66D),
    'Discipline': Color(0xFF95E1D3),
    'Integrity': Color(0xFFA8E6CF),
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

  Color get _color => _virtueColors[virtue] ?? const Color(0xFF9B59B6);
  IconData get _icon => _virtueIcons[virtue] ?? Icons.star;
  String get _desc =>
      _virtueDescriptions[virtue] ?? 'Grow together in $virtue.';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 160,
              backgroundColor: const Color(0xFF0D0D1A),
              flexibleSpace: FlexibleSpaceBar(
                background: _HubHeader(
                  virtue: virtue,
                  color: _color,
                  icon: _icon,
                  description: _desc,
                ),
              ),
              bottom: TabBar(
                indicatorColor: _color,
                labelColor: _color,
                unselectedLabelColor: Colors.white38,
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

/// Decorative header shown in the SliverAppBar for a virtue hub.
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.18),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glow icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
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
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.3),
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
