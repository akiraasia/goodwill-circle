import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/services/external_contact_service.dart';

class RequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onVolunteer;
  final VoidCallback onComplete;
  final Future<void> Function(String? message) onRequestCompletion;

  const RequestCard({
    super.key,
    required this.request,
    required this.onVolunteer,
    required this.onComplete,
    required this.onRequestCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCreator = currentUserId == request.creatorId;
    final isUrgent = request.goodwillReward >= 25;
    final isHelping = request.myVolunteerStatus != null;
    final isCompletionRequested =
        request.myVolunteerStatus == 'completion_requested';
    final helperName = request.contactName ?? 'Helper';
    final authorName = request.creatorName ?? 'Community member';
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

    return AppCard(
      isUrgent: isUrgent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.yellowPale,
                backgroundImage:
                    request.creatorPhoto != null &&
                        request.creatorPhoto!.isNotEmpty
                    ? NetworkImage(request.creatorPhoto!)
                    : null,
                child:
                    request.creatorPhoto == null ||
                        request.creatorPhoto!.isEmpty
                    ? Text(initial, style: AppTypography.textTheme.labelLarge)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.labelLarge,
                    ),
                    Text(
                      request.category,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.red.withValues(alpha: 0.1)
                      : AppColors.yellowPale,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isUrgent ? 'URGENT' : '+${request.goodwillReward}',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: isUrgent ? AppColors.red : AppColors.tan3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(request.title, style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            request.description,
            style: AppTypography.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          if (request.imageUrl != null && request.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(request.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (request.contactPhone != null &&
              request.contactPhone!.trim().isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ContactChip(
                  icon: Icons.call,
                  label: 'Call',
                  onTap: () => _launchContact(
                    context,
                    ExternalContactService.call(request.contactPhone!),
                  ),
                ),
                _ContactChip(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  onTap: () => _launchContact(
                    context,
                    ExternalContactService.chat(
                      request.contactPhone!,
                      message:
                          'Hi, I am reaching out about "${request.title}".',
                    ),
                  ),
                ),
                _ContactChip(
                  icon: Icons.video_call,
                  label: 'Video',
                  onTap: () => _launchContact(
                    context,
                    ExternalContactService.video(request.contactPhone!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (isCreator && isCompletionRequested) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.yellowPale,
                border: Border.all(color: AppColors.yellow),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rate_review, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '$helperName requested completion',
                          style: AppTypography.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  if (request.completionMessage != null &&
                      request.completionMessage!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      request.completionMessage!,
                      style: AppTypography.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: AppColors.textLight),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${request.volunteersCount} helping',
                style: AppTypography.textTheme.labelSmall,
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: isCreator
                    ? ElevatedButton.icon(
                        onPressed: isCompletionRequested ? onComplete : null,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: Text(isCompletionRequested ? 'Confirm' : 'Wait'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )
                    : isHelping
                    ? ElevatedButton.icon(
                        onPressed: isCompletionRequested
                            ? null
                            : () => _showCompletionDialog(context),
                        icon: const Icon(Icons.rate_review, size: 16),
                        label: Text(
                          isCompletionRequested ? 'Sent' : 'Complete help',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: onVolunteer,
                        icon: const Icon(Icons.volunteer_activism, size: 16),
                        label: const Text('I can help'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchContact(BuildContext context, Future<bool> action) async {
    final opened = await action;
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone app is available for this.')),
      );
    }
  }

  Future<void> _showCompletionDialog(BuildContext context) async {
    final controller = TextEditingController();
    final message = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send for confirmation?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Review message to helpee',
            hintText: 'Tell them what you completed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null) return;
    await onRequestCompletion(message.isEmpty ? null : message);
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
