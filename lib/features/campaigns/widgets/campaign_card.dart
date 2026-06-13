import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/campaigns/models/campaign.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/core/theme/app_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final void Function(String role)? onCommunityRoleSelected;
  final VoidCallback? onViewContacts;
  final VoidCallback? onToggleSupport;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
    this.onJoin,
    this.onCommunityRoleSelected,
    this.onViewContacts,
    this.onToggleSupport,
  });

  @override
  Widget build(BuildContext context) {
    final creatorVerified =
        campaign.creatorVerificationStatus == 'verified';

    return AppCard(
      onTap: onTap,
      isFeatured: campaign.progressPercentage > 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.campaign,
                color: AppColors.textDark,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    Text(
                      campaign.creatorName ?? 'Community Leader',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    if (creatorVerified || campaign.isVerified)
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
                            campaign.isVerified
                                ? 'Verified campaign'
                                : 'Verified creator',
                            style: AppTypography.textTheme.labelSmall
                                ?.copyWith(color: Colors.green),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (campaign.endDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tan1,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${campaign.endDate!.difference(DateTime.now()).inDays}d left',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.tan3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            campaign.description,
            style: AppTypography.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(campaign.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: campaign.progressPercentage,
              minHeight: 6,
              backgroundColor: AppColors.tan1,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '${campaign.currentAmount} / ${campaign.goalAmount} credits',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (campaign.completedConnectionsCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🤝 Connected ${campaign.completedConnectionsCount} times',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Icon(
                LucideIcons.users,
                size: 16,
                color: AppColors.textLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'helpers: ${campaign.helperCount}, helpies: ${campaign.helpieCount}',
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
                        campaign.hasSupported ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: campaign.hasSupported ? AppColors.red : AppColors.textLight,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${campaign.supportCount}',
                        style: AppTypography.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Spacer(),
              if (campaign.isJoined)
                SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: onViewContacts,
                    icon: Icon(LucideIcons.users, size: 16),
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
                        onPressed: () => onCommunityRoleSelected!('helpee'),
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
                        onPressed: () => onCommunityRoleSelected!('helper'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 28),
                        ),
                        child: const Text('Can help', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.group_add_outlined, size: 16),
                  label: const Text('Join'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
