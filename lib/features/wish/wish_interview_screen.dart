import 'package:flutter/material.dart';

class WishInterviewScreen extends StatefulWidget {
  final String initialWish;

  const WishInterviewScreen({Key? key, required this.initialWish}) : super(key: key);

  @override
  _WishInterviewScreenState createState() => _WishInterviewScreenState();
}

class _WishInterviewScreenState extends State<WishInterviewScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;
  bool _isInterviewComplete = false;

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
      _isAiTyping = true;
    });

    // Simulate AI response based on the initial wish
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add({
            'role': 'ai',
            'text': 'That is a beautiful wish. To help you achieve this, I need to understand your current path. What virtues do you think are most needed for your wish?',
          });
        });
        _scrollToBottom();
      }
    });
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
      _isAiTyping = true;
    });
    _scrollToBottom();

    // Simulate AI processing the response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          // In a real implementation, this would call the HGOS Semantic Engine
          // For now, we simulate reaching the end of the interview after a few exchanges
          if (_messages.length >= 5) {
            _messages.add({
              'role': 'ai',
              'text': 'I understand. Are you ready to confirm these answers to be true so we can align your path?',
            });
            _isInterviewComplete = true;
          } else {
            _messages.add({
              'role': 'ai',
              'text': 'I see. How do you feel about connecting with others to build this virtue, versus working on it individually?',
            });
          }
        });
        _scrollToBottom();
      }
    });
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

  void _confirmAndProceed() {
    // TODO: Send data to backend to assign stats (Physical, Mental, Ethical) and Virtues
    // TODO: Navigate to Path Selection Screen
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
                      color: isUser ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
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
                onPressed: _confirmAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('I Confirm These Answers Are True', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
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
