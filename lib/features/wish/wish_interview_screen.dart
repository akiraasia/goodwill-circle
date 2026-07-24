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
  int _interactionCount = 0;
  final Map<String, dynamic> _interviewData = {};
  
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-1.5-flash',
      systemInstruction: Content.system('''
You are a wise, empathetic guide interviewing someone about their honest wish: "\${widget.initialWish}".
Your goal is to discover their:
- motivation
- obstacles
- fears
- strengths
- weaknesses
- habits
- support
- time
- confidence
- desired future

Rules:
1. Ask ONE thoughtful question at a time.
2. Keep the tone conversational, empathetic, and encouraging.
3. Keep responses relatively concise (2-4 sentences max).
4. Do not list out all the things you are trying to discover.
5. After you have asked enough questions to gauge their physical, mental, and ethical state (usually 4-5 interactions), you MUST conclude by saying EXACTLY: "[INTERVIEW_COMPLETE]". Do not say anything else after that tag.
'''),
    );
    _chat = _model.startChat();
    _startInterview();
  }

  Future<void> _startInterview() async {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': 'My honest wish is: \${widget.initialWish}',
      });
      _interviewData['initial_wish'] = widget.initialWish;
      _isAiTyping = true;
    });

    try {
      final response = await _chat.sendMessage(Content.text('Hello. I am here to understand your wish. Let us begin.'));
      setState(() {
        _isAiTyping = false;
        _messages.add({
          'role': 'ai',
          'text': response.text ?? 'Tell me more about this wish.',
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isAiTyping = false;
        _messages.add({'role': 'ai', 'text': 'How do you feel about this wish?'});
      });
    }
  }

  Future<Map<String, int>> _analyzeWithAI() async {
    try {
      final analysisModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
      );
      
      final prompt = '''
Analyze this wish interview and assign stats (physical, mental, ethical) from 1-10 based on the user's responses.
Also suggest 2-3 virtues from: Courage, Wisdom, Compassion, Discipline, Integrity.

Wish: \${widget.initialWish}
Interview Data: \${_interviewData.toString()}

Return JSON format exactly like this:
{
  "physical": 5,
  "mental": 7, 
  "ethical": 6,
  "virtues": ["Courage", "Discipline"],
  "reasoning": "brief explanation"
}
''';

      final response = await analysisModel.generateContent([Content.text(prompt)]);
      
      final text = response.text ?? '';
      
      int physical = 1;
      int mental = 1;
      int ethical = 1;
      List<String> virtues = [];
      
      try {
        // Very basic manual parsing if JSON decoding fails, but let's try to extract basic patterns
        final RegExp physicalReg = RegExp(r'"physical"\s*:\s*(\d+)');
        final RegExp mentalReg = RegExp(r'"mental"\s*:\s*(\d+)');
        final RegExp ethicalReg = RegExp(r'"ethical"\s*:\s*(\d+)');
        
        if (physicalReg.hasMatch(text)) physical = int.parse(physicalReg.firstMatch(text)!.group(1)!);
        if (mentalReg.hasMatch(text)) mental = int.parse(mentalReg.firstMatch(text)!.group(1)!);
        if (ethicalReg.hasMatch(text)) ethical = int.parse(ethicalReg.firstMatch(text)!.group(1)!);
        
        if (text.contains('Courage')) virtues.add('Courage');
        if (text.contains('Wisdom')) virtues.add('Wisdom');
        if (text.contains('Compassion')) virtues.add('Compassion');
        if (text.contains('Discipline')) virtues.add('Discipline');
        if (text.contains('Integrity')) virtues.add('Integrity');
        
        if (virtues.isEmpty) virtues.add('Courage'); // fallback
      } catch (e) {
        // fallback
      }
      
      final assignedStats = {
        'physical': physical,
        'mental': mental,
        'ethical': ethical,
      };
      
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
      print('AI analysis failed: \$e');
      return _heuristicStatAssignment();
    }
  }

  Map<String, int> _heuristicStatAssignment() {
    int physical = 2;
    int mental = 2;
    int ethical = 2;
    return {'physical': physical, 'mental': mental, 'ethical': ethical};
  }

  void _completeInterview() {
    setState(() {
      _isAiTyping = false;
      _messages.add({
        'role': 'ai',
        'text': 'I understand perfectly. Are you ready to confirm these answers to be true so we can align your path?',
      });
      _isInterviewComplete = true;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userText = _messageController.text.trim();
    _messageController.clear();
    
    setState(() {
      _messages.add({
        'role': 'user',
        'text': userText,
      });
      _interactionCount++;
      _interviewData['interaction_\$_interactionCount'] = userText;
      _isAiTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(userText));
      final aiResponse = response.text ?? '';
      
      if (aiResponse.contains('[INTERVIEW_COMPLETE]')) {
        _completeInterview();
      } else {
        setState(() {
          _isAiTyping = false;
          _messages.add({'role': 'ai', 'text': aiResponse.replaceAll('[INTERVIEW_COMPLETE]', '').trim()});
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isAiTyping = false;
        _messages.add({'role': 'ai', 'text': 'I had trouble hearing that. Could you repeat?'});
      });
      _scrollToBottom();
    }
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
