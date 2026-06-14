import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/features/agenda/agenda_controller.dart';
import 'package:goodwill_circle/features/agenda/widgets/agenda_item_card.dart';
import 'package:goodwill_circle/shared/widgets/contact_exchange_screen.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agendaControllerProvider);
    final controller = ref.read(agendaControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SectionHeader(
              title: 'NGO Agenda',
              actionLabel: 'Refresh',
              onActionTap: () => controller.loadAgendaItems(),
            ),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${state.error}'),
                          ElevatedButton(
                            onPressed: () => controller.loadAgendaItems(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.loadAgendaItems(),
                      child: state.items.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              children: [
                                const SizedBox(height: 96),
                                Icon(
                                  Icons.school_outlined,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No nonprofit agenda yet.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                const Text(
                                  'Post a teaching, mentoring, training, or service opportunity for the community.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                bottom: 120,
                              ),
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                return AgendaItemCard(
                                  item: item,
                                  onCommunityRoleSelected: (role) async {
                                    await controller.joinAgendaItem(item.id, role);
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ContactExchangeScreen(
                                          entityId: item.id,
                                          entityType: 'agenda',
                                          myRole: role,
                                          title: 'Connection Hub',
                                        ),
                                      ),
                                    );
                                  },
                                  onViewContacts: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ContactExchangeScreen(
                                          entityId: item.id,
                                          entityType: 'agenda',
                                          myRole: item.myParticipantStatus == 'helper' ? 'helper' : 'helpee',
                                          title: 'Connection Hub',
                                        ),
                                      ),
                                    );
                                  },
                                  onToggleSupport: () {
                                    controller.toggleSupport(item.id);
                                  },
                                  onJoin: () {}, // Fallback unused, role buttons preferred
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create-agenda'),
          icon: const Icon(Icons.add),
          label: const Text('Add Agenda'),
        ),
      ),
    );
  }
}
