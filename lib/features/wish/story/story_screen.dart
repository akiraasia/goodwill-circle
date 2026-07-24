import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'story_engine.dart';

class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  late StoryEngine _game;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  final List<Map<String, String>> _dialogueHistory = [];
  bool _isNpcTyping = false;
  
  // Current NPC state
  String _npcName = "The Mentor";
  int _trust = 50;
  String _emotion = "neutral";
  
  @override
  void initState() {
    super.initState();
    _game = StoryEngine();
    
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-1.5-flash',
      systemInstruction: Content.system('''
You are an NPC in a visual novel game called "The Mentor".
The user is a traveler seeking guidance on their wish.
You have internal states:
- Trust (0-100), starts at 50.
- Emotion (happy, sad, angry, surprised, neutral), starts at neutral.

Based on what the user says, update your trust and emotion, and reply in character.
You MUST output your response strictly in the following JSON format:
{
  "dialogue": "Your in-character spoken response",
  "emotion": "happy|sad|angry|surprised|neutral",
  "trust_change": +5 or -5 or 0
}
'''),
    );
    
    _chat = _model.startChat();
    _startConversation();
  }
  
  Future<void> _startConversation() async {
    setState(() => _isNpcTyping = true);
    try {
      final response = await _chat.sendMessage(Content.text("The traveler approaches you. Greet them."));
      _processAiResponse(response.text ?? '{}');
    } catch (e) {
      _addDialogue("System", "Error starting conversation.");
    }
  }

  void _processAiResponse(String jsonString) {
    setState(() => _isNpcTyping = false);
    
    try {
      // Find JSON bounds in case AI adds markdown
      final start = jsonString.indexOf('{');
      final end = jsonString.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final cleanJson = jsonString.substring(start, end + 1);
        final data = jsonDecode(cleanJson);
        
        final dialogue = data['dialogue'] ?? '...';
        final emotion = data['emotion'] ?? 'neutral';
        final trustChange = data['trust_change'] ?? 0;
        
        setState(() {
          _emotion = emotion;
          _trust = (_trust + (trustChange as num).toInt()).clamp(0, 100);
          _game.updateScene(newEmotion: _emotion);
        });
        
        _addDialogue(_npcName, dialogue);
      } else {
        _addDialogue(_npcName, jsonString); // fallback
      }
    } catch (e) {
      _addDialogue(_npcName, "I don't know what to say.");
    }
  }

  void _addDialogue(String speaker, String text) {
    setState(() {
      _dialogueHistory.add({'speaker': speaker, 'text': text});
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

  Future<void> _submitInput() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    _inputController.clear();
    _addDialogue("You", text);
    
    setState(() => _isNpcTyping = true);
    
    try {
      final response = await _chat.sendMessage(Content.text(text));
      _processAiResponse(response.text ?? '{}');
    } catch (e) {
      setState(() => _isNpcTyping = false);
      _addDialogue("System", "Failed to get response.");
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Flame Game Background/Layer
          Positioned.fill(
            child: GameWidget(game: _game),
          ),
          
          // HUD - Top stats
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Trust: $_trust | Emotion: $_emotion',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // 2. Visual Novel Overlay (Dialogue box at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _dialogueHistory.length + (_isNpcTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _dialogueHistory.length && _isNpcTyping) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('...', style: TextStyle(color: Colors.white70, fontSize: 24)),
                          );
                        }
                        
                        final msg = _dialogueHistory[index];
                        final isPlayer = msg['speaker'] == 'You';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '\${msg['speaker']}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPlayer ? Colors.blue[300] : Colors.amber,
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: msg['text'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Input field
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'What will you say?',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (_) => _submitInput(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.black),
                            onPressed: _submitInput,
                          ),
                        ),
                      ],
                    ),
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
