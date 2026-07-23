import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/shared/widgets/shooting_star_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/wish_repository.dart';

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
  List<WishTask> _wishTasks = [];
  List<Novel> _novels = [];
  
  // Navigation State
  int _onboardingStage = 0; // 0=None/Done, 1=Entry, 2=Interview, 3=Confirm, 4=Stats, 5=Path
  UserVirtue? _selectedVirtue; // For virtue detail view
  
  // Onboarding Data
  String _rawWishText = '';
  List<WishInterviewQA> _interviewQA = [];
  AssignedStats? _assignedStats;

  // Visual Novel State
  Novel? _activeNovel;
  NovelScene? _currentScene;
  List<NovelChoice> _sceneChoices = [];
  bool _storyLoading = false;
  final _storyInputController = TextEditingController();

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

  @override
  void dispose() {
    _storyInputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(wishRepositoryProvider);
    _activeWish = await repo.getActiveWish();
    if (_activeWish != null) {
      _stats = await repo.getUserStats();
      _virtues = await repo.getUserVirtues();
      _wishTasks = await repo.getUserTasks();
      _novels = await repo.getNovels();
      _onboardingStage = 0;
    } else {
      _onboardingStage = 1; // Start onboarding
    }
    setState(() => _isLoading = false);
  }

  // --- Onboarding Flow ---

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

  void _onInterviewComplete(List<WishInterviewQA> qa, AssignedStats stats) {
    setState(() {
      _interviewQA = qa;
      _assignedStats = stats;
      _onboardingStage = 3; // Move to confirmation
    });
  }

  void _onConfirmationComplete() async {
    setState(() => _isLoading = true);
    
    // Simulate AI final processing
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _onboardingStage = 4; // Move to stat reveal
      _isLoading = false;
    });
  }

  void _onStatsRevealed() {
    setState(() {
      _onboardingStage = 5; // Move to path choice
    });
  }

  Future<void> _onPathChosen(String pathMode) async {
    setState(() => _isLoading = true);
    final repo = ref.read(wishRepositoryProvider);
    
    await repo.createUserWish(
      wishStatement: _rawWishText,
      physicalCondition: 'Derived from interview', // Simplification for MVP
      mentalCondition: 'Derived from interview',
      interviewData: _interviewQA,
      assignedStats: _assignedStats,
      pathMode: pathMode,
    );

    await _loadData(); // Reload to enter dashboard
  }

  // --- Novel Game Loop ---

  Future<void> _startNovel(Novel novel) async {
    setState(() => _storyLoading = true);
    final repo = ref.read(wishRepositoryProvider);
    final progress = await repo.getNovelProgress(novel.id);

    final scenes = await repo.getNovelScenes(novel.id);
    NovelScene targetScene;

    if (progress != null && !progress['completed']) {
      final sceneId = progress['current_scene_id'] as String;
      targetScene = scenes.firstWhere((s) => s.id == sceneId, orElse: () => scenes.first);
    } else {
      targetScene = scenes.first;
    }

    final choices = await repo.getSceneChoices(targetScene.id);

    setState(() {
      _activeNovel = novel;
      _currentScene = targetScene;
      _sceneChoices = choices;
      _storyLoading = false;
    });
  }

  Future<void> _completeTask(WishTask task) async {
    setState(() => _isLoading = true);
    final repo = ref.read(wishRepositoryProvider);
    await repo.completeTask(task.id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task completed! You gained stats.'), backgroundColor: Colors.green));
    }
  }

  Future<void> _requestTaskForChoice(NovelChoice choice) async {
    setState(() => _storyLoading = true);
    final repo = ref.read(wishRepositoryProvider);
    // Simple AI task generation mock
    final targetStat = choice.requiredSubStats.keys.isNotEmpty ? choice.requiredSubStats.keys.first : 'general';
    await repo.assignTask(
      taskText: 'Train your $targetStat to unlock this path.',
      targetStatCategory: choice.requiredPhysical > 0 ? 'physical' : (choice.requiredMental > 0 ? 'mental' : 'ethical'),
      targetSubStat: targetStat,
      rewardAmount: 2,
    );
    await _loadData();
    if (mounted) {
      setState(() => _storyLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI assigned a new task! Check your dashboard.'), backgroundColor: AppColors.redSoft));
    }
  }

  Future<void> _makeChoice(NovelChoice choice) async {
    if (_activeNovel == null) return;
    setState(() => _storyLoading = true);

    final repo = ref.read(wishRepositoryProvider);

    if (_stats != null) {
      final newPhysical = _stats!.physical + choice.rewardPhysical;
      final newMental = _stats!.mental + choice.rewardMental;
      final newEthical = _stats!.ethicalEmotional + choice.rewardEthical;
      
      await repo.updateStats(
        physical: newPhysical,
        mental: newMental,
        ethical: newEthical,
      );
      
      _stats = WishStats(physical: newPhysical, mental: newMental, ethicalEmotional: newEthical);
    }

    if (choice.targetSceneId != null) {
      final scenes = await repo.getNovelScenes(_activeNovel!.id);
      final nextScene = scenes.firstWhere((s) => s.id == choice.targetSceneId);
      final nextChoices = await repo.getSceneChoices(nextScene.id);

      await repo.saveNovelProgress(_activeNovel!.id, nextScene.id, nextScene.isEnding);

      setState(() {
        _currentScene = nextScene;
        _sceneChoices = nextChoices;
        _storyLoading = false;
      });
    } else {
      setState(() {
        _storyLoading = false;
      });
    }
  }

  Future<void> _submitFreeResponse() async {
    final text = _storyInputController.text.trim();
    if (text.isEmpty || _activeNovel == null || _currentScene == null) return;
    
    _storyInputController.clear();
    setState(() => _storyLoading = true);
    
    // In a real implementation, we would send this to Gemini to generate the next scene.
    // For now, we simulate a response.
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _currentScene = NovelScene(
        id: 'ai-generated-${DateTime.now().millisecondsSinceEpoch}',
        novelId: _activeNovel!.id,
        title: 'AI Continuation',
        content: 'The AI processes your action: "$text". The environment shifts accordingly. Your journey continues...',
        isEnding: false,
      );
      _sceneChoices = []; // Clear preset choices, rely on free text
      _storyLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_onboardingStage > 0) {
      return _buildOnboardingFlow();
    }

    if (_activeNovel != null) {
      return _buildNovelPlayer();
    }

    if (_selectedVirtue != null) {
      return VirtueDetailScreen(
        virtue: _selectedVirtue!,
        onBack: () => setState(() => _selectedVirtue = null),
      );
    }

    return _buildDashboard();
  }

  Widget _buildOnboardingFlow() {
    switch (_onboardingStage) {
      case 1:
        return _WishEntryScreen(onSubmit: _onWishEntered);
      case 2:
        return _AIChatOnboardingScreen(wishText: _rawWishText, onComplete: _onInterviewComplete);
      case 3:
        return _TruthConfirmationScreen(qaList: _interviewQA, onConfirm: _onConfirmationComplete);
      case 4:
        return _StatAssignmentScreen(stats: _assignedStats!, onContinue: _onStatsRevealed);
      case 5:
        return _PathChoiceScreen(onChoice: _onPathChosen);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard() {
    final totalScore = _stats!.physical + _stats!.mental + _stats!.ethicalEmotional;
    final userLvl = (totalScore / 3).toInt();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My Wish Board'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Wish Card
            AppCard(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.yellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'MY HONEST WISH',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.tan3,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeWish!['wish_statement'] ?? '',
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Level $userLvl Character',
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Base Stats
            Text(
              'MY STATS',
              style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ExpandableStatCard(title: 'Physical', value: _stats!.physical, color: Colors.orange, details: _stats!.physicalDetails)),
                const SizedBox(width: 8),
                Expanded(child: _ExpandableStatCard(title: 'Mental', value: _stats!.mental, color: Colors.blue, details: _stats!.mentalDetails)),
                const SizedBox(width: 8),
                Expanded(child: _ExpandableStatCard(title: 'Ethical', value: _stats!.ethicalEmotional, color: AppColors.red, details: _stats!.ethicalDetails)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // My Tasks
            Text(
              'MY TASKS',
              style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_wishTasks.isEmpty)
              const Text('No tasks assigned. Keep playing to get some!')
            else
              ..._wishTasks.where((t) => t.status != 'completed').map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: AppCard(
                  color: AppColors.white,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.taskText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('+${t.rewardAmount} ${t.targetSubStat} (${t.targetStatCategory})'),
                    trailing: ElevatedButton(
                      onPressed: () => _completeTask(t),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.redSoft),
                      child: const Text('Complete'),
                    ),
                  ),
                ),
              )),
            const SizedBox(height: AppSpacing.md),

            // Virtues (Stat Hubs)
            Text(
              'MY STAT HUBS (COMMUNITIES)',
              style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_virtues.isEmpty)
              const Text('No stats assigned yet.')
            else
              ..._virtues.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _VirtueCard(
                  virtue: v,
                  onTap: () => setState(() => _selectedVirtue = v),
                ),
              )),
            const SizedBox(height: AppSpacing.md),
            
            // Path Mode display
            Text(
              'CURRENT PATH: ${_activeWish!['path_mode']?.toString().toUpperCase() ?? 'TASK'} MODE',
              style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_activeWish!['path_mode'] == 'story')
              ..._novels.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: AppCard(
                  color: AppColors.white,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(n.description),
                    trailing: ElevatedButton(
                      onPressed: () => _startNovel(n),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.redSoft),
                      child: const Text('Play'),
                    ),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildNovelPlayer() {
    if (_currentScene == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title: Text('AI Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                leading: Icon(Icons.psychology, color: AppColors.red),
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: Text(
                    'AI Chatbot coming soon!\n\nHere you can ask for specific tasks, guidance, and clarification on your journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMid),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(_activeNovel!.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _activeNovel = null;
              _currentScene = null;
              _sceneChoices = [];
            });
            _loadData();
          },
        ),
      ),
      body: _storyLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Scene Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppCard(
                      color: AppColors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentScene!.title.toUpperCase(),
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.redSoft,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentScene!.content,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Choices or Free Text
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: _currentScene!.isEnding
                      ? ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _activeNovel = null;
                              _currentScene = null;
                              _sceneChoices = [];
                            });
                            _loadData();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, minimumSize: const Size.fromHeight(50)),
                          child: const Text('Complete Story & Claim Rewards'),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_sceneChoices.isNotEmpty) ...[
                              Text(
                                'PRESET CHOICES',
                                style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._sceneChoices.map((choice) {
                                final meetsPhysical = _stats == null || _stats!.physical >= choice.requiredPhysical;
                                final meetsMental = _stats == null || _stats!.mental >= choice.requiredMental;
                                final meetsEthical = _stats == null || _stats!.ethicalEmotional >= choice.requiredEthical;
                                
                                bool meetsSubStats = true;
                                if (_stats != null) {
                                  for (final entry in choice.requiredSubStats.entries) {
                                    final val = _stats!.physicalDetails[entry.key] ?? _stats!.mentalDetails[entry.key] ?? _stats!.ethicalDetails[entry.key] ?? 0.0;
                                    if (val < entry.value) {
                                      meetsSubStats = false;
                                      break;
                                    }
                                  }
                                }

                                final isSelectable = meetsPhysical && meetsMental && meetsEthical && meetsSubStats;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton(
                                    onPressed: isSelectable ? () => _makeChoice(choice) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelectable ? AppColors.cream : Colors.grey.shade300,
                                      foregroundColor: isSelectable ? AppColors.textDark : Colors.grey.shade600,
                                      alignment: Alignment.centerLeft,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        side: BorderSide(color: isSelectable ? AppColors.tan1 : Colors.transparent),
                                      ),
                                    ),
                                    child: isSelectable 
                                        ? Text(choice.choiceText) 
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(child: Text(choice.choiceText)),
                                              TextButton(
                                                onPressed: () => _requestTaskForChoice(choice),
                                                child: const Text('Get Task', style: TextStyle(color: AppColors.red)),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              }),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(child: Text('— OR —', style: TextStyle(color: Colors.grey, fontSize: 12))),
                              ),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _storyInputController,
                                    decoration: InputDecoration(
                                      hintText: 'Type your own action...',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onSubmitted: (_) => _submitFreeResponse(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.send, color: AppColors.red),
                                  onPressed: _submitFreeResponse,
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

// ─── Stage 1: Wish Entry ─────────────────────────────────────────────────────

class _WishEntryScreen extends StatefulWidget {
  final Function(String) onSubmit;
  const _WishEntryScreen({required this.onSubmit});

  @override
  State<_WishEntryScreen> createState() => _WishEntryScreenState();
}

class _WishEntryScreenState extends State<_WishEntryScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF020A18), Color(0xFF06142B), Color(0xFF0C1F3F)],
              ),
            ),
          ),
          // Moon
          Positioned(
            top: 80,
            right: 60,
            child: Icon(Icons.nightlight_round, color: Colors.white.withOpacity(0.8), size: 80),
          ),
          // Stars (simple layout)
          Positioned(top: 100, left: 50, child: Icon(Icons.star, color: Colors.white.withOpacity(0.5), size: 12)),
          Positioned(top: 150, left: 150, child: Icon(Icons.star, color: Colors.white.withOpacity(0.7), size: 16)),
          Positioned(top: 250, right: 100, child: Icon(Icons.star, color: Colors.white.withOpacity(0.4), size: 10)),
          Positioned(top: 60, right: 200, child: Icon(Icons.star, color: Colors.white.withOpacity(0.6), size: 14)),
          Positioned(bottom: 200, left: 80, child: Icon(Icons.star, color: Colors.white.withOpacity(0.5), size: 15)),
          Positioned(bottom: 100, right: 120, child: Icon(Icons.star, color: Colors.white.withOpacity(0.8), size: 12)),
          
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFF5C842), size: 40),
                  const SizedBox(height: 24),
                  const Text(
                    'What is your honest wish?',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      filled: false,
                      hintText: 'Type your wish here...',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF5C842))),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) widget.onSubmit(val.trim());
                    },
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

