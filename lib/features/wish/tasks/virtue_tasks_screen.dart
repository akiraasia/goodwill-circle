import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/shared/widgets/mascot_widget.dart';
import 'virtue_task.dart';
import 'virtue_task_repository.dart';
import 'wish_task_generator.dart';

class VirtueTasksScreen extends ConsumerStatefulWidget {
  final List<String> assignedVirtues;

  const VirtueTasksScreen({Key? key, required this.assignedVirtues}) : super(key: key);

  @override
  ConsumerState<VirtueTasksScreen> createState() => _VirtueTasksScreenState();
}

class _VirtueTasksScreenState extends ConsumerState<VirtueTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSocial = true;
  bool _isGeneratingTasks = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.assignedVirtues.isEmpty ? 1 : widget.assignedVirtues.length,
      vsync: this,
    );
    _generateInitialTasks();
  }

  Future<void> _generateInitialTasks() async {
    final repo = ref.read(virtueTaskRepositoryProvider);
    final existingTasks = await repo.getMyTasks();
    
    if (existingTasks.isEmpty) {
      setState(() => _isGeneratingTasks = true);
      String userWish = 'To grow and become a better person';
      final taskGenerator = WishTaskGenerator();
      
      for (final virtue in widget.assignedVirtues) {
        final generated = await taskGenerator.generateDualTrackTasks(
          wish: userWish,
          virtue: virtue,
          currentLevel: 1,
        );
        
        for (final task in generated) {
          if (task['type'] == 'solo') {
            await repo.insertTask(
              virtueName: virtue,
              taskType: TaskType.individual,
              title: task['title'] ?? 'Solo $virtue Task',
              description: task['description'] ?? 'Practice $virtue',
              xpReward: task['xp'] ?? 20,
            );
          } else {
            bool matched = false;
            final helperMatches = await repo.findMatchedRequests(virtue: virtue, role: 'helper');
            if (helperMatches.isNotEmpty) {
              final matchedRequest = helperMatches.first;
              await repo.insertTask(
                virtueName: virtue,
                taskType: TaskType.social,
                title: 'Help: ${matchedRequest["title"]}',
                description: task['description'] ?? 'Help someone build $virtue.',
                xpReward: task['xp'] ?? 50,
                linkedRequestId: matchedRequest['id'] as String?,
                socialRole: 'helper',
              );
              matched = true;
            } else {
              final helpeeMatches = await repo.findMatchedRequests(virtue: virtue, role: 'helpee');
              if (helpeeMatches.isNotEmpty) {
                final matchedRequest = helpeeMatches.first;
                await repo.insertTask(
                  virtueName: virtue,
                  taskType: TaskType.social,
                  title: 'Learn: ${matchedRequest["title"]}',
                  description: task['description'] ?? 'Join this request to build your $virtue.',
                  xpReward: task['xp'] ?? 40,
                  linkedRequestId: matchedRequest['id'] as String?,
                  socialRole: 'helpee',
                );
                matched = true;
              }
            }
            
            if (!matched) {
              await repo.insertTask(
                virtueName: virtue,
                taskType: TaskType.social,
                title: task['title'] ?? 'Community $virtue Task',
                description: task['description'] ?? 'Connect with others.',
                xpReward: task['xp'] ?? 30,
              );
            }
          }
        }
      }
      
      if (mounted) {
        setState(() => _isGeneratingTasks = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _virtueColor(String virtue) =>
      _virtueColors[virtue] ?? AppColors.red;

  IconData _virtueIcon(String virtue) =>
      _virtueIcons[virtue] ?? Icons.star;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Your Path Tasks',
          style: TextStyle(
            color: AppColors.red,
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () => context.go('/app'),
              icon: const Icon(Icons.home, size: 16, color: AppColors.red),
              label: const Text('Home', style: TextStyle(color: AppColors.red)),
            ),
          ),
        ],
        bottom: widget.assignedVirtues.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.red,
                labelColor: AppColors.red,
                unselectedLabelColor: AppColors.textLight,
                tabs: widget.assignedVirtues
                    .map((v) => Tab(
                          child: Row(
                            children: [
                              Icon(_virtueIcon(v), color: _virtueColor(v), size: 16),
                              const SizedBox(width: 6),
                              Text(v),
                            ],
                          ),
                        ))
                    .toList(),
              )
            : null,
      ),
      body: _isGeneratingTasks
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.red),
                  SizedBox(height: 16),
                  Text(
                    'Generating your personalized tasks...',
                    style: TextStyle(color: AppColors.textMid),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.tan1.withValues(alpha: 0.5),
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
                              child: Text(
                                'No values assigned yet.',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            )
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
          return const Center(child: CircularProgressIndicator(color: AppColors.red));
        }

        final tasks = (snapshot.data ?? [])
            .where((t) => showSocial ? t.isSocial : t.isIndividual)
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

class _TaskCard extends ConsumerWidget {
  final VirtueTask task;
  final Color accentColor;

  const _TaskCard({required this.task, required this.accentColor});

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.completed: return Colors.green.shade600;
      case TaskStatus.inProgress: return AppColors.red;
      default: return AppColors.red;
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.completed: return 'Completed 🌱';
      case TaskStatus.inProgress: return 'In Progress';
      default: return task.isSocial ? 'View Opportunity' : 'Start Task';
    }
  }

  void _handleTaskAction(BuildContext context, WidgetRef ref, VirtueTask task) async {
    final repo = ref.read(virtueTaskRepositoryProvider);
    
    if (task.isSocial && task.linkedRequestId != null) {
      if (context.mounted) {
        context.go('/app');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening community request: ${task.linkedRequestId}')),
        );
      }
    } else {
      await repo.updateTaskStatus(task.id, TaskStatus.inProgress);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task started! 🌱')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tan1, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.redPale,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  task.isSocial ? Icons.people : Icons.self_improvement,
                  color: AppColors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: const TextStyle(color: AppColors.textMid, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: task.status != TaskStatus.completed
                        ? () => _handleTaskAction(context, ref, task)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColor,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
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
            const MascotWidget(height: 120),
            const SizedBox(height: 24),
            Text(
              showSocial
                  ? 'No community tasks yet for $virtue'
                  : 'No solo tasks yet for $virtue',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              showSocial
                  ? 'We are looking for people in the community who need your help building $virtue together.'
                  : 'Individual tasks for $virtue will be generated based on your wish.',
              style: const TextStyle(color: AppColors.textMid, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.red : AppColors.textMid,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.red : AppColors.textMid,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
