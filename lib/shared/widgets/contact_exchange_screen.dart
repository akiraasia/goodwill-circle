import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/features/agenda/agenda_repository.dart';
import 'package:goodwill_circle/features/campaigns/campaign_repository.dart';
import 'package:goodwill_circle/features/requests/request_controller.dart';
import 'package:goodwill_circle/features/requests/request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactExchangeScreen extends ConsumerStatefulWidget {
  final String entityId;
  final String entityType;
  final String myRole;
  final String title;

  const ContactExchangeScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.myRole,
    required this.title,
  });

  @override
  ConsumerState<ContactExchangeScreen> createState() =>
      _ContactExchangeScreenState();
}

class _ContactExchangeScreenState extends ConsumerState<ContactExchangeScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _contacts = [];
  RealtimeChannel? _channel;
  Timer? _refreshDebounce;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _subscribeToHub();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final channel = _channel;
    if (channel != null) {
      _supabase.removeChannel(channel);
    }
    super.dispose();
  }

  void _subscribeToHub() {
    final channel = _supabase.channel(
      'connection-hub:${widget.entityType}:${widget.entityId}',
    );

    if (widget.entityType == 'request') {
      _listenToTable(channel, 'request_volunteers', 'request_id');
      _listenToTable(channel, 'community_starter_request_joins', 'request_id');
      _listenToTable(channel, 'help_request_posts', 'request_id');
    } else if (widget.entityType == 'campaign') {
      _listenToTable(channel, 'campaign_members', 'campaign_id');
    } else if (widget.entityType == 'agenda') {
      _listenToTable(channel, 'agenda_participants', 'agenda_item_id');
    }

    _channel = channel.subscribe();
  }

  void _listenToTable(RealtimeChannel channel, String table, String idColumn) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: idColumn,
        value: widget.entityId,
      ),
      callback: (_) => _scheduleRefresh(),
    );
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (widget.entityType == 'request') {
        ref.invalidate(requestPostsProvider(widget.entityId));
      }
      _fetchContacts(showLoading: false);
    });
  }

  Future<void> _fetchContacts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      List<Map<String, dynamic>> contacts = [];
      if (widget.entityType == 'request') {
        contacts = await ref
            .read(requestRepositoryProvider)
            .fetchContacts(widget.entityId, widget.myRole);
      } else if (widget.entityType == 'campaign') {
        contacts = await ref
            .read(campaignRepositoryProvider)
            .fetchContacts(widget.entityId, widget.myRole);
      } else if (widget.entityType == 'agenda') {
        contacts = await ref
            .read(agendaRepositoryProvider)
            .fetchContacts(widget.entityId, widget.myRole);
      }

      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmHelpCompletion(String participantId, bool liked) async {
    try {
      if (widget.entityType == 'request') {
        await _supabase.rpc(
          'confirm_and_like_helper',
          params: {
            'p_request_id': widget.entityId,
            'p_helper_id': participantId,
            'p_liked': liked,
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help completion confirmed.')),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(liked ? 'Confirmed and liked!' : 'Confirmed successfully!')),
      );
      _fetchContacts(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleDoneWithRequest() async {
    try {
      if (widget.entityType == 'request') {
        await ref
            .read(requestRepositoryProvider)
            .requestCompletionReview(
              requestId: widget.entityId,
              message: 'Helper completed request.',
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completion requested successfully.')),
        );
        _fetchContacts(showLoading: false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpers = _contacts
        .where((contact) => _roleFor(contact, widget.myRole) == 'helper')
        .toList();
    final helpies = _contacts
        .where((contact) => _roleFor(contact, widget.myRole) == 'helpee')
        .toList();

    final currentUserId = _supabase.auth.currentUser?.id;
    final myContact = _contacts.firstWhere(
      (contact) => contact['participant_id'] == currentUserId,
      orElse: () => <String, dynamic>{},
    );
    final myStatus = myContact['status'] as String? ?? 'accepted';
    final isDoneRequested = myStatus == 'completion_requested' || myStatus == 'completed';

    return Scaffold(
      backgroundColor: AppColors.cream,
      bottomNavigationBar: widget.myRole == 'helper' && widget.entityType == 'request'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ElevatedButton.icon(
                  onPressed: isDoneRequested
                      ? null
                      : _handleDoneWithRequest,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(isDoneRequested ? 'Completion Requested' : 'Done with Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDoneRequested ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.cream,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _fetchContacts(showLoading: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchContacts(showLoading: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120,
                ),
                children: [
                  _HubHeader(
                    helpersCount: helpers.length,
                    helpiesCount: helpies.length,
                  ),
                  if (widget.entityType == 'request') ...[
                    const SizedBox(height: AppSpacing.md),
                    _HubActivityFeed(requestId: widget.entityId),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final sections = [
                        _ParticipantSection(
                          title: 'Helpers',
                          emptyText: 'No helpers have joined yet.',
                          role: 'helper',
                          contacts: helpers,
                          onConfirmHelp: widget.myRole == 'helpee'
                              ? _confirmHelpCompletion
                              : null,
                        ),
                        _ParticipantSection(
                          title: 'Helpies',
                          emptyText: 'No helpies have joined yet.',
                          role: 'helpee',
                          contacts: helpies,
                        ),
                      ];

                      if (!isWide) {
                        return Column(
                          children: [
                            sections.first,
                            const SizedBox(height: AppSpacing.md),
                            sections.last,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: sections.first),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: sections.last),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  final int helpersCount;
  final int helpiesCount;

  const _HubHeader({required this.helpersCount, required this.helpiesCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.yellowPale,
            child: Icon(Icons.groups_2_outlined, color: AppColors.tan3),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Hub',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CountPill(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'Helpers',
                      count: helpersCount,
                      color: _roleColor('helper'),
                    ),
                    _CountPill(
                      icon: Icons.person_search_outlined,
                      label: 'Helpies',
                      count: helpiesCount,
                      color: _roleColor('helpee'),
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

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _CountPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final String role;
  final List<Map<String, dynamic>> contacts;
  final Future<void> Function(String participantId, bool liked)? onConfirmHelp;

  const _ParticipantSection({
    required this.title,
    required this.emptyText,
    required this.role,
    required this.contacts,
    this.onConfirmHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_roleIcon(role), size: 18, color: _roleColor(role)),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                emptyText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
              ),
            )
          else
            ...contacts.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == contacts.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: _ParticipantTile(
                  number: entry.key + 1,
                  role: role,
                  contact: entry.value,
                  onConfirmHelp: onConfirmHelp,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final int number;
  final String role;
  final Map<String, dynamic> contact;
  final Future<void> Function(String participantId, bool liked)? onConfirmHelp;

  const _ParticipantTile({
    required this.number,
    required this.role,
    required this.contact,
    this.onConfirmHelp,
  });

  @override
  Widget build(BuildContext context) {
    final name = (contact['name'] as String?)?.trim().isNotEmpty == true
        ? contact['name'] as String
        : 'Unknown';
    final email = (contact['email'] as String?)?.trim() ?? '';
    final phone = (contact['phone'] as String?)?.trim() ?? '';
    final contactLine = phone.isNotEmpty
        ? phone
        : email.isNotEmpty
        ? email
        : 'No contact shared';
    final status = contact['status'] as String? ?? 'accepted';
    final joinType = contact['join_type'] as String? ?? 'individual';
    final participantId = contact['participant_id'] as String?;
    final isConfirmed = contact['is_confirmed'] as bool? ?? false;
    final isLiked = contact['is_liked'] as bool? ?? false;
    final isCompletionRequested = status == 'completion_requested';
    final isAccepted = status == 'accepted';
    final isCompleted = status == 'completed';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.06),
        border: Border.all(color: _roleColor(role).withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _roleColor(role).withValues(alpha: 0.12),
                child: Icon(_roleIcon(role), color: _roleColor(role), size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_roleLabel(role)} $number: $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Contact: $contactLine',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy contact',
                onPressed: contactLine == 'No contact shared'
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: contactLine));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied contact details.'),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniPill(label: status),
              _MiniPill(label: joinType == 'multiple' ? 'Group' : 'Individual'),
              if (onConfirmHelp != null && participantId != null && (isCompletionRequested || isConfirmed || isAccepted || isCompleted)) ...[
                if (isConfirmed)
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check, size: 16, color: Colors.green),
                    label: const Text('Confirmed'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => onConfirmHelp!(participantId, isLiked),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                IconButton(
                  tooltip: 'Like Helper',
                  onPressed: () => onConfirmHelp!(participantId, !isLiked),
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? Colors.blue : Colors.grey,
                  ),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;

  const _MiniPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.yellowPale,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.textMid),
      ),
    );
  }
}

class _HubActivityFeed extends ConsumerStatefulWidget {
  final String requestId;

  const _HubActivityFeed({required this.requestId});

  @override
  ConsumerState<_HubActivityFeed> createState() => _HubActivityFeedState();
}

class _HubActivityFeedState extends ConsumerState<_HubActivityFeed> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await ref
          .read(requestControllerProvider.notifier)
          .addRequestPost(widget.requestId, text);
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(requestPostsProvider(widget.requestId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 18, color: AppColors.textMid),
              const SizedBox(width: 6),
              Text(
                'Group Chat',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No instructions or updates yet. Start the room here.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                  ),
                );
              }
              return Column(
                children: posts.map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.yellowPale,
                          backgroundImage:
                              post.userPhoto != null &&
                                  post.userPhoto!.isNotEmpty
                              ? NetworkImage(post.userPhoto!)
                              : null,
                          child:
                              post.userPhoto == null || post.userPhoto!.isEmpty
                              ? Text(
                                  post.userName != null &&
                                          post.userName!.isNotEmpty
                                      ? post.userName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 11),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${post.userName ?? 'User'}: ',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                ),
                                TextSpan(
                                  text: post.message,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Error loading updates: $e',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ask for help, share instructions, or post updates...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitPost(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _isPosting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton.filled(
                      onPressed: _submitPost,
                      icon: const Icon(Icons.send, size: 18),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

String _roleFor(Map<String, dynamic> contact, String myRole) {
  return contact['role'] as String? ??
      contact['join_role'] as String? ??
      (myRole == 'helper' ? 'helpee' : 'helper');
}

String _roleLabel(String role) {
  return role == 'helper' ? 'Helper' : 'Helpie';
}

IconData _roleIcon(String role) {
  return role == 'helper'
      ? Icons.volunteer_activism_outlined
      : Icons.person_search_outlined;
}

Color _roleColor(String role) {
  return role == 'helper' ? Colors.blue.shade700 : Colors.green.shade700;
}
