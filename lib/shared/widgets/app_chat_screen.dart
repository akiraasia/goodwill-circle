import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

/// Global Goodwill Circle navigation & app-understanding chatbot.
/// Helps users understand how the platform works and navigate features.
/// Powered by Firebase AI Logic (Gemini Developer API).
class AppChatScreen extends StatefulWidget {
  const AppChatScreen({super.key});

  @override
  State<AppChatScreen> createState() => _AppChatScreenState();
}

class _AppChatScreenState extends State<AppChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  ChatSession? _chatSession;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  static const _systemInstruction = '''
You are "Goodwill", the friendly AI guide for the Goodwill Circle community app.

Goodwill Circle is a platform where people connect to give and receive help through "Goodwill Loops". Here's what you know about the app:

CORE CONCEPTS:
- Help Requests: People post requests for help in categories like Education, Career, Medical, Finance, Housing, Emotional Support
- Goodwill Credits: Virtual credits earned by helping others. Urgent requests offer 25 credits, normal = 10, low = 5. Credits are transferred from helpee to helper upon completion.
- Helpers & Helpees: Helpers are people who offer assistance. Helpees are people who need help.
- Community Requests: Broader requests open to many participants, with role-based joining (helper or helpee)
- Connection Hub: A shared space where matched helpers and helpees can view each other's contact info and coordinate

KEY FEATURES:
- Feed / Requests Screen: Main feed showing all open help requests. Users can filter by category.
- New Request button (+): Create a new help request with title, description, category (Education/Career/Medical/Finance etc.), urgency level, and optional photo.
- Join/Help button: Click to volunteer as a helper for a request. Choose individual or group joining.
- Complete button: Helpers click this when done to trigger a completion review. Credits transfer after helpee confirms.
- Support (heart): Like/upvote a request to show solidarity without joining.
- Agenda tab: NGO-posted volunteering opportunities with certificates/badges as rewards.
- Profile tab: View your earned goodwill credits, badges, verification status.
- Trust/Verification: Users can verify their identity for financial help requests.

HOW TO HELP SOMEONE:
1. Browse the feed and find a request that matches your skills
2. Tap "Join/Help" and select your role (helper/helpee) and type (individual/group)
3. Connect through the Connection Hub with the other person
4. When done, tap "Complete" and write a message to the helpee
5. Helpee confirms, credits are transferred to you

HOW TO ASK FOR HELP:
1. Tap the "+" New Request button
2. Fill in the title, describe your situation honestly
3. Choose a category and urgency level
4. Post your request — the community will see it

Be friendly, warm, concise, and actionable. If you do not know something specific about the app, say so honestly. Do not make up user data or specific names.
''';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-flash-latest',
        systemInstruction: Content.system(_systemInstruction),
      );

      _chatSession = model.startChat();

      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                'Hi! I\'m **Goodwill** 👋\n\n'
                'I can help you understand and navigate the Goodwill Circle app — '
                'how credits work, how to post or join a help request, '
                'or anything else about the platform.\n\n'
                'What would you like to know?',
            isUser: false,
          ),
        );
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _initialized = true;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _chatSession == null) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final stream = _chatSession!.sendMessageStream(Content.text(text));
      final buffer = StringBuffer();

      setState(() {
        _messages.add(
          const _ChatMessage(text: '', isUser: false, isStreaming: true),
        );
      });

      await for (final chunk in stream) {
        buffer.write(chunk.text ?? '');
        setState(() {
          _messages.last = _ChatMessage(
            text: buffer.toString(),
            isUser: false,
            isStreaming: true,
          );
        });
        _scrollToBottom();
      }

      setState(() {
        _messages.last = _ChatMessage(
          text: buffer.toString(),
          isUser: false,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'Something went wrong. Please try again.',
            isUser: false,
            isError: true,
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Quick-prompt chips to get users started
  static const _quickPrompts = [
    'How do credits work?',
    'How do I ask for help?',
    'How do I help someone?',
    'What is the Connection Hub?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Goodwill Guide'),
          ],
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.tan1),
        ),
      ),
      body: Column(
        children: [
          // Quick-prompt chips (show only when chat is at the beginning)
          if (_messages.length <= 1 && _initialized)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPrompts.map((prompt) {
                  return InkWell(
                    onTap: () {
                      _controller.text = prompt;
                      _sendMessage();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.yellowPale,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.tan2),
                      ),
                      child: Text(
                        prompt,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.tan3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Chat messages
          Expanded(
            child: !_initialized
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not start AI assistant.\n$_error',
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: _messages[index]),
                  ),
          ),

          // Input
          _ChatInput(
            controller: _controller,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : message.isError
              ? Colors.red.shade50
              : AppColors.tan1,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
        ),
        child: message.text.isEmpty && message.isStreaming
            ? _TypingIndicator()
            : Text(
                message.text,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : message.isError
                      ? Colors.red.shade700
                      : AppColors.textDark,
                  height: 1.45,
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.tan3,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chat Input ───────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.tan1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about the app...',
                  hintStyle: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.tan2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.tan2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            isLoading
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: Icon(
                      Icons.send_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Send',
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.isError = false,
  });
}
