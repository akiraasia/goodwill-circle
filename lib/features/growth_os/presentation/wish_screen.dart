import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/widgets/shooting_star_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/wish_repository.dart';
import '../../wish/wish_interview_screen.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';

const Color _emerald = Color(0xFF10B981);
const Color _emeraldAccent = Color(0xFF34D399);

class WishScreen extends ConsumerStatefulWidget {
  const WishScreen({super.key});

  @override
  ConsumerState<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends ConsumerState<WishScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeWish;
  WishStats? _stats;
  List<UserVirtue> _virtues = [];
  List<Habit> _habits = [];
  List<HelpRequest> _communityRequests = [];
  
  // Navigation & Onboarding State
  int _onboardingStage = 0; // 0 = Dashboard, 1 = Wish Entry, 2 = Interview
  String _rawWishText = '';

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
      _stats = await repo.getUserStats();
      _virtues = await repo.getUserVirtues();
      _habits = await repo.getUserHabits();
      _communityRequests = await repo.getRecommendedHelpRequests('Ethical');
      _onboardingStage = 0;
    } else {
      _onboardingStage = 1; // Start onboarding
    }
    setState(() => _isLoading = false);
  }

  // --- Onboarding Handlers ---

  void _onWishEntered(String wishText) {
    setState(() {
      _rawWishText = wishText;
    });
    ShootingStarOverlay.show(
      context,
      wishText: wishText,
      onComplete: () {
        setState(() {
          _onboardingStage = 2; // Move to interview
        });
      },
    );
  }

  // --- Habit Handlers ---

  Future<void> _toggleHabit(Habit habit) async {
    final repo = ref.read(wishRepositoryProvider);
    await repo.toggleHabit(habit.id);
    await _loadData();

    if (mounted) {
      final isNowCompleted = !habit.completedToday;
      final msg = isNowCompleted
          ? 'Completed! +${habit.xpReward} ${habit.virtueName} XP 🔥'
          : 'Habit marked incomplete.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isNowCompleted ? Icons.check_circle : Icons.info, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: isNowCompleted ? _emerald : Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddHabitDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedVirtue = 'Discipline';
    String selectedCategory = 'Mind';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Custom Habit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Habit Title',
                      labelStyle: const TextStyle(color: Colors.white60),
                      hintText: 'e.g. Read 15 mins of Philosophy',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description / Goal',
                      labelStyle: const TextStyle(color: Colors.white60),
                      hintText: 'e.g. Build mental clarity every morning',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Virtue Alignment', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kAllVirtues.map((virtue) {
                      final isSelected = selectedVirtue == virtue;
                      return ChoiceChip(
                        label: Text(virtue),
                        selected: isSelected,
                        selectedColor: Colors.amberAccent,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
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
                        category: selectedCategory,
                        xpReward: 20,
                      );
                      if (mounted) Navigator.pop(context);
                      await _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Add Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _postWishToCircle() async {
    if (_activeWish == null) return;
    final repo = ref.read(wishRepositoryProvider);
    final totalScore = (_stats?.physical ?? 10) + (_stats?.mental ?? 10) + (_stats?.ethicalEmotional ?? 10);
    await repo.postWishAsHelpRequest(
      wishStatement: _activeWish!['wish_statement'] ?? '',
      characterScore: totalScore,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wish posted to Goodwill Circle as a Help Request! Community members can now offer guidance.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1D),
        body: Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
      );
    }

    if (_onboardingStage > 0) {
      return _buildOnboardingFlow();
    }

    return _buildDashboard();
  }

  Widget _buildOnboardingFlow() {
    switch (_onboardingStage) {
      case 1:
        return _WishEntryView(onSubmit: _onWishEntered);
      case 2:
        return WishInterviewScreen(initialWish: _rawWishText);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard() {
    final totalScore = (_stats?.physical ?? 10) + (_stats?.mental ?? 10) + (_stats?.ethicalEmotional ?? 10);
    final userLvl = (totalScore / 3).toInt();
    final completedHabitsCount = _habits.where((h) => h.completedToday).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Wish & Character Path', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            tooltip: 'Cast New Wish',
            onPressed: () {
              setState(() {
                _onboardingStage = 1;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Wish Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2942), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amberAccent.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ACTIVE GOAL & WISH',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: Colors.amberAccent,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Lvl $userLvl Character',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _activeWish?['wish_statement'] ?? 'Accomplish core personal growth',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _postWishToCircle,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Connect to Goodwill Circle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Streak & Daily Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Habit Streak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('$completedHabitsCount of ${_habits.length} habits completed today', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _showAddHabitDialog,
                    icon: const Icon(Icons.add_circle, color: Colors.amberAccent, size: 32),
                    tooltip: 'Add Custom Habit',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Habit Tracker Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DAILY HABIT TRACKER',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                TextButton.icon(
                  onPressed: _showAddHabitDialog,
                  icon: const Icon(Icons.add, size: 16, color: Colors.amberAccent),
                  label: const Text('Add Habit', style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_habits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No habits created yet. Tap + to add one!', style: TextStyle(color: Colors.white38), textAlign: TextAlign.center),
              )
            else
              ..._habits.map((habit) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: habit.completedToday 
                        ? _emerald.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: habit.completedToday
                          ? _emerald.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleHabit(habit),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: habit.completedToday ? _emerald : Colors.transparent,
                            border: Border.all(
                              color: habit.completedToday ? _emerald : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: habit.completedToday
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: habit.completedToday ? TextDecoration.lineThrough : null,
                                    decorationColor: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                            if (habit.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(habit.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    habit.virtueName.toUpperCase(),
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('🔥 ${habit.streakDays}d streak', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                                const Spacer(),
                                Text('+${habit.xpReward} XP', style: const TextStyle(color: _emeraldAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            const SizedBox(height: 24),

            // Character Virtues & Stats Section
            const Text(
              'CHARACTER VIRTUES & LEVELING',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            if (_virtues.isEmpty)
              const Text('No virtues assigned yet.', style: TextStyle(color: Colors.white38))
            else
              ..._virtues.map((virtue) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _VirtueProgressCard(virtue: virtue),
              )),
            const SizedBox(height: 24),

            // Goodwill Circle Action Matching
            const Text(
              'GOODWILL CIRCLE COMMUNITY ACTIONS',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            if (_communityRequests.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('No community requests matching at the moment. Keep building habits!', style: TextStyle(color: Colors.white54)),
              )
            else
              ..._communityRequests.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(req.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('+30 Compassion XP', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(req.description, style: const TextStyle(color: Colors.white60, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening community request details...'), backgroundColor: Colors.blue),
                            );
                          },
                          icon: const Icon(Icons.handshake, size: 16, color: Colors.blueAccent),
                          label: const Text('Volunteer & Earn XP', style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ─── Virtue Progress Card Component ──────────────────────────────────────────

class _VirtueProgressCard extends ConsumerStatefulWidget {
  final UserVirtue virtue;
  const _VirtueProgressCard({required this.virtue});

  @override
  ConsumerState<_VirtueProgressCard> createState() => _VirtueProgressCardState();
}

class _VirtueProgressCardState extends ConsumerState<_VirtueProgressCard> {
  bool _isExpanded = false;
  List<VirtueChatMessage> _chatMessages = [];
  final _chatController = TextEditingController();

  Future<void> _loadChat() async {
    final repo = ref.read(wishRepositoryProvider);
    _chatMessages = await repo.getVirtueChatMessages(widget.virtue.virtueName);
    if (mounted) setState(() {});
  }

  void _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    await ref.read(wishRepositoryProvider).sendVirtueChat(widget.virtue.virtueName, text);
    await _loadChat();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.virtue.virtueName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.virtue.xpProgress == 0 ? 0.05 : widget.virtue.xpProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lvl ${widget.virtue.level} • ${widget.virtue.xp}/${widget.virtue.xpToNextLevel} XP',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            if (expanded) _loadChat();
          },
          children: [
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      kVirtueDescription[widget.virtue.virtueName] ?? 'Cultivate this virtue through daily habits.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.forum, size: 16, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Virtue Circle Chat (${widget.virtue.virtueName})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _chatMessages.isEmpty
                          ? const Center(child: Text('No community messages yet. Share your experience!', style: TextStyle(color: Colors.white38, fontSize: 11)))
                          : ListView.builder(
                              itemCount: _chatMessages.length,
                              itemBuilder: (context, index) {
                                final m = _chatMessages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: '${m.senderName}: ', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                        TextSpan(text: m.message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Share a progress note...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendChat(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.amberAccent, size: 20),
                          onPressed: _sendChat,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stage 1: Wish Entry Screen Component ────────────────────────────────────

class _WishEntryView extends StatefulWidget {
  final Function(String) onSubmit;
  const _WishEntryView({required this.onSubmit});

  @override
  State<_WishEntryView> createState() => _WishEntryViewState();
}

class _WishEntryViewState extends State<_WishEntryView> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amberAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 48),
                  const SizedBox(height: 24),
                  const Text(
                    'What is your honest wish or goal?',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Define the goal you wish to accomplish. Goodwill Circle will build your habit tracker, virtues, and character enhancement path.',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 18),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'I wish to...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final val = _controller.text.trim();
                      if (val.isNotEmpty) widget.onSubmit(val);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Cast Wish & Set My Path', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
