import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:goodwill_circle/shared/services/external_contact_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestCard extends StatelessWidget {
  final HelpRequest request;
  final Future<void> Function({
    String? communityJoinRole,
    RequestContactOption? contactOption,
  })
  onVolunteer;
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
    final isCommunityRequest = request.isCommunityRequest;
    final isCompletionRequested =
        request.myVolunteerStatus == 'completion_requested';
    final authorName = request.creatorName ?? 'Community member';
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequestVisual(request: request),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.yellowPale,
                      backgroundImage: request.creatorPhoto != null &&
                              request.creatorPhoto!.isNotEmpty
                          ? NetworkImage(request.creatorPhoto!)
                          : null,
                      child: request.creatorPhoto == null ||
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
                    _ImpactPill(
                      label: isCommunityRequest
                          ? '${request.goodwillImpactScore}%'
                          : isUrgent
                              ? 'URGENT'
                              : '+${request.goodwillReward}',
                      urgent: isUrgent && !isCommunityRequest,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(request.title, style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  request.description,
                  style: AppTypography.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCommunityRequest && request.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: request.tags.take(2).map(_TagPill.new).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isCommunityRequest
                          ? '${request.volunteersCount} joined'
                          : '${request.volunteersCount} helping',
                      style: AppTypography.textTheme.labelSmall,
                    ),
                    if (isCommunityRequest && request.helperCount > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${request.helperCount} helpers',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                    const Spacer(),
                    _ActionButton(
                      isCreator: isCreator,
                      isHelping: isHelping,
                      isCommunityRequest: isCommunityRequest,
                      isCompletionRequested: isCompletionRequested,
                      onComplete: onComplete,
                      onVolunteer: () => _handleVolunteer(context),
                      onCommunityRoleSelected: (role) =>
                          _handleVolunteer(context, role),
                      onShowCompletion: () => _showCompletionDialog(context),
                    ),
                  ],
                ),
                if (isCommunityRequest &&
                    isHelping &&
                    request.joinedContactOption != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _FeedContactPanel(
                    option: request.joinedContactOption!,
                    role: request.communityJoinRole,
                  ),
                ],
                if (request.contactPhone != null &&
                    request.contactPhone!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
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
                    ],
                  ),
                ],
                if (isCreator && isCompletionRequested) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CompletionNotice(
                    helperName: request.contactName ?? 'Helper',
                    message: request.completionMessage,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVolunteer(BuildContext context, [String? role]) async {
    if (!request.isCommunityRequest || request.contactOptions.isEmpty) {
      await onVolunteer();
      return;
    }

    final selected = await showModalBottomSheet<RequestContactOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => _JoinChoiceSheet(options: request.contactOptions),
    );

    if (selected == null) return;
    await onVolunteer(communityJoinRole: role ?? 'helpee', contactOption: selected);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _UnlockedContactSheet(option: selected),
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

class _RequestVisual extends StatelessWidget {
  final HelpRequest request;

  const _RequestVisual({required this.request});

  @override
  Widget build(BuildContext context) {
    if (request.artAssetPath != null && request.artAssetPath!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 2.45,
        child: Image.asset(request.artAssetPath!, fit: BoxFit.cover),
      );
    }

    if (request.imageUrl != null && request.imageUrl!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(request.imageUrl!, fit: BoxFit.cover),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ImpactPill extends StatelessWidget {
  final String label;
  final bool urgent;

  const _ImpactPill({required this.label, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.red.withValues(alpha: 0.1)
            : AppColors.yellowPale,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: urgent ? AppColors.red : AppColors.tan3,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.yellowPale,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.tan3,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isCreator;
  final bool isHelping;
  final bool isCommunityRequest;
  final bool isCompletionRequested;
  final VoidCallback onComplete;
  final Future<void> Function() onVolunteer;
  final void Function(String role) onCommunityRoleSelected;
  final VoidCallback onShowCompletion;

  const _ActionButton({
    required this.isCreator,
    required this.isHelping,
    required this.isCommunityRequest,
    required this.isCompletionRequested,
    required this.onComplete,
    required this.onVolunteer,
    required this.onCommunityRoleSelected,
    required this.onShowCompletion,
  });

  @override
  Widget build(BuildContext context) {
    if (isCreator) {
      return SizedBox(
        height: 34,
        child: ElevatedButton.icon(
          onPressed: isCompletionRequested ? onComplete : null,
          icon: const Icon(Icons.check_circle, size: 16),
          label: Text(isCompletionRequested ? 'Confirm' : 'Wait'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      );
    }

    if (isHelping && !isCommunityRequest) {
      return SizedBox(
        height: 34,
        child: ElevatedButton.icon(
          onPressed: isCompletionRequested ? null : onShowCompletion,
          icon: const Icon(Icons.rate_review, size: 16),
          label: Text(isCompletionRequested ? 'Sent' : 'Complete'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      );
    }

    if (isCommunityRequest && isHelping) {
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.yellowPale,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Joined', style: AppTypography.textTheme.labelSmall),
      );
    }

    if (isCommunityRequest) {
      return Wrap(
        spacing: 6,
        children: [
          SizedBox(
            height: 30,
            child: OutlinedButton(
              onPressed: () => onCommunityRoleSelected('helpee'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9),
              ),
              child: const Text('Need help'),
            ),
          ),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: () => onCommunityRoleSelected('helper'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9),
              ),
              child: const Text('Can help'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onVolunteer,
        icon: const Icon(Icons.volunteer_activism, size: 16),
        label: Text(isCommunityRequest ? 'Join' : 'Help'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}

class _JoinChoiceSheet extends StatelessWidget {
  final List<RequestContactOption> options;

  const _JoinChoiceSheet({required this.options});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join this need', style: AppTypography.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose where you want to connect after joining.',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.tan1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: Icon(_contactIcon(option.type)),
                  title: Text(option.label),
                  subtitle: option.note == null ? null : Text(option.note!),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pop(context, option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _UnlockedContactSheet extends StatelessWidget {
  final RequestContactOption option;

  const _UnlockedContactSheet({required this.option});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact unlocked', style: AppTypography.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(option.label, style: AppTypography.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(option.value, style: AppTypography.textTheme.bodyMedium),
            if (option.note != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                option.note!,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: option.value));
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openContactValue(context, option),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionNotice extends StatelessWidget {
  final String helperName;
  final String? message;

  const _CompletionNotice({required this.helperName, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.yellowPale,
        border: Border.all(color: AppColors.yellow),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message == null || message!.trim().isEmpty
            ? '$helperName requested completion'
            : '$helperName requested completion: $message',
        style: AppTypography.textTheme.labelLarge,
      ),
    );
  }
}

class _FeedContactPanel extends StatelessWidget {
  final RequestContactOption option;
  final String? role;

  const _FeedContactPanel({required this.option, this.role});

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == 'helper' ? 'Helping as helper' : 'Joined for help';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_contactIcon(option.type), size: 18, color: AppColors.tan3),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roleLabel, style: AppTypography.textTheme.labelSmall),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy contact',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: option.value)),
            icon: const Icon(Icons.copy, size: 17),
          ),
          IconButton(
            tooltip: 'Open contact',
            onPressed: () => _openContactValue(context, option),
            icon: const Icon(Icons.open_in_new, size: 17),
          ),
        ],
      ),
    );
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

IconData _contactIcon(String type) {
  switch (type) {
    case 'whatsapp':
      return Icons.chat_bubble_outline;
    case 'telegram':
      return Icons.send;
    case 'mentor':
      return Icons.person_search;
    default:
      return Icons.groups_2_outlined;
  }
}

Future<void> _openContactValue(
  BuildContext context,
  RequestContactOption option,
) async {
  final uri = Uri.tryParse(option.value);
  if (uri == null || !uri.hasScheme) {
    await Clipboard.setData(ClipboardData(text: option.value));
    if (context.mounted) Navigator.pop(context);
    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    await Clipboard.setData(ClipboardData(text: option.value));
  }
  if (context.mounted) Navigator.pop(context);
}
