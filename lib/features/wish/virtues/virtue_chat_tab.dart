import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'virtue_models.dart';
import 'virtue_hub_repository.dart';

class VirtueChatTab extends StatefulWidget {
  final String virtue;
  final Color accentColor;

  const VirtueChatTab({
    Key? key,
    required this.virtue,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<VirtueChatTab> createState() => _VirtueChatTabState();
}

class _VirtueChatTabState extends State<VirtueChatTab> {
  late final VirtueHubRepository _repo;
  late RealtimeChannel _channel;

  final List<VirtueChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  String get _myName =>
      Supabase.instance.client.auth.currentUser?.userMetadata?['name']
          as String? ??
      'You';

  @override
  void initState() {
    super.initState();
    _repo = VirtueHubRepository(Supabase.instance.client);
    _loadMessages();
    _channel = _repo.subscribeToChatRoom(
      virtueName: widget.virtue,
      onMessage: (msg) {
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      },
    );
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await _repo.getChatMessages(widget.virtue);
    if (mounted) {
      setState(() {
        _messages.addAll(msgs);
        _isLoading = false;
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await _repo.sendMessage(
      virtueName: widget.virtue,
      message: text,
      senderName: _myName,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.red));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.redPale,
          child: Row(
            children: [
              const Icon(Icons.people, color: AppColors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                '${widget.virtue} Community Room',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'Be the first to speak in the ${widget.virtue} room!',
                    style: const TextStyle(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = _messages[i];
                    final isMe = msg.senderName == _myName;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.redPale,
                              child: Text(
                                _initials(msg.senderName),
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                                    child: Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        color: AppColors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.red : AppColors.white,
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isMe
                                          ? const Radius.circular(4)
                                          : const Radius.circular(16),
                                      bottomLeft: isMe
                                          ? const Radius.circular(16)
                                          : const Radius.circular(4),
                                    ),
                                    border: Border.all(
                                      color: isMe ? AppColors.red : AppColors.tan1,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    msg.message,
                                    style: TextStyle(
                                      color: isMe ? AppColors.white : AppColors.textDark,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: AppColors.cream,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Share your ${widget.virtue} journey...',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.tan1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.red,
                  child: Icon(Icons.send, color: AppColors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
