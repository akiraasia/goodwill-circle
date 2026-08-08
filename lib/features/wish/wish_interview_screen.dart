import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/shared/widgets/mascot_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'path_selection_screen.dart';
import 'wish_history_repository.dart';
import '../growth_os/data/wish_repository.dart';

class WishInterviewScreen extends ConsumerStatefulWidget {
  final String initialWish;

  const WishInterviewScreen({Key? key, required this.initialWish}) : super(key: key);

  @override
  ConsumerState<WishInterviewScreen> createState() => _WishInterviewScreenState();
}

class _WishInterviewScreenState extends ConsumerState<WishInterviewScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;
  bool _isInterviewComplete = false;
  int _interactionCount = 0;
  final Map<String, dynamic> _interviewData = {};

  GenerativeModel? _model;
  ChatSession? _chat;

  static const List<String> _fallbackQuestions = [
    "That is a deeply meaningful wish. What is your primary motivation behind wanting to achieve this?",
    "What obstacle or fear has held you back from accomplishing this wish in the past?",
    "Which of your personal strengths or values will help you most on this journey?",
    "What daily habit or small step can you take starting today to build momentum?",
    "How will achieving this wish allow you to contribute to others and pass goodwill forward?",
  ];

  @override
  void initState() {
    super.initState();
    try {
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        systemInstruction: Content.system('''
You are a wise, empathetic guide interviewing someone about their honest wish: "${widget.initialWish}".
Your goal is to discover their motivation, obstacles, strengths, habits, and desired future.

Rules:
1. Ask ONE thoughtful question at a time.
2. Keep responses concise (2-3 sentences max).
3. After 4-5 interactions, end with EXACTLY: "[INTERVIEW_COMPLETE]".
'''),
      );
      _chat = _model?.startChat();
    } catch (e) {
      debugPrint('FirebaseAI initialization error: $e');
    }
    _startInterview();
  }

  Future<void> _startInterview() async {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': 'My wish is: ${widget.initialWish}',
      });
      _interviewData['initial_wish'] = widget.initialWish;
      _isAiTyping = true;
    });

    String? aiText;
    if (_chat != null) {
      try {
        final response = await _chat!.sendMessage(
          Content.text('Hello. I am here to understand your wish. Let us begin.'),
        );
        aiText = response.text;
      } catch (e) {
        debugPrint('AI start interview error: $e');
      }
    }

    final firstQuestion = (aiText != null && aiText.trim().isNotEmpty)
        ? aiText.replaceAll('[INTERVIEW_COMPLETE]', '').trim()
        : _fallbackQuestions[0];

    setState(() {
      _isAiTyping = false;
      _messages.add({
        'role': 'ai',
        'text': firstQuestion,
      });
    });
    _scrollToBottom();
  }

  Future<Map<String, int>> _analyzeWithAI() async {
    int physical = 5;
    int mental = 5;
    int ethical = 5;
    List<String> virtues = ['Courage', 'Discipline'];

    if (_model != null) {
      try {
        final prompt = '''
Analyze this wish interview and suggest 2-3 supporting values from: Courage, Wisdom, Compassion, Discipline, Integrity.

Wish: ${widget.initialWish}
Interview Data: ${_interviewData.toString()}

Return JSON format exactly like this:
{
  "physical": 5,
  "mental": 7, 
  "ethical": 6,
  "virtues": ["Courage", "Discipline"]
}
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';

        virtues.clear();
        if (text.contains('Courage')) virtues.add('Courage');
        if (text.contains('Wisdom')) virtues.add('Wisdom');
        if (text.contains('Compassion')) virtues.add('Compassion');
        if (text.contains('Discipline')) virtues.add('Discipline');
        if (text.contains('Integrity')) virtues.add('Integrity');
        if (virtues.isEmpty) virtues.add('Courage');
      } catch (e) {
        debugPrint('AI analysis error: $e');
      }
    }

    final assignedStats = {
      'physical': physical,
      'mental': mental,
      'ethical': ethical,
    };

    try {
      final repo = ref.read(wishHistoryRepositoryProvider);
      await repo.createWish(
        initialWish: widget.initialWish,
        interviewData: _interviewData,
        assignedVirtues: virtues,
        assignedStats: assignedStats,
        pathMode: 'task',
      );
    } catch (e) {
      debugPrint('wishHistoryRepository createWish error: $e');
    }

    return assignedStats;
  }

  void _completeInterview() {
    setState(() {
      _isAiTyping = false;
      _isInterviewComplete = true;
      _messages.add({
        'role': 'ai',
        'text': 'Your wish has been heard. 🌱 Whenever you are ready, let us begin your journey.',
      });
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isAiTyping || _isInterviewComplete) return;

    final userText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'text': userText,
      });
      _interactionCount++;
      _interviewData['interaction_$_interactionCount'] = userText;
      _isAiTyping = true;
    });
    _scrollToBottom();

    if (_interactionCount >= 5) {
      _completeInterview();
      return;
    }

    String? aiResponseText;
    if (_chat != null) {
      try {
        final response = await _chat!.sendMessage(Content.text(userText));
        aiResponseText = response.text;
      } catch (e) {
        debugPrint('AI sendMessage error: $e');
      }
    }

    if (aiResponseText != null && aiResponseText.contains('[INTERVIEW_COMPLETE]')) {
      _completeInterview();
      return;
    }

    final nextText = (aiResponseText != null && aiResponseText.trim().isNotEmpty)
        ? aiResponseText.replaceAll('[INTERVIEW_COMPLETE]', '').trim()
        : (_interactionCount < _fallbackQuestions.length
            ? _fallbackQuestions[_interactionCount]
            : 'Thank you for sharing your thoughts.');

    setState(() {
      _isAiTyping = false;
      _messages.add({'role': 'ai', 'text': nextText});
    });
    _scrollToBottom();
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

  Future<void> _confirmAndProceed() async {
    setState(() => _isAiTyping = true);

    final assignedStats = await _analyzeWithAI();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_wish', true);
    await prefs.setBool('has_visited_wish_module', true);

    final wishRepo = ref.read(wishRepositoryProvider);
    await wishRepo.createUserWish(
      wishStatement: widget.initialWish,
      physicalCondition: 'Calibrated from wish conversation',
      mentalCondition: 'Calibrated from wish conversation',
      interviewData: _interviewData.entries
          .map((e) => WishInterviewQA(question: e.key, answer: e.value.toString()))
          .toList(),
      assignedStats: AssignedStats(
        physical: (assignedStats['physical'] ?? 5).toDouble(),
        mental: (assignedStats['mental'] ?? 5).toDouble(),
        ethical: (assignedStats['ethical'] ?? 5).toDouble(),
        physicalDetails: {'Energy': (assignedStats['physical'] ?? 5).toDouble()},
        mentalDetails: {'Focus': (assignedStats['mental'] ?? 5).toDouble()},
        ethicalDetails: {'Goodwill': (assignedStats['ethical'] ?? 5).toDouble()},
      ),
    );

    if (mounted) {
      setState(() => _isAiTyping = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PathSelectionScreen(assignedStats: assignedStats),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Visual dots indicator instead of "1/5", "2/5"
  Widget _buildProgressIndicator() {
    final count = _interactionCount.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < count;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.red : AppColors.tan1,
          ),
        );
      }),
    );
  }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wish Conversation',
              style: TextStyle(
                color: AppColors.red,
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _buildProgressIndicator(),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isAiTyping) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            MascotWidget(height: 36, state: MascotState.listening),
                            SizedBox(width: 8),
                            Text(
                              '...',
                              style: TextStyle(color: AppColors.textLight, fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.red : AppColors.white,
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                          bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                        ),
                        border: Border.all(
                          color: isUser ? AppColors.red : AppColors.tan1,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          color: isUser ? AppColors.white : AppColors.textDark,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isInterviewComplete)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton.icon(
                  onPressed: _isAiTyping ? null : _confirmAndProceed,
                  icon: const Icon(Icons.check, color: AppColors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  label: _isAiTyping
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text(
                          "I'm ready",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  border: Border(top: BorderSide(color: AppColors.tan1, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppColors.textDark, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Share your response...',
                          hintStyle: TextStyle(color: AppColors.textLight),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(color: AppColors.tan1, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(color: AppColors.tan1, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(color: AppColors.redSoft, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.red,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: AppColors.white, size: 18),
                        onPressed: _sendMessage,
                      ),
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
