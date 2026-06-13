import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/campaigns/models/campaign.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/core/theme/app_icons.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
    this.onJoin,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${campaign.currentAmount} / ${campaign.goalAmount} credits',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${campaign.supportersCount} Supporters',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed: campaign.isJoined ? null : onJoin,
                icon: Icon(
                  campaign.isJoined ? Icons.check : Icons.group_add_outlined,
                  size: 16,
                ),
                label: Text(campaign.isJoined ? 'Joined' : 'Join'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