// ─── Stage 2: AI Onboarding Chat ────────────────────────────────────────────────

class _AIChatOnboardingScreen extends StatefulWidget {
  final String wishText;
  final Function(List<WishInterviewQA>, AssignedStats) onComplete;

  const _AIChatOnboardingScreen({required this.wishText, required this.onComplete});

  @override
  State<_AIChatOnboardingScreen> createState() => _AIChatOnboardingScreenState();
}

class _AIChatOnboardingScreenState extends State<_AIChatOnboardingScreen> {
  final List<Map<String, dynamic>> _chatHistory = [];
  final List<WishInterviewQA> _qaList = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _questions = [
    "Let's calibrate your Physical stats. What is your weight, BMI, or current fitness level?",
    "Next, your Mental stats. What are your current skills, domains, or areas of study?",
    "Finally, what specific stats or virtues do you require to achieve your wish?",
  ];
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _chatHistory.add({'text': _questions[_currentQuestionIndex], 'isBot': true});
  }

  void _submitAnswer() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;
    _inputController.clear();

    setState(() {
      _chatHistory.add({'text': text, 'isBot': false});
      _qaList.add(WishInterviewQA(question: _questions[_currentQuestionIndex], answer: text));
      _isLoading = true;
    });
    _scrollToBottom();
    
    // Simulate AI processing the response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentQuestionIndex++;
        if (_currentQuestionIndex < _questions.length) {
          _chatHistory.add({'text': _questions[_currentQuestionIndex], 'isBot': true});
        } else {
          // Finish onboarding, generate dynamic stats based on responses
          _generateAndComplete();
        }
      });
      _scrollToBottom();
    });
  }

  void _generateAndComplete() {
    // Basic NLP mock to extract stats from the user's answers
    final physicalAns = _qaList[0].answer.toLowerCase();
    final mentalAns = _qaList[1].answer.toLowerCase();
    final ethicalAns = _qaList[2].answer.toLowerCase();

    Map<String, double> physicalDetails = {};
    if (physicalAns.contains(RegExp(r'\d+'))) {
      // Very basic extraction for mockup: if user entered numbers like "75 kg, bmi 22"
      physicalDetails['Weight'] = 75.0; // Mocked extracted value
      physicalDetails['BMI'] = 22.0;
    } else {
      physicalDetails['Fitness'] = 10.0;
    }

    Map<String, double> mentalDetails = {};
    // Extract words longer than 4 chars as mocked skills
    final words = mentalAns.split(RegExp(r'\s+')).where((w) => w.length > 4).toList();
    for (var w in words.take(2)) {
      mentalDetails[w[0].toUpperCase() + w.substring(1)] = 5.0;
    }
    if (mentalDetails.isEmpty) mentalDetails['Focus'] = 5.0;

    Map<String, double> ethicalDetails = {};
    final reqWords = ethicalAns.split(RegExp(r'\s+')).where((w) => w.length > 4).toList();
    for (var w in reqWords.take(2)) {
      ethicalDetails[w[0].toUpperCase() + w.substring(1)] = 2.0;
    }
    if (ethicalDetails.isEmpty) ethicalDetails['Patience'] = 2.0;

    final stats = AssignedStats(
      physical: 10.0,
      mental: 10.0,
      ethical: 10.0,
      physicalDetails: physicalDetails,
      mentalDetails: mentalDetails,
      ethicalDetails: ethicalDetails,
    );

    widget.onComplete(_qaList, stats);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Uncovering Your Wish'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final bubble = _chatHistory[index];
                final isBot = bubble['isBot'] as bool;
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isBot ? AppColors.white : AppColors.redSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: isBot ? Border.all(color: AppColors.tan1) : null,
                    ),
                    child: Text(
                      bubble['text'],
                      style: TextStyle(color: isBot ? AppColors.textDark : Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Share your thoughts...', 
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (_) => _submitAnswer(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.red),
                  onPressed: _isLoading ? null : _submitAnswer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage 3: Confirmation ───────────────────────────────────────────────────

class _TruthConfirmationScreen extends StatefulWidget {
  final List<WishInterviewQA> qaList;
  final VoidCallback onConfirm;
  const _TruthConfirmationScreen({required this.qaList, required this.onConfirm});

  @override
  State<_TruthConfirmationScreen> createState() => _TruthConfirmationScreenState();
}

class _TruthConfirmationScreenState extends State<_TruthConfirmationScreen> {
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Truth Confirmation'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please review your answers. True growth begins with honesty.',
              style: TextStyle(fontSize: 16, color: AppColors.textMid),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.qaList.length,
                itemBuilder: (context, index) {
                  final qa = widget.qaList[index];
                  return AppCard(
                    color: AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q: ${qa.question}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        Text('A: ${qa.answer}', style: const TextStyle(color: AppColors.textMid, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('I confirm these answers are true to the best of my knowledge.', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _isConfirmed,
              onChanged: (val) => setState(() => _isConfirmed = val ?? false),
              activeColor: AppColors.red,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isConfirmed ? widget.onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Confirm & Set My Path'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stage 4: Stat Assignment ────────────────────────────────────────────────

class _StatAssignmentScreen extends StatelessWidget {
  final AssignedStats stats;
  final VoidCallback onContinue;

  const _StatAssignmentScreen({required this.stats, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, size: 64, color: AppColors.redSoft),
              const SizedBox(height: 24),
              const Text('Your Profile is Ready', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Based on your honest answers, your starting attributes have been calibrated.', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BigStat(label: 'Physical', value: stats.physical),
                  _BigStat(label: 'Mental', value: stats.mental),
                  _BigStat(label: 'Ethical', value: stats.ethical),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Your Specific Attributes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...stats.physicalDetails.entries.map((e) => Chip(
                    label: Text('${e.key}: ${e.value.toInt()}'),
                    backgroundColor: Colors.orange.shade50,
                    side: const BorderSide(color: Colors.orange),
                  )),
                  ...stats.mentalDetails.entries.map((e) => Chip(
                    label: Text('${e.key}: ${e.value.toInt()}'),
                    backgroundColor: Colors.blue.shade50,
                    side: const BorderSide(color: Colors.blue),
                  )),
                  ...stats.ethicalDetails.entries.map((e) => Chip(
                    label: Text('${e.key}: ${e.value.toInt()}'),
                    backgroundColor: AppColors.yellowPale,
                    side: const BorderSide(color: AppColors.red),
                  )),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                child: const Text('Choose Your Path'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final double value;
  const _BigStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toInt().toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        Text(label, style: const TextStyle(color: AppColors.textLight)),
      ],
    );
  }
}

// ─── Stage 5: Path Choice ────────────────────────────────────────────────────

class _PathChoiceScreen extends StatelessWidget {
  final Function(String) onChoice;
  const _PathChoiceScreen({required this.onChoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Select Your Journey'), automaticallyImplyLeading: false, backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Expanded(
              child: _PathCard(
                title: 'Story Mode',
                description: 'Immerse yourself in interactive visual novels. Make choices, write your own responses, and grow your stats through narrative challenges.',
                icon: Icons.menu_book,
                onTap: () => onChoice('story'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _PathCard(
                title: 'Task Mode',
                description: 'Take direct action. Complete real-world tasks, connect with the community as a helper or helpee, and build your virtues practically.',
                icon: Icons.task_alt,
                onTap: () => onChoice('task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _PathCard({required this.title, required this.description, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppCard(
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.redSoft),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMid, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Helper Widgets ────────────────────────────────────────────────

class _ExpandableStatCard extends StatefulWidget {
  final String title;
  final double value;
  final Color color;
  final Map<String, double> details;

  const _ExpandableStatCard({required this.title, required this.value, required this.color, required this.details});

  @override
  State<_ExpandableStatCard> createState() => _ExpandableStatCardState();
}

class _ExpandableStatCardState extends State<_ExpandableStatCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.white,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textMid)),
                    const SizedBox(height: 4),
                    Text('Lvl ${widget.value.toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.color)),
                  ],
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textLight),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 16),
              if (widget.details.isEmpty)
                const Text('No details yet.', style: TextStyle(fontSize: 10, color: AppColors.textLight))
              else
                ...widget.details.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                      Text(e.value.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            ],
          ],
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  final UserVirtue virtue;
  final VoidCallback onTap;

  const _VirtueCard({required this.virtue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        color: AppColors.white,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
              child: const Icon(Icons.star, color: AppColors.yellow),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(virtue.virtueName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: virtue.xpProgress == 0 ? 0.05 : virtue.xpProgress,
                      backgroundColor: AppColors.cream,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Lvl ${virtue.level}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text('${virtue.xp} / ${virtue.xpToNextLevel} XP', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.tan2),
          ],
        ),
      ),
    );
  }
}

// ─── Virtue Detail Screen ────────────────────────────────────────────────────

class VirtueDetailScreen extends ConsumerStatefulWidget {
  final UserVirtue virtue;
  final VoidCallback onBack;

  const VirtueDetailScreen({super.key, required this.virtue, required this.onBack});

  @override
  ConsumerState<VirtueDetailScreen> createState() => _VirtueDetailScreenState();
}

class _VirtueDetailScreenState extends ConsumerState<VirtueDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VirtueTask> _tasks = [];
  List<VirtueChatMessage> _chatMessages = [];
  List<VirtueMaterial> _materials = [];
  final _chatInputController = TextEditingController();
  dynamic _chatSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVirtueData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    try { _chatSub?.cancel(); } catch (_) {}
    try { _chatSub?.unsubscribe(); } catch (_) {}
    super.dispose();
  }

  Future<void> _loadVirtueData() async {
    final repo = ref.read(wishRepositoryProvider);
    final tasks = await repo.getVirtueTasks(widget.virtue.virtueName);
    
    // Seed tasks if empty
    if (tasks.isEmpty) {
      await repo.seedVirtueTasks(widget.virtue.virtueName, [
        VirtueTask(id: '', userId: '', virtueName: widget.virtue.virtueName, taskType: 'individual', title: 'Daily Reflection', description: 'Spend 5 minutes reflecting on how you demonstrated ${widget.virtue.virtueName} today.', xpReward: 10, status: 'pending'),
        VirtueTask(id: '', userId: '', virtueName: widget.virtue.virtueName, taskType: 'social', title: 'Help Someone', description: 'Find a request on the feed related to ${widget.virtue.virtueName} and offer assistance.', xpReward: 30, status: 'pending'),
      ]);
      _tasks = await repo.getVirtueTasks(widget.virtue.virtueName);
    } else {
      _tasks = tasks;
    }

    _chatMessages = await repo.getVirtueChatMessages(widget.virtue.virtueName);
    _materials = await repo.getVirtueMaterials(widget.virtue.virtueName);

    _chatSub = repo.subscribeToVirtueChat(widget.virtue.virtueName, (msg) {
      if (mounted) setState(() => _chatMessages.add(msg));
    });

    if (mounted) setState(() {});
  }

  void _sendChat() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    _chatInputController.clear();
    await ref.read(wishRepositoryProvider).sendVirtueChat(widget.virtue.virtueName, text);
    _chatMessages = await ref.read(wishRepositoryProvider).getVirtueChatMessages(widget.virtue.virtueName);
    setState(() {});
  }

  void _completeTask(VirtueTask task) async {
    await ref.read(wishRepositoryProvider).completeVirtueTask(task.id, widget.virtue.virtueName, task.xpReward);
    // Reload tasks and virtue stats
    await _loadVirtueData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task completed! +${task.xpReward} XP'), backgroundColor: AppColors.redSoft));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(widget.virtue.virtueName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.red,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.red,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Chat Room'),
            Tab(text: 'Materials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tasks Tab
          ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              final isCompleted = task.status == 'completed';
              return AppCard(
                color: AppColors.white,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(task.taskType == 'social' ? Icons.group : Icons.person, color: isCompleted ? Colors.green : AppColors.tan3),
                  title: Text(task.title, style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null)),
                  subtitle: Text(task.description),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => _completeTask(task),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.redSoft),
                          child: const Text('Complete'),
                        ),
                ),
              );
            },
          ),

          // Chat Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${msg.senderName}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            TextSpan(text: msg.message, style: const TextStyle(color: AppColors.textMid)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatInputController,
                        decoration: const InputDecoration(hintText: 'Share your progress...', border: InputBorder.none),
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send, color: AppColors.red), onPressed: _sendChat),
                  ],
                ),
              ),
            ],
          ),

          // Materials Tab
          _materials.isEmpty
              ? const Center(child: Text('No materials posted yet. Be the first!'))
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _materials.length,
                  itemBuilder: (context, index) {
                    final mat = _materials[index];
                    return AppCard(
                      color: AppColors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            mat.materialType == 'book' ? Icons.book : mat.materialType == 'song' ? Icons.music_note : Icons.image,
                            color: AppColors.tan3,
                          ),
                          const SizedBox(height: 8),
                          Text(mat.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          Text('By ${mat.posterName}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: () {
                // Future: Show dialog to post new material
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post material feature coming soon!')));
              },
              backgroundColor: AppColors.red,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
