import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/shared/widgets/mascot_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/wish_repository.dart';
import '../../wish/wish_entry_screen.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';

class WishScreen extends ConsumerStatefulWidget {
  const WishScreen({super.key});

  @override
  ConsumerState<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends ConsumerState<WishScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeWish;
  List<UserVirtue> _virtues = [];
  List<Habit> _habits = [];
  List<HelpRequest> _communityRequests = [];

  int _onboardingStage = 0; // 0 = Dashboard, 1 = Wish Entry

  @override
  void initState() {
    super.initState();
    _loadData();
    _markVisited();
  }

  Future<void> _markVisited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_visited_wish_module', true);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(wishRepositoryProvider);
    _activeWish = await repo.getActiveWish();
    if (_activeWish != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_wish', true);
      _stats = await repo.getUserStats();
      _virtues = await repo.getUserVirtues();
      _habits = await repo.getUserHabits();
      _communityRequests = await repo.getRecommendedHelpRequests('Ethical');
      _onboardingStage = 0;
    } else {
      _onboardingStage = 1; // Show Wish Entry Landing
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleHabit(Habit habit) async {
    final repo = ref.read(wishRepositoryProvider);
    await repo.toggleHabit(habit.id);
    await _loadData();

    if (mounted) {
      final isNowCompleted = !habit.completedToday;
      final msg = isNowCompleted
          ? 'Completed today 🌱'
          : 'Habit marked incomplete.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isNowCompleted ? AppColors.red : AppColors.textMid,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddHabitDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedVirtue = 'Discipline';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                top: AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Small Habit',
                        style: TextStyle(
                          color: AppColors.red,
                          fontFamily: 'Georgia',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMid),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: const InputDecoration(
                      labelText: 'Habit Title',
                      hintText: 'e.g. Spend 5 minutes reflecting',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Build mental clarity every morning',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supporting Value',
                    style: TextStyle(color: AppColors.textMid, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kAllVirtues.map((virtue) {
                      final isSelected = selectedVirtue == virtue;
                      return ChoiceChip(
                        label: Text(virtue),
                        selected: isSelected,
                        selectedColor: AppColors.red,
                        backgroundColor: AppColors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedVirtue = virtue);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final repo = ref.read(wishRepositoryProvider);
                      await repo.addCustomHabit(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        virtueName: selectedVirtue,
                        category: 'Mind',
                        xpReward: 20,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      'Add Habit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.red),
        ),
      );
    }

    if (_onboardingStage > 0) {
      return _buildOnboardingLanding();
    }

    return _buildDashboard();
  }

  Widget _buildOnboardingLanding() {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Title & Subtitle
              Text(
                "What's your\nWish Today?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every wish you share,\ncreates ripples of change.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Mascot Illustration
              const MascotWidget(height: 200, state: MascotState.welcoming),
              const Spacer(),

              // Action Cards
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WishEntryScreen()),
                  ).then((_) => _loadData());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_outline, color: AppColors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Make a Wish',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Share your heart',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your wish history is saved in your path.')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.tan1, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.redPale,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_outlined, color: AppColors.red, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Wish Stories',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your journey so far',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, color: AppColors.textMid, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Your Wish & Journey',
          style: TextStyle(
            color: AppColors.red,
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.red),
            tooltip: 'Make a New Wish',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WishEntryScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Wish Hero Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.tan1, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'CURRENT WISH FOCUS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _activeWish?['wish_statement'] ?? 'Accomplish core personal growth',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontFamily: 'Georgia',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Values Support Chips
            if (_virtues.isNotEmpty) ...[
              const Text(
                'VALUES YOU ARE DEVELOPING',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _virtues.map((v) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.redMuted),
                    ),
                    child: Text(
                      v.virtueName,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Daily Habit Overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TODAY\'S HABITS',
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddHabitDialog,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.red),
                  label: const Text(
                    'Add Habit',
                    style: TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No small habits set for today yet.',
                  style: TextStyle(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._habits.map(
                (habit) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: habit.completedToday ? AppColors.redMuted : AppColors.tan1,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleHabit(habit),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: habit.completedToday ? AppColors.red : Colors.transparent,
                              border: Border.all(
                                color: habit.completedToday ? AppColors.red : AppColors.tan2,
                                width: 2,
                              ),
                            ),
                            child: habit.completedToday
                                ? const Icon(Icons.check, color: AppColors.white, size: 18)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  decoration: habit.completedToday ? TextDecoration.lineThrough : null,
                                  decorationColor: AppColors.textLight,
                                ),
                              ),
                              if (habit.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  habit.description,
                                  style: TextStyle(
                                    color: AppColors.textMid,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Community Opportunity
            if (_communityRequests.isNotEmpty) ...[
              const Text(
                'OPTIONAL COMMUNITY OPPORTUNITY',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ..._communityRequests.take(2).map(
                (req) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.tan1, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.title,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        req.description,
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
