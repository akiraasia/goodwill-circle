import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'path_selection_screen.dart';
import 'wish_history_repository.dart';

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
  final List<String> _interviewQuestions = [
    'What virtues do you think are most needed for your wish?',
    'How do you feel about connecting with others to build this virtue, versus working on it individually?',
    'What challenges might you face on this journey?',
    'How committed are you to this path?',
  ];
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _interviewData = {};

  @override
  void initState() {
    super.initState();
    _startInterview();
  }

  void _startInterview() {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': widget.initialWish,
      });
      _interviewData['initial_wish'] = widget.initialWish;
      _isAiTyping = true;
    });

    _askNextQuestion();
  }

  void _askNextQuestion() {
    if (_currentQuestionIndex >= _interviewQuestions.length) {
      _completeInterview();
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add({
            'role': 'ai',
            'text': _interviewQuestions[_currentQuestionIndex],
          });
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _analyzeWithAI() async {
    try {
      final aiLogic = FirebaseAI.instance;
      
      final prompt = '''
Analyze this wish interview and assign stats (physical, mental, ethical) from 1-5 based on the user's responses.
Also suggest 2-3 virtues from: Courage, Wisdom, Compassion, Discipline, Integrity.

Wish: ${widget.initialWish}
Interview Data: ${_interviewData.toString()}

Return JSON format:
{
  "physical": 1-5,
  "mental": 1-5, 
  "ethical": 1-5,
  "virtues": ["virtue1", "virtue2"],
  "reasoning": "brief explanation"
}
''';

      final response = await aiLogic.generateText(prompt);
      
      // Parse the AI response to extract stats
      // For now, use a simple heuristic based on interview content
      final assignedStats = _heuristicStatAssignment();
      
      final virtues = _extractVirtuesFromInterview();
      
      // Save to wish history
      final repo = ref.read(wishHistoryRepositoryProvider);
      await repo.createWish(
        initialWish: widget.initialWish,
        interviewData: _interviewData,
        assignedVirtues: virtues,
        assignedStats: assignedStats,
        pathMode: 'task',
      );
      
      return assignedStats;
    } catch (e) {
      print('AI analysis failed: $e');
      // Fallback to heuristic assignment
      return _heuristicStatAssignment();
    }
  }

  Map<String, int> _heuristicStatAssignment() {
    int physical = 1;
    int mental = 1;
    int ethical = 1;

    final text = _interviewData.values.join(' ').toLowerCase();
    
    // Simple keyword-based stat assignment
    if (text.contains('fit') || text.contains('health') || text.contains('body') || text.contains('exercise')) {
      physical = 3;
    }
    if (text.contains('learn') || text.contains('study') || text.contains('knowledge') || text.contains('wisdom')) {
      mental = 3;
    }
    if (text.contains('help') || text.contains('kind') || text.contains('ethical') || text.contains('moral')) {
      ethical = 3;
    }
    
    // Boost based on wish content
    final wish = widget.initialWish.toLowerCase();
    if (wish.contains('anxiety') || wish.contains('fear')) {
      physical = 2; // Courage relates to physical action
      mental = 3;
    }
    if (wish.contains('learn') || wish.contains('skill') || wish.contains('knowledge')) {
      mental = 4;
    }
    if (wish.contains('relationship') || wish.contains('friend') || wish.contains('connect')) {
      ethical = 3;
      mental = 2;
    }

    return {'physical': physical, 'mental': mental, 'ethical': ethical};
  }

  List<String> _extractVirtuesFromInterview() {
    final virtues = <String>[];
    final text = _interviewData.values.join(' ').toLowerCase() + ' ' + widget.initialWish.toLowerCase();
    
    if (text.contains('courage') || text.contains('fear') || text.contains('brave')) {
      virtues.add('Courage');
    }
    if (text.contains('wisdom') || text.contains('learn') || text.contains('knowledge')) {
      virtues.add('Wisdom');
    }
    if (text.contains('compassion') || text.contains('help') || text.contains('kind')) {
      virtues.add('Compassion');
    }
    if (text.contains('discipline') || text.contains('habit') || text.contains('consistent')) {
      virtues.add('Discipline');
    }
    if (text.contains('integrity') || text.contains('honest') || text.contains('truth')) {
      virtues.add('Integrity');
    }
    
    // Default to Courage if no virtues matched
    if (virtues.isEmpty) {
      virtues.add('Courage');
    }
    
    return virtues;
  }

  void _completeInterview() {
    setState(() {
      _isAiTyping = false;
      _messages.add({
        'role': 'ai',
        'text': 'I understand. Are you ready to confirm these answers to be true so we can align your path?',
      });
      _isInterviewComplete = true;
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userText = _messageController.text.trim();
    _messageController.clear();
    
    setState(() {
      _messages.add({
        'role': 'user',
        'text': userText,
      });
      _interviewData['question_${_currentQuestionIndex}'] = userText;
      _isAiTyping = true;
    });
    _scrollToBottom();

    _currentQuestionIndex++;
    _askNextQuestion();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('The Wishing Module'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isAiTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('...', style: TextStyle(color: Colors.white70, fontSize: 24)),
                    ),
                  );
                }
                
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isInterviewComplete)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isAiTyping ? null : _confirmAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isAiTyping
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('I Confirm These Answers Are True', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Your answer...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
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
