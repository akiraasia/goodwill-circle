import 'package:flutter/material.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/agenda/models/nonprofit_agenda_item.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AgendaItemCard extends StatelessWidget {
  final NonprofitAgendaItem item;
  final VoidCallback onJoin;
  final void Function(String role)? onCommunityRoleSelected;
  final VoidCallback? onViewContacts;
  final VoidCallback? onToggleSupport;

  const AgendaItemCard({
    super.key, 
    required this.item, 
    required this.onJoin,
    this.onCommunityRoleSelected,
    this.onViewContacts,
    this.onToggleSupport,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCreator = currentUserId == item.ngoId;
    final alreadyJoined = item.myParticipantStatus != null;
    final isFull = item.seatsFilled >= item.seatsNeeded;
    final seatsLabel = '${item.seatsFilled}/${item.seatsNeeded} connected';
    final isNgoVerified = item.ngoVerificationStatus == 'verified';

    return AppCard(
      isFeatured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.yellowPale,
                child: Icon(Icons.apartment, color: AppColors.tan3, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.ngoName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.labelLarge,
                    ),
                    Text(
                      item.skillArea,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    if (isNgoVerified)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 13,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Verified NGO',
                            style: AppTypography.textTheme.labelSmall
                                ?.copyWith(color: Colors.green),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellowPale,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Certificate',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.tan3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.title, style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.description,
            style: AppTypography.textTheme.bodySmall,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(icon: Icons.place_outlined, label: item.location),
              _InfoChip(icon: Icons.groups_outlined, label: seatsLabel),
              _InfoChip(
                icon: Icons.workspace_premium_outlined,
                label: item.certificateTitle,
              ),
              if (item.completedConnectionsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handshake, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'Connected ${item.completedConnectionsCount} times',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.labelSmall?.copyWith(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 16,
                color: AppColors.textLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${item.certificateIssuer} issues badge ${item.rewardBadgeId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: AppColors.textLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'helpers: ${item.helperCount}, helpies: ${item.helpieCount}',
                style: AppTypography.textTheme.labelSmall,
              ),
              const SizedBox(width: AppSpacing.md),
              InkWell(
                onTap: onToggleSupport,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        item.hasSupported ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: item.hasSupported ? AppColors.red : AppColors.textLight,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${item.supportCount}',
                        style: AppTypography.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (alreadyJoined)
                SizedBox(
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
                )
              else if (onCommunityRoleSelected != null)
                Wrap(
                  spacing: 8,
                  children: [
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: isFull ? null : () => onCommunityRoleSelected!('helpee'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(width: 1),
                        ),
                        child: Text(isFull ? 'Full' : 'Need help', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: isFull ? null : () => onCommunityRoleSelected!('helper'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 28),
                        ),
                        child: Text(isFull ? 'Full' : 'Can help', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: isCreator || alreadyJoined || isFull ? null : onJoin,
                    icon: const Icon(Icons.handshake_outlined, size: 16),
                    label: Text(isCreator ? 'Posted' : alreadyJoined ? 'Connected' : isFull ? 'Full' : 'Connect'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textLight),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
