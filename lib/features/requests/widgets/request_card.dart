import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

class RequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onVolunteer;
  final VoidCallback onComplete;

  const RequestCard({
    super.key,
    required this.request,
    required this.onVolunteer,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCreator = currentUserId == request.creatorId;
    final isUrgent = request.goodwillReward >= 25;
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
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
}
