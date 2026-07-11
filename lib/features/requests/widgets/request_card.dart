import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:goodwill_circle/features/requests/widgets/help_chat_screen.dart';
import 'package:goodwill_circle/shared/services/external_contact_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:goodwill_circle/shared/widgets/contact_exchange_screen.dart';

class RequestCard extends ConsumerStatefulWidget {
  final HelpRequest request;
  final Future<void> Function({
    String? communityJoinRole,
    RequestContactOption? contactOption,
    String? joinType,
  })
  onVolunteer;
  final Future<void> Function(String message, bool sendEmail) onComplete;
  final Future<void> Function(String? message) onRequestCompletion;
  final VoidCallback? onToggleSupport;

  const RequestCard({
    super.key,
    required this.request,
    required this.onVolunteer,
    required this.onComplete,
    required this.onRequestCompletion,
    this.onToggleSupport,
  });

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard> {
  void _navigateToContacts(BuildContext context, String myRole) {
    final actualRole = widget.request.myVolunteerStatus != null
        ? (widget.request.communityJoinRole ?? 'helper')
        : myRole;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactExchangeScreen(
          entityId: widget.request.id,
          entityType: 'request',
          myRole: actualRole,
          title: 'Connection Hub',
        ),
      ),
    );
  }

  Future<void> _handleVolunteer(BuildContext context, [String? role]) async {
    // Show a dialog to let the user select their role and join type
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Join Goodwill Loop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how you would like to join this help request:'),
            const SizedBox(height: 16),
            if (role == null || role == 'helper') ...[
              ListTile(
                leading: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.blue,
                ),
                title: const Text('Join as Helper (Individual)'),
                subtitle: const Text('Help out as a single volunteer'),
                onTap: () => Navigator.pop(context, {
                  'role': 'helper',
                  'type': 'individual',
                }),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: const Text('Join as Helper (Multiple/Group)'),
                subtitle: const Text('Help out with a group/team'),
                onTap: () => Navigator.pop(context, {
                  'role': 'helper',
                  'type': 'multiple',
                }),
              ),
            ],
            if (role == null) const Divider(thickness: 1.5),
            if (role == null || role == 'helpee') ...[
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.green),
                title: const Text('Join as Helpie (Individual)'),
                subtitle: const Text('Need help for yourself'),
                onTap: () => Navigator.pop(context, {
                  'role': 'helpee',
                  'type': 'individual',
                }),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_outlined, color: Colors.green),
                title: const Text('Join as Helpie (Multiple/Group)'),
                subtitle: const Text('Need help for a group/community'),
                onTap: () => Navigator.pop(context, {
                  'role': 'helpee',
                  'type': 'multiple',
                }),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final selectedRole = result['role']!;
    final type = result['type']!;

    try {
      await widget.onVolunteer(
        communityJoinRole: selectedRole,
        joinType: type,
        contactOption: const RequestContactOption(
          label: 'Connection Hub',
          type: 'group',
          value: '',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not join Connection Hub: $e')),
      );
      return;
    }

    if (!context.mounted) return;
    _navigateToContacts(context, selectedRole);
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
    await widget.onRequestCompletion(message.isEmpty ? null : message);
  }

  Future<void> _showConfirmCompletionDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool sendEmail = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message to helper',
                  hintText: 'Thank them for their help!',
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'Email this helper after completing',
                  style: TextStyle(fontSize: 14),
                ),
                value: sendEmail,
                onChanged: (val) {
                  setState(() {
                    sendEmail = val ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'message': controller.text.trim(),
                'sendEmail': sendEmail,
              }),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null) return;
    await widget.onComplete(
      result['message'] as String,
      result['sendEmail'] as bool,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCreator = currentUserId == widget.request.creatorId;
    final isUrgent = widget.request.goodwillReward >= 25;
    final isHelping = widget.request.myVolunteerStatus != null;
    final isCommunityRequest = widget.request.isCommunityRequest;
    final isCompletionRequested =
        widget.request.myVolunteerStatus == 'completion_requested';
    final hasCompleted = widget.request.myVolunteerStatus == 'completed';
    final authorName = widget.request.creatorName ?? 'Community member';
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          if (isWide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _RequestVisual(
                      request: widget.request,
                      isWide: true,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _RequestDetails(
                      request: widget.request,
                      isCreator: isCreator,
                      isUrgent: isUrgent,
                      isHelping: isHelping,
                      isCommunityRequest: isCommunityRequest,
                      isCompletionRequested: isCompletionRequested,
                      authorName: authorName,
                      initial: initial,
                      hasCompleted: hasCompleted,
                      onVolunteer: () => _handleVolunteer(context),
                      onCommunityRoleSelected: (role) =>
                          _handleVolunteer(context, role),
                      onComplete: () => _showConfirmCompletionDialog(context),
                      onShowCompletion: () => _showCompletionDialog(context),
                      launchContact: (action) =>
                          _launchContact(context, action),
                      onViewContacts: () => _navigateToContacts(
                        context,
                        isCreator
                            ? 'helpee'
                            : widget.request.communityJoinRole ?? 'helper',
                      ),
                      onToggleSupport: widget.onToggleSupport,
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequestVisual(request: widget.request, isWide: false),
              _RequestDetails(
                request: widget.request,
                isCreator: isCreator,
                isUrgent: isUrgent,
                isHelping: isHelping,
                isCommunityRequest: isCommunityRequest,
                isCompletionRequested: isCompletionRequested,
                authorName: authorName,
                initial: initial,
                hasCompleted: hasCompleted,
                onVolunteer: () => _handleVolunteer(context),
                onCommunityRoleSelected: (role) =>
                    _handleVolunteer(context, role),
                onComplete: () => _showConfirmCompletionDialog(context),
                onShowCompletion: () => _showCompletionDialog(context),
                launchContact: (action) => _launchContact(context, action),
                onViewContacts: () => _navigateToContacts(
                  context,
                  isCreator
                      ? 'helpee'
                      : widget.request.communityJoinRole ?? 'helper',
                ),
                onToggleSupport: widget.onToggleSupport,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RequestDetails extends StatelessWidget {
  final HelpRequest request;
  final bool isCreator;
  final bool isUrgent;
  final bool isHelping;
  final bool isCommunityRequest;
  final bool isCompletionRequested;
  final String authorName;
  final String initial;
  final bool hasCompleted;
  final Future<void> Function() onVolunteer;
  final void Function(String role) onCommunityRoleSelected;
  final VoidCallback onComplete;
  final VoidCallback onShowCompletion;
  final void Function(Future<bool> action) launchContact;
  final VoidCallback? onViewContacts;
  final VoidCallback? onToggleSupport;

  const _RequestDetails({
    required this.request,
    required this.isCreator,
    required this.isUrgent,
    required this.isHelping,
    required this.isCommunityRequest,
    required this.isCompletionRequested,
    required this.authorName,
    required this.initial,
    required this.hasCompleted,
    required this.onVolunteer,
    required this.onCommunityRoleSelected,
    required this.onComplete,
    required this.onShowCompletion,
    required this.launchContact,
    this.onViewContacts,
    this.onToggleSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              _ImpactPill(
                label: isUrgent ? 'URGENT' : '+${request.goodwillReward}',
                urgent: isUrgent,
              ),
            ],
          ),
          if (request.artAssetPath == null ||
              request.artAssetPath!.isEmpty) ...[
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
          ],
          // Helper / Helpee count chips
          if (request.helperCount > 0 || request.helpieCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (request.helperCount > 0)
                  _StatChip(
                    icon: Icons.volunteer_activism,
                    label:
                        '${request.helperCount} helper${request.helperCount != 1 ? 's' : ''}',
                    color: Colors.blue,
                  ),
                if (request.helpieCount > 0)
                  _StatChip(
                    icon: Icons.person_outline,
                    label:
                        '${request.helpieCount} helpee${request.helpieCount != 1 ? 's' : ''}',
                    color: Colors.green,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (request.completedConnectionsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Completed ${request.completedConnectionsCount}',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: onToggleSupport,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        request.hasSupported
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: request.hasSupported
                            ? Colors.red
                            : AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${request.supportCount}',
                        style: AppTypography.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
              // AI chatbot icon — opens contextual chat for this request
              Builder(
                builder: (context) => InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpChatScreen(request: request),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Action button container (Placed underneath stats row to fit beautifully on Android)
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              isCreator: isCreator,
              isHelping: isHelping,
              isCommunityRequest: isCommunityRequest,
              isCompletionRequested: isCompletionRequested,
              hasCompleted: hasCompleted,
              helperCount: request.helperCount,
              helpieCount: request.helpieCount,
              onComplete: onComplete,
              onVolunteer: onVolunteer,
              onCommunityRoleSelected: onCommunityRoleSelected,
              onShowCompletion: onShowCompletion,
              onViewContacts: onViewContacts,
            ),
          ),
          if (!isCommunityRequest && (isHelping || isCreator)) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewContacts,
                icon: const Icon(Icons.groups_2_outlined, size: 16),
                label: const Text('Connection Hub'),
              ),
            ),
          ],
          if (isHelping && request.joinedContactOption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _FeedContactPanel(
              option: request.joinedContactOption!,
              role: request.communityJoinRole,
              request: request,
              onViewContacts: onViewContacts,
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
                  onTap: () => launchContact(
                    ExternalContactService.call(request.contactPhone!),
                  ),
                ),
                _ContactChip(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  onTap: () => launchContact(
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
    );
  }
}

class _RequestVisual extends StatelessWidget {
  final HelpRequest request;
  final bool isWide;

  const _RequestVisual({required this.request, this.isWide = false});

  @override
  Widget build(BuildContext context) {
    final authorName = request.creatorName ?? 'Community member';
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

    if (request.artAssetPath != null && request.artAssetPath!.isNotEmpty) {
      return Container(
        width: double.infinity,
        color: AppColors.tan1,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: isWide ? Radius.zero : const Radius.circular(8),
            bottomLeft: isWide ? const Radius.circular(8) : Radius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isWide ? double.infinity : 200,
            ),
            child: Image.asset(
              request.artAssetPath!,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (request.imageUrl != null && request.imageUrl!.isNotEmpty) {
      return Container(
        width: double.infinity,
        color: AppColors.tan1,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: isWide ? Radius.zero : const Radius.circular(8),
            bottomLeft: isWide ? const Radius.circular(8) : Radius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isWide ? double.infinity : 200,
            ),
            child: Image.network(
              request.imageUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (request.creatorPhoto != null && request.creatorPhoto!.isNotEmpty) {
      return Container(
        width: double.infinity,
        color: AppColors.tan1,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: isWide ? Radius.zero : const Radius.circular(8),
            bottomLeft: isWide ? const Radius.circular(8) : Radius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isWide ? double.infinity : 200,
            ),
            child: Image.network(
              request.creatorPhoto!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: AppColors.tan1,
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(8),
          topRight: isWide ? Radius.zero : const Radius.circular(8),
          bottomLeft: isWide ? const Radius.circular(8) : Radius.zero,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isWide ? double.infinity : 200,
          ),
          child: Container(
            width: double.infinity,
            height: 200,
            color: AppColors.yellowPale,
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                color: AppColors.tan3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isCreator;
  final bool isHelping;
  final bool isCommunityRequest;
  final bool isCompletionRequested;
  final bool hasCompleted;
  final int helperCount;
  final int helpieCount;
  final VoidCallback onComplete;
  final Future<void> Function() onVolunteer;
  final void Function(String role) onCommunityRoleSelected;
  final VoidCallback onShowCompletion;
  final VoidCallback? onViewContacts;

  const _ActionButton({
    required this.isCreator,
    required this.isHelping,
    required this.isCommunityRequest,
    required this.isCompletionRequested,
    required this.hasCompleted,
    required this.helperCount,
    required this.helpieCount,
    required this.onComplete,
    required this.onVolunteer,
    required this.onCommunityRoleSelected,
    required this.onShowCompletion,
    this.onViewContacts,
  });

  @override
  Widget build(BuildContext context) {
    if (isCreator) {
      final canCompleteDirectly = helpieCount <= 1 && helperCount >= 1;
      final showConfirmButton = isCompletionRequested || canCompleteDirectly;
      return SizedBox(
        height: 34,
        child: ElevatedButton.icon(
          onPressed: showConfirmButton ? onComplete : null,
          icon: const Icon(Icons.check_circle, size: 16),
          label: Text(showConfirmButton ? 'Confirm' : 'Wait'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      );
    }

    if (hasCompleted) {
      return SizedBox(
        height: 34,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Connected'),
          style: ElevatedButton.styleFrom(
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
      return SizedBox(
        height: 34,
        child: ElevatedButton.icon(
          onPressed: onViewContacts,
          icon: const Icon(Icons.group, size: 16),
          label: const Text('View Contacts'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      );
    }

    if (isCommunityRequest) {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          SizedBox(
            height: 28,
            child: OutlinedButton(
              onPressed: () => onCommunityRoleSelected('helpee'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(width: 1),
              ),
              child: const Text('Need help', style: TextStyle(fontSize: 12)),
            ),
          ),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: () => onCommunityRoleSelected('helper'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 28),
              ),
              child: const Text('Can help', style: TextStyle(fontSize: 12)),
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
        label: const Text('Join/Help'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
  final HelpRequest request;
  final VoidCallback? onViewContacts;

  bool get isConnectionHub => _isConnectionHubOption(option);

  const _FeedContactPanel({
    required this.option,
    this.role,
    required this.request,
    this.onViewContacts,
  });

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == 'helper'
        ? 'Helping as helper'
        : 'Joined for help';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roleLabel,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _contactIcon(option.type),
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (option.value.length < 50 && option.value.isNotEmpty)
                      Text(
                        option.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                child: IconButton(
                  tooltip: 'Copy',
                  onPressed: () {
                    final textToCopy = isConnectionHub
                        ? 'Connection Hub for ${request.title}'
                        : option.value;
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied details to clipboard'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: IconButton(
                  tooltip: 'Open',
                  onPressed: () {
                    if (isConnectionHub) {
                      onViewContacts?.call();
                    } else {
                      _openContactValue(context, option);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
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

bool _isConnectionHubOption(RequestContactOption option) {
  final normalizedLabel = option.label.trim().toLowerCase();
  final normalizedValue = option.value.trim();
  return normalizedLabel == 'connection hub' ||
      (option.type == 'group' && normalizedValue.isEmpty) ||
      normalizedValue ==
          'Your registered email and phone number will be used to connect.';
}

Future<void> _openContactValue(
  BuildContext context,
  RequestContactOption option,
) async {
  final uri = Uri.tryParse(option.value);
  if (uri == null || !uri.hasScheme) {
    await Clipboard.setData(ClipboardData(text: option.value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard (not a valid URL)')),
      );
    }
    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    await Clipboard.setData(ClipboardData(text: option.value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link, copied to clipboard'),
        ),
      );
    }
  }
}
