import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'virtue_task.dart';
import 'virtue_task_repository.dart';

/// The main Task Mode screen for the Wish Module.
/// Shows AI-assigned virtue tasks and lets users toggle between
/// individual (solo) tasks and social tasks that connect them to
/// real help requests in the community.
class VirtueTasksScreen extends ConsumerStatefulWidget {
  /// The virtues the AI assigned to this user based on their wish interview.
  final List<String> assignedVirtues;

  const VirtueTasksScreen({Key? key, required this.assignedVirtues}) : super(key: key);

  @override
  ConsumerState<VirtueTasksScreen> createState() => _VirtueTasksScreenState();
}

class _VirtueTasksScreenState extends ConsumerState<VirtueTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSocial = true; // Toggle: social or individual

  // Virtue -> accent color mapping
  static const _virtueColors = {
    'Courage': Color(0xFFFF6B6B),
    'Wisdom': Color(0xFF4ECDC4),
    'Compassion': Color(0xFFFFE66D),
    'Discipline': Color(0xFF95E1D3),
    'Integrity': Color(0xFFA8E6CF),
  };

  // Virtue -> icon mapping
  static const _virtueIcons = {
    'Courage': Icons.local_fire_department,
    'Wisdom': Icons.auto_stories,
    'Compassion': Icons.favorite,
    'Discipline': Icons.timer,
    'Integrity': Icons.shield,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.assignedVirtues.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _virtueColor(String virtue) =>
      _virtueColors[virtue] ?? const Color(0xFF9B59B6);

  IconData _virtueIcon(String virtue) =>
      _virtueIcons[virtue] ?? Icons.star;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Path',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: widget.assignedVirtues.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                tabs: widget.assignedVirtues
                    .map((v) => Tab(
                          child: Row(
                            children: [
                              Icon(_virtueIcon(v),
                                  color: _virtueColor(v), size: 16),
                              const SizedBox(width: 6),
                              Text(v,
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ))
                    .toList(),
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Social / Individual Toggle ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _ToggleTab(
                    label: 'Connect with People',
                    icon: Icons.people,
                    isSelected: _showSocial,
                    onTap: () => setState(() => _showSocial = true),
                  ),
                  _ToggleTab(
                    label: 'Individual Task',
                    icon: Icons.self_improvement,
                    isSelected: !_showSocial,
                    onTap: () => setState(() => _showSocial = false),
                  ),
                ],
              ),
            ),
          ),

          // ── Virtue Tab Content ─────────────────────────────────────────
          Expanded(
            child: widget.assignedVirtues.length > 1
                ? TabBarView(
                    controller: _tabController,
                    children: widget.assignedVirtues
                        .map((v) => _VirtueTaskList(
                              virtue: v,
                              showSocial: _showSocial,
                              accentColor: _virtueColor(v),
                            ))
                        .toList(),
                  )
                : widget.assignedVirtues.isEmpty
                    ? const Center(
                        child: Text('No virtues assigned yet.',
                            style: TextStyle(color: Colors.white54)))
                    : _VirtueTaskList(
                        virtue: widget.assignedVirtues.first,
                        showSocial: _showSocial,
                        accentColor: _virtueColor(widget.assignedVirtues.first),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-virtue task list
// ─────────────────────────────────────────────────────────────────────────────

class _VirtueTaskList extends ConsumerWidget {
  final String virtue;
  final bool showSocial;
  final Color accentColor;

  const _VirtueTaskList({
    required this.virtue,
    required this.showSocial,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(
      FutureProvider<List<VirtueTask>>((ref) {
        return ref.read(virtueTaskRepositoryProvider).getTasksForVirtue(virtue);
      }).future,
    );

    return FutureBuilder<List<VirtueTask>>(
      future: tasksAsync,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final tasks = (snapshot.data ?? [])
            .where((t) =>
                showSocial ? t.isSocial : t.isIndividual)
            .toList();

        if (tasks.isEmpty) {
          return _EmptyTaskState(
            virtue: virtue,
            showSocial: showSocial,
            accentColor: accentColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) => _TaskCard(
            task: tasks[i],
            accentColor: accentColor,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task card
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final VirtueTask task;
  final Color accentColor;

  const _TaskCard({required this.task, required this.accentColor});

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.completed: return Colors.green;
      case TaskStatus.inProgress: return Colors.amber;
      default: return Colors.white24;
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.completed: return 'Done';
      case TaskStatus.inProgress: return 'In Progress';
      default: return 'Start';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  task.isSocial ? Icons.people : Icons.self_improvement,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                // XP badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${task.xpReward} XP',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
                if (task.isSocial && task.socialRole != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        task.socialRole == 'helper'
                            ? Icons.volunteer_activism
                            : Icons.school,
                        color: accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.socialRole == 'helper'
                            ? 'You will act as a Helper'
                            : 'You will join as a Learner (Helpee)',
                        style:
                            TextStyle(color: accentColor, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: task.status != TaskStatus.completed
                        ? () {
                            // TODO: Navigate to linked HelpRequest or start individual task
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — shown when no tasks exist yet for this virtue + type
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTaskState extends StatelessWidget {
  final String virtue;
  final bool showSocial;
  final Color accentColor;

  const _EmptyTaskState({
    required this.virtue,
    required this.showSocial,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showSocial ? Icons.people_outline : Icons.self_improvement,
              color: accentColor.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              showSocial
                  ? 'No community tasks yet for $virtue'
                  : 'No solo tasks yet for $virtue',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              showSocial
                  ? 'We are looking for people in the community who need your help building $virtue together.'
                  : 'Individual tasks for $virtue will be generated based on your wish.',
              style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle tab widget
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.black : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
