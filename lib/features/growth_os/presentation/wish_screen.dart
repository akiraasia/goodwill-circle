import 'dart:math';
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

  int _onboardingStage = 0; // 0 = Dashboard, 1 = Wish Entry Landing

  // View navigation state: 'wish', 'calendar', 'diary'
  String _currentView = 'wish';

  // Mascot animation state
  MascotState _mascotState = MascotState.idle;

  // Calendar state
  DateTime _calDate = DateTime.now();
  late int _selectedDay;

  // Diary state
  int _selectedMood = 0;
  final List<String> _moods = ['😄', '🙂', '😐', '😕', '😢'];
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _gratitudeController = TextEditingController();

  // Companion Chat state
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];

  static const List<String> _botReplies = [
    "That's wonderful to hear! Keep going 🌸",
    "I'm proud of you for showing up today.",
    "Every small step counts. You're doing great.",
    "Thank you for sharing that with me.",
    "I'm here with you on your journey step by step.",
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
    _loadData();
    _markVisited();
    _triggerWinkOnMount();
  }

  void _triggerWinkOnMount() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _mascotState = MascotState.winking);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _mascotState = MascotState.idle);
          }
        });
      }
    });
  }

  void _triggerMascotJump() {
    setState(() => _mascotState = MascotState.celebrating);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _mascotState = MascotState.idle);
      }
    });
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
      _virtues = await repo.getUserVirtues();
      _habits = await repo.getUserHabits();
      _communityRequests = await repo.getRecommendedHelpRequests('Ethical');
      _onboardingStage = 0;
    } else {
      _onboardingStage = 1;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleHabit(Habit habit) async {
    final repo = ref.read(wishRepositoryProvider);
    await repo.toggleHabit(habit.id);
    await _loadData();
    _triggerMascotJump();
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatController.clear();
    });

    _triggerMascotJump();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final randomReply = _botReplies[Random().nextInt(_botReplies.length)];
        setState(() {
          _chatMessages.add({'role': 'bot', 'text': randomReply});
          if (_chatMessages.length > 6) {
            _chatMessages.removeAt(0);
          }
        });
      }
    });
  }

  void _toggleView(String name) {
    setState(() {
      if (_currentView == name) {
        _currentView = 'wish';
      } else {
        _currentView = name;
      }
    });
  }

  // Get duration string for a task item
  String _getTaskDuration(int index, String title) {
    if (index == 0) return '1–2 min'; // Guarantee easy entry 1-2 min task!
    if (title.contains('walk') || title.contains('Connect')) return '10 min';
    if (title.contains('Help') || title.contains('Community')) return '15–20 min';
    return '5 min';
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _gratitudeController.dispose();
    _chatController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar / Title
            _buildTopAppBar(),

            // Primary View Switcher
            Expanded(
              child: Stack(
                children: [
                  // Main Scrollable View Content
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        top: AppSpacing.sm,
                        bottom: 140, // Space for chat bar & nav
                      ),
                      child: _buildCurrentViewContent(),
                    ),
                  ),

                  // Chat Log Overlay Floating Bubbles
                  if (_chatMessages.isNotEmpty)
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: 72,
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _chatMessages.take(3).map((msg) {
                            final isUser = msg['role'] == 'user';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.red : AppColors.white,
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                                    bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textDark.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(
                                    color: isUser ? AppColors.white : AppColors.textDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Companion Chat Input Bar (persistent)
            _buildCompanionChatBar(),

            // Persistent Wish Views Navigation Bar (Calendar / Diary)
            _buildWishBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _currentView == 'calendar'
                ? 'Calendar'
                : _currentView == 'diary'
                    ? 'My Diary'
                    : 'Goodwill Circle',
            style: const TextStyle(
              color: AppColors.red,
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.red, size: 22),
            tooltip: 'Make a New Wish',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WishEntryScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case 'calendar':
        return _buildCalendarView();
      case 'diary':
        return _buildDiaryView();
      case 'wish':
      default:
        return _buildWishDashboardView();
    }
  }

  // ================= VIEW A: WISH DASHBOARD =================
  Widget _buildWishDashboardView() {
    // Standard default tasks if habits list is empty, guaranteeing 1-2 min task!
    final List<Map<String, String>> defaultTasks = [
      {
        'title': "Write one thing you're proud of",
        'sub': 'Personal',
        'duration': '1–2 min',
      },
      {
        'title': 'Take a 5-minute reflection',
        'sub': 'Personal',
        'duration': '5 min',
      },
      {
        'title': 'Speak to someone new today',
        'sub': 'Personal',
        'duration': '10 min',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mascot Hero Section
        const SizedBox(height: 4),
        MascotWidget(height: 140, state: _mascotState, armsUp: true),
        const SizedBox(height: 8),
        const Text(
          "What's your\nWish Today?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.red,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every wish you share,\ncreates ripples of change.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textMid,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Wish Focus Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.tan1, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, color: AppColors.red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Your Wish Focus',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _activeWish?['wish_statement'] ?? 'I wish to become more confident',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Georgia',
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Values I'm Developing Chips (No morality scores!)
        if (_virtues.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "VALUES I'M DEVELOPING",
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Today's Options Section
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Today's Options",
            style: TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Habit / Task Options List with Time Durations!
        if (_habits.isNotEmpty)
          ..._habits.asMap().entries.map((entry) {
            final idx = entry.key;
            final habit = entry.value;
            final duration = _getTaskDuration(idx, habit.title);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GestureDetector(
                onTap: () => _toggleHabit(habit),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: habit.completedToday ? AppColors.redPale : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: habit.completedToday ? AppColors.redMuted : AppColors.tan1,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.redLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa_outlined, color: AppColors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: habit.completedToday ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  habit.virtueName.isNotEmpty ? habit.virtueName : 'Personal',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const Text(' • ', style: TextStyle(color: AppColors.textLight, fontSize: 11.5)),
                                Text(
                                  duration,
                                  style: const TextStyle(
                                    color: AppColors.red,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: habit.completedToday ? AppColors.red : Colors.transparent,
                          border: Border.all(
                            color: habit.completedToday ? AppColors.red : AppColors.redMuted,
                            width: 2,
                          ),
                        ),
                        child: habit.completedToday
                            ? const Icon(Icons.check, color: AppColors.white, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
        else
          ...defaultTasks.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.tan1, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.redLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        idx == 0 ? Icons.eco : (idx == 1 ? Icons.self_improvement : Icons.people),
                        color: AppColors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['title']!,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                t['sub']!,
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11.5,
                                ),
                              ),
                              const Text(' • ', style: TextStyle(color: AppColors.textLight, fontSize: 11.5)),
                              Text(
                                t['duration']!,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.redMuted, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: AppSpacing.md),

        // Optional Community Opportunity Section
        if (_communityRequests.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Community opportunity",
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Georgia',
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._communityRequests.take(1).map(
            (req) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tan1, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline, color: AppColors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req.title,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        '15–20 min',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    req.description,
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12.5,
                      height: 1.3,
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
    );
  }

  // ================= VIEW B: CALENDAR =================
  Widget _buildCalendarView() {
    final monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    final year = _calDate.year;
    final month = _calDate.month;

    final firstOfMonth = DateTime(year, month, 1);
    int startOffset = firstOfMonth.weekday - 1; // Mon = 0
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysInPrevMonth = DateTime(year, month, 0).day;

    List<Map<String, dynamic>> cells = [];
    for (int i = startOffset; i > 0; i--) {
      cells.add({'num': daysInPrevMonth - i + 1, 'dim': true});
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add({'num': d, 'dim': false});
    }
    while (cells.length % 7 != 0) {
      cells.add({'num': cells.length - (startOffset + daysInMonth) + 1, 'dim': true});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month Navigation Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _calDate = DateTime(_calDate.year, _calDate.month - 1, 1);
                });
              },
              icon: const Icon(Icons.chevron_left, color: AppColors.red),
            ),
            Text(
              "${monthNames[month - 1]} $year",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
                fontFamily: 'Georgia',
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _calDate = DateTime(_calDate.year, _calDate.month + 1, 1);
                });
              },
              icon: const Icon(Icons.chevron_right, color: AppColors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Day of Week Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            return SizedBox(
              width: 38,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Grid of Days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: cells.length,
          itemBuilder: (context, idx) {
            final cell = cells[idx];
            final num = cell['num'] as int;
            final isDim = cell['dim'] as bool;
            final isSelected = !isDim && num == _selectedDay;
            final hasActivity = !isDim && (num == DateTime.now().day || num == 14);

            return GestureDetector(
              onTap: isDim
                  ? null
                  : () {
                      setState(() => _selectedDay = num);
                      _triggerMascotJump();
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.red : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$num',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? AppColors.white
                            : (isDim ? AppColors.tan2 : AppColors.textDark),
                      ),
                    ),
                    if (hasActivity && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.redSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Today / Selected Date Task List
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.tan1, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today · ${monthNames[month - 1]} $_selectedDay",
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 12),
              _buildCalendarTaskRow(
                title: "Take a 5-minute reflection",
                sub: "Personal • 5 min",
                isDone: true,
              ),
              const Divider(height: 16, color: AppColors.cream),
              _buildCalendarTaskRow(
                title: "Speak to someone new today",
                sub: "Personal • 10 min",
                isDone: false,
              ),
              const Divider(height: 16, color: AppColors.cream),
              _buildCalendarTaskRow(
                title: "Write one thing you're proud of",
                sub: "Personal • 1–2 min",
                isDone: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Footer Mascot
        Align(
          alignment: Alignment.centerRight,
          child: MascotWidget(height: 64, state: _mascotState),
        ),
      ],
    );
  }

  Widget _buildCalendarTaskRow({
    required String title,
    required String sub,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.redLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.red, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.red : Colors.transparent,
            border: Border.all(color: AppColors.red, width: 2),
          ),
          child: isDone
              ? const Icon(Icons.check, color: AppColors.white, size: 12)
              : null,
        ),
      ],
    );
  }

  // ================= VIEW C: DIARY =================
  Widget _buildDiaryView() {
    final now = DateTime.now();
    final monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Diary Date Header
        Text(
          "${monthNames[now.month - 1]} ${now.day}, ${now.year}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMid,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Card: How are you feeling?
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.tan1, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _moods.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final emoji = entry.value;
                  final isSelected = idx == _selectedMood;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMood = idx);
                      _triggerMascotJump();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.red : AppColors.redLight,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.red.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: isSelected ? 22 : 18),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Card: Today's Reflection
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.tan1, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Reflection",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reflectionController,
                maxLength: 500,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts here...',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: AppColors.textLight, fontSize: 11),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Card: Gratitude for today
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.tan1, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gratitude for today',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _gratitudeController,
                maxLength: 300,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'What are you grateful for today?',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: AppColors.textLight, fontSize: 11),
                ),
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: MascotWidget(height: 52, state: _mascotState),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= COMPANION CHAT BAR =================
  Widget _buildCompanionChatBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const MascotWidget(height: 32),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: AppColors.textDark, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Chat with your companion...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _sendChatMessage(),
            ),
          ),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.red,
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.white, size: 14),
              onPressed: _sendChatMessage,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ================= WISH PERSISTENT NAVIGATION BAR =================
  Widget _buildWishBottomNav() {
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.sm,
        top: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleView('calendar'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _currentView == 'calendar' ? AppColors.redMuted : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: _currentView == 'calendar' ? AppColors.white : AppColors.textMid,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Calendar',
                      style: TextStyle(
                        color: _currentView == 'calendar' ? AppColors.white : AppColors.textMid,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleView('diary'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _currentView == 'diary' ? AppColors.redMuted : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: _currentView == 'diary' ? AppColors.white : AppColors.textMid,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Diary',
                      style: TextStyle(
                        color: _currentView == 'diary' ? AppColors.white : AppColors.textMid,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ONBOARDING LANDING =================
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
              const Text(
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
              const Text(
                'Every wish you share,\ncreates ripples of change.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              const MascotWidget(height: 180, state: MascotState.welcoming),
              const Spacer(),
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
}
