import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/profile/profile_controller.dart';
import 'package:goodwill_circle/features/gamification/gamification_controller.dart';
import 'package:goodwill_circle/features/gamification/character_system.dart';
import 'package:goodwill_circle/features/profile/widgets/impact_graph.dart';
import 'package:goodwill_circle/features/profile/widgets/badges_section.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/shared/widgets/stat_card.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final gamificationState = ref.watch(gamificationControllerProvider);

    if (profileState.isLoading && profileState.profile == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileState.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Error: ${profileState.error}')),
      );
    }

    final profile = profileState.profile;
    final stats = profileState.stats;

    if (profile == null || stats == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Profile not found.')),
      );
    }

    final currentLevel = CharacterSystem.getLevelForScore(stats.impactScore);
    final progress = currentLevel.getProgress(stats.impactScore);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileControllerProvider.notifier).loadProfile();
          await ref.read(gamificationControllerProvider.notifier).loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: 120, // space for bottom nav
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Profile Card
              AppCard(
                color: AppColors.yellowPale,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.yellow,
                      backgroundImage:
                          profile.photoUrl != null &&
                              profile.photoUrl!.isNotEmpty
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child:
                          profile.photoUrl == null || profile.photoUrl!.isEmpty
                          ? Text(
                              profile.name?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: AppTypography.textTheme.displayMedium,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      profile.name ?? 'New User',
                      style: AppTypography.textTheme.headlineLarge,
                    ),
                    Text(
                      currentLevel.title,
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.tan3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: progress),
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 8,
                                    backgroundColor: AppColors.tan1,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.red,
                                        ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${(progress * 100).toInt()}% to next level',
                            style: AppTypography.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Passport Section
              const SectionHeader(title: 'Goodwill Passport'),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Credit',
                      value: '${stats.credits}',
                      backgroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatCard(
                      label: 'Impact',
                      value: '${stats.impactScore}',
                      backgroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Analytics Section
              const SectionHeader(title: 'Analytics'),
              ImpactGraph(stats: stats),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: 'Earned', value: '${stats.creditsEarned}'),
                  StatCard(label: 'Donated', value: '${stats.creditsDonated}'),
                  StatCard(
                    label: 'Supported',
                    value: '${stats.campaignsSupported}',
                  ),
                  StatCard(label: 'Helped', value: '${stats.helpCount}'),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Badges & Chains'),
              BadgesSection(
                stats: stats,
                gamificationState: gamificationState,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
