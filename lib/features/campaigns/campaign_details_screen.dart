import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/campaigns/campaign_controller.dart';
import 'package:goodwill_circle/features/campaigns/campaign_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

class CampaignDetailsScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CampaignDetailsScreen> createState() =>
      _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends ConsumerState<CampaignDetailsScreen> {
  final _donationController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _donationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _donate(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Donate Goodwill Credits'),
          content: TextField(
            controller: _donationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount to Donate',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(_donationController.text) ?? 0;
                if (amount > 0) {
                  Navigator.pop(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                  try {
                    await ref
                        .read(campaignRepositoryProvider)
                        .donateToCampaign(widget.campaignId, amount);
                    // Refresh data
                    ref.invalidate(campaignDetailsProvider(widget.campaignId));
                    ref.invalidate(
                      campaignDonationsProvider(widget.campaignId),
                    );
                    ref.invalidate(campaignUpdatesProvider(widget.campaignId));
                    ref
                        .read(campaignControllerProvider.notifier)
                        .loadCampaigns(); // refresh list too

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Donation successful!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Donate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinCampaign(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(campaignRepositoryProvider)
          .joinCampaign(widget.campaignId, 'helper');
      ref.invalidate(campaignDetailsProvider(widget.campaignId));
      ref.read(campaignControllerProvider.notifier).loadCampaigns();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Joined campaign.')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _voteForCampaign(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(campaignRepositoryProvider)
          .voteForCampaign(widget.campaignId);
      ref.invalidate(campaignDetailsProvider(widget.campaignId));
      ref.read(campaignControllerProvider.notifier).loadCampaigns();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Vote counted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addComment(BuildContext context) async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(campaignRepositoryProvider)
          .addCampaignComment(widget.campaignId, message);
      _commentController.clear();
      ref.invalidate(campaignCommentsProvider(widget.campaignId));
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Comment posted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignAsync = ref.watch(campaignDetailsProvider(widget.campaignId));
    final updatesAsync = ref.watch(campaignUpdatesProvider(widget.campaignId));
    final commentsAsync = ref.watch(
      campaignCommentsProvider(widget.campaignId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Details')),
      body: campaignAsync.when(
        data: (campaign) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          campaign.creatorPhoto != null &&
                              campaign.creatorPhoto!.isNotEmpty
                          ? NetworkImage(campaign.creatorPhoto!)
                          : null,
                      child:
                          campaign.creatorPhoto == null ||
                              campaign.creatorPhoto!.isEmpty
                          ? const Icon(Icons.business, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Organized by ${campaign.creatorName ?? 'Community Leader'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (campaign.imageUrl != null &&
                    campaign.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        campaign.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Impact Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: campaign.progressPercentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${campaign.currentAmount} / ${campaign.goalAmount} Credits',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${(campaign.progressPercentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${campaign.supportersCount} Supporters',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: campaign.isVoted
                        ? null
                        : () => _voteForCampaign(context),
                    icon: Icon(
                      campaign.isVoted
                          ? Icons.how_to_vote
                          : Icons.how_to_vote_outlined,
                    ),
                    label: Text(campaign.isVoted ? 'Voted' : 'Vote Support'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: campaign.isJoined
                        ? null
                        : () => _joinCampaign(context),
                    icon: Icon(
                      campaign.isJoined
                          ? Icons.check
                          : Icons.group_add_outlined,
                    ),
                    label: Text(
                      campaign.isJoined
                          ? 'Joined Campaign'
                          : 'Join Campaign Feed',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: campaign.status == 'active'
                        ? () => _donate(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      campaign.status == 'active'
                          ? 'Donate Goodwill Credits'
                          : 'Campaign Ended',
                    ),
                  ),
                ),
                const Divider(height: 48),
                Text(
                  'About this Campaign',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(campaign.description),
                const Divider(height: 48),
                Text(
                  'Updates & Impact Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                updatesAsync.when(
                  data: (updates) {
                    if (updates.isEmpty) {
                      return const Text('No updates yet.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: updates.length,
                      itemBuilder: (context, index) {
                        final update = updates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeago.format(update.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(update.message),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading updates: $e'),
                ),
                const Divider(height: 48),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Add support or a question',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _addComment(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Text('No comments yet.');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage:
                                comment.userPhoto != null &&
                                    comment.userPhoto!.isNotEmpty
                                ? NetworkImage(comment.userPhoto!)
                                : null,
                            child:
                                comment.userPhoto == null ||
                                    comment.userPhoto!.isEmpty
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          title: Text(comment.userName ?? 'Supporter'),
                          subtitle: Text(comment.message),
                          trailing: Text(
                            timeago.format(comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading comments: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
