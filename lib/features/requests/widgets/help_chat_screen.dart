import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';

/// Per-request AI chatbot grounded on a specific help request's context.
/// Uses Firebase AI Logic (Gemini Developer API) with gemini-flash-latest.
class HelpChatScreen extends StatefulWidget {
  final HelpRequest request;

  const HelpChatScreen({super.key, required this.request});

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  ChatSession? _chatSession;
  bool _isLoading = false;
  bool _initialized = false;
  bool _isMock = false;
  String? _error;

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

  String _buildSystemContext() {
    final req = widget.request;
    final tags =
        req.tags.isNotEmpty ? req.tags.join(', ') : 'none specified';
    final difficulty = req.difficulty ?? 'not specified';
    final benefit = req.estimatedPeopleWhoMayBenefit ?? 'unknown';

    return '''You are a helpful assistant for the Goodwill Circle community platform.
A community member posted a help request with these details:

Title: ${req.title}
Category: ${req.category}
Description: ${req.description}
Tags: $tags
Difficulty: $difficulty
Estimated people who may benefit: $benefit

Your job is to:
1. Answer questions about this specific help request
2. Give practical, actionable advice on how someone can assist with this need
3. Suggest resources, approaches, or steps relevant to this type of help
4. Explain how the Goodwill Circle platform works (credits, joining as helper/helpee, Connection Hub)

Keep answers concise, warm, and actionable. Do not make up specific contact information.''';
  }

  Future<void> _initChat() async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-flash-latest',
        systemInstruction: Content.system(_buildSystemContext()),
      );

      _chatSession = model.startChat();
    } catch (e) {
      _isMock = true; // Fallback to a mock chat if Firebase is not configured
      _error = e.toString();
      print('Firebase AI Init Error: $e');
    }

    // Greet the user
    setState(() {
      _messages.add(
        _ChatMessage(
          text:
              'Hi! I\'m your assistant for this help request: **"${widget.request.title}"**. '
              'Ask me anything about this need, how to help, or how Goodwill Circle works.',
          isUser: false,
        ),
      );
      _initialized = true;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || (_chatSession == null && !_isMock)) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    if (_isMock) {
      setState(() {
        _messages.add(const _ChatMessage(text: '', isUser: false, isStreaming: true));
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {
        _messages.last = _ChatMessage(
          text: 'I am a preview AI assistant. To use the real Gemini AI features, please configure Firebase with a valid google-services.json or GoogleService-Info.plist for this project.\n\nError details: $_error',
          isUser: false,
          isStreaming: false,
        );
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final stream = _chatSession!.sendMessageStream(Content.text(text));
      final buffer = StringBuffer();

      // Add placeholder for streaming response
      setState(() {
        _messages.add(_ChatMessage(text: '', isUser: false, isStreaming: true));
      });

      await for (final chunk in stream) {
        final chunkText = chunk.text ?? '';
        buffer.write(chunkText);
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
          isStreaming: false,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'Sorry, I ran into an error. Please try again.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('AI Assistant'),
              ],
            ),
            Text(
              widget.request.title,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
          // Context banner
          _ContextBanner(request: widget.request),

          // Chat messages
          Expanded(
            child: !_initialized
                ? const Center(child: CircularProgressIndicator())
                : _error != null && !_isMock
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
                            'Could not start AI chat.\n$_error',
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

          // Input row
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

// ─── Context Banner ───────────────────────────────────────────────────────────

class _ContextBanner extends StatelessWidget {
  final HelpRequest request;

  const _ContextBanner({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.yellowPale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppColors.tan3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Chatting about: ${request.category} · ${request.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.tan3,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
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
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.tan3,
              shape: BoxShape.circle,
            ),
          );
        }),
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
                  hintText: 'Ask about this help request...',
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: isLoading
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
