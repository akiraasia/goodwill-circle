import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/campaigns/campaign_controller.dart';
import 'package:goodwill_circle/features/campaigns/widgets/campaign_card.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/shared/widgets/contact_exchange_screen.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignControllerProvider);
    final controller = ref.read(campaignControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SectionHeader(
              title: 'Community Campaigns',
              actionLabel: 'Refresh',
              onActionTap: () => controller.loadCampaigns(),
            ),
            Expanded(
              child: state.isLoading && state.campaigns.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.campaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${state.error}'),
                          ElevatedButton(
                            onPressed: () => controller.loadCampaigns(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.loadCampaigns(),
                      child: state.campaigns.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    'No active campaigns. Start one!',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                bottom: 120, // space for bottom nav
                              ),
                              itemCount: state.campaigns.length,
                              itemBuilder: (context, index) {
                                final campaign = state.campaigns[index];
                                return CampaignCard(
                                  campaign: campaign,
                                  onTap: () {
                                    context.push('/campaign/${campaign.id}');
                                  },
                                  onCommunityRoleSelected: (role) async {
                                    try {
                                      await controller.joinCampaign(campaign.id, role);
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ContactExchangeScreen(
                                              entityId: campaign.id,
                                              entityType: 'campaign',
                                              myRole: role,
                                              title: 'Connection Hub',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  onViewContacts: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ContactExchangeScreen(
                                          entityId: campaign.id,
                                          entityType: 'campaign',
                                          myRole: 'helper',
                                          title: 'Connection Hub',
                                        ),
                                      ),
                                    );
                                  },
                                  onToggleSupport: () {
                                    controller.toggleSupport(campaign.id);
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
            context.push('/create-campaign');
          },
          icon: const Icon(Icons.add),
          label: const Text('Start Campaign'),
        ),
      ),
    );
  }
}
