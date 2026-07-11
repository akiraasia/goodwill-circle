import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/requests/request_controller.dart';
import 'package:goodwill_circle/features/requests/widgets/request_card.dart';
import 'package:goodwill_circle/features/trust/trust_repository.dart';
import 'package:goodwill_circle/features/trust/widgets/platform_impact_overview.dart';
import 'package:goodwill_circle/shared/widgets/app_chat_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  static const _categories = [
    'All',
    'Career',
    'Technology',
    'Education',
    'Skill Development',
    'Entrepreneurship',
  ];

  String _selectedCategory = 'All';
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _requestsChannel;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _subscribeToRequestChanges();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final channel = _requestsChannel;
    if (channel != null) {
      _supabase.removeChannel(channel);
    }
    super.dispose();
  }

  void _subscribeToRequestChanges() {
    final channel = _supabase.channel('requests-feed-live');
    for (final table in const [
      'help_requests',
      'request_volunteers',
      'community_starter_request_joins',
      'help_request_posts',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleFeedRefresh(),
      );
    }
    _requestsChannel = channel.subscribe();
  }

  void _scheduleFeedRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(requestControllerProvider.notifier).loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestControllerProvider);
    final controller = ref.read(requestControllerProvider.notifier);
    final visibleRequests = _selectedCategory == 'All'
        ? state.requests
        : state.requests
              .where((request) => request.category == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SectionHeader(
            title: 'Goodwill Feed',
            actionLabel: 'Impact',
            onActionTap: _showImpactSheet,
          ),
          SizedBox(
            height: 32,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _selectedCategory;
                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    setState(() => _selectedCategory = category);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.tan2,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : AppColors.textMid,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: _categories.length,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.isLoading && state.requests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.error}'),
                        ElevatedButton(
                          onPressed: () => controller.loadRequests(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await controller.loadRequests();
                      ref.invalidate(platformImpactProvider);
                    },
                    child: visibleRequests.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            children: [
                              const SizedBox(height: 96),
                              Icon(
                                Icons.auto_awesome,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Nothing here yet.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _selectedCategory == 'All'
                                    ? 'Be the first to ask for help.'
                                    : 'No open requests in $_selectedCategory right now.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              right: AppSpacing.md,
                              bottom: 120, // space for bottom nav
                            ),
                            itemCount: visibleRequests.length,
                            itemBuilder: (context, index) {
                              final request = visibleRequests[index];
                              return RequestCard(
                                request: request,
                                onToggleSupport: () async {
                                  await controller.toggleSupport(request.id);
                                },
                                onVolunteer:
                                    ({
                                      communityJoinRole,
                                      contactOption,
                                      joinType,
                                    }) async {
                                      await controller.volunteerForRequest(
                                        request.id,
                                        isCommunityRequest:
                                            request.isCommunityRequest,
                                        communityJoinRole: communityJoinRole,
                                        contactOption: contactOption,
                                        joinType: joinType,
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You joined this goodwill loop.',
                                          ),
                                        ),
                                      );
                                    },
                                onComplete: (message, sendEmail) async {
                                  if (request.contactId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Helper ID not found.'),
                                      ),
                                    );
                                    return;
                                  }
                                  final email = await controller
                                      .completeRequest(
                                        request.id,
                                        request.contactId!,
                                        message,
                                      );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Connection marked as complete!',
                                      ),
                                    ),
                                  );

                                  if (sendEmail &&
                                      email != null &&
                                      email.isNotEmpty) {
                                    final uri = Uri.parse(
                                      'mailto:$email?subject=Goodwill Circle: Connection Completed&body=${Uri.encodeComponent(message)}',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not open email app.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                onRequestCompletion: (message) async {
                                  await controller.requestCompletionReview(
                                    requestId: request.id,
                                    message: message,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sent to helpee for confirmation.',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Global AI navigation chatbot
            FloatingActionButton(
              heroTag: 'goodwill_guide_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppChatScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.yellowPale,
              foregroundColor: AppColors.tan3,
              tooltip: 'Goodwill Guide',
              child: const Icon(Icons.auto_awesome),
            ),
            const SizedBox(height: 12),
            // New request
            FloatingActionButton.extended(
              heroTag: 'new_request_fab',
              onPressed: () {
                context.push('/create-request');
              },
              icon: const Icon(Icons.add),
              label: const Text('New Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImpactSheet() {
    ref.invalidate(platformImpactProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: PlatformImpactOverview(),
          ),
        );
      },
    );
  }
}
