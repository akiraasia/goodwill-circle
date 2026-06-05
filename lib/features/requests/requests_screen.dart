import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/requests/request_controller.dart';
import 'package:goodwill_circle/features/requests/widgets/request_card.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  static const _categories = [
    'All',
    'Education',
    'Career',
    'Food',
    'Medical',
    'Finance',
    'Housing',
    'Emotional Support',
    'Other',
  ];

  String _selectedCategory = 'All';

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SectionHeader(
              title: 'Goodwill Feed',
              actionLabel: 'Refresh',
              onActionTap: () => controller.loadRequests(),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemCount: _categories.length,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                      onRefresh: () => controller.loadRequests(),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
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
                                  onVolunteer: () async {
                                    await controller.volunteerForRequest(
                                      request.id,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You joined this goodwill loop.',
                                        ),
                                      ),
                                    );
                                  },
                                  onComplete: () async {
                                    await controller.completeRequest(
                                      request.id,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Request marked as complete!',
                                        ),
                                      ),
                                    );
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
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.push('/create-request');
          },
          icon: const Icon(Icons.add),
          label: const Text('New Request'),
        ),
      ),
    );
  }
}
