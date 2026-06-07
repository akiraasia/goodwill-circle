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
                    const SizedBox(height: AppSpacing.xs),
                    _VerificationChip(
                      status: profile.verificationStatus,
                      accountType: profile.accountType,
                    ),
                    if (profile.organizationName != null &&
                        profile.organizationName!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        profile.organizationName!,
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          color: AppColors.textMid,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
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

              const SectionHeader(title: 'Trust & Verification'),
              AppCard(
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          profile.isVerified
                              ? Icons.verified
                              : Icons.verified_outlined,
                          color: profile.isVerified
                              ? Colors.green
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _verificationTitle(profile.verificationStatus),
                            style: AppTypography.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _verificationMessage(profile.verificationStatus),
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                    if (!profile.isVerified &&
                        !profile.isVerificationPending) ...[
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => _showVerificationDialog(profile),
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: const Text('Request verification'),
                      ),
                    ],
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

  Future<void> _showVerificationDialog(dynamic profile) async {
    final organizationController = TextEditingController(
      text: profile.organizationName ?? '',
    );
    final noteController = TextEditingController();
    var accountType = profile.accountType as String;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNgo = accountType == 'ngo';
          return AlertDialog(
            title: const Text('Request verification'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'individual',
                        label: Text('Person'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: 'ngo',
                        label: Text('NGO'),
                        icon: Icon(Icons.apartment),
                      ),
                    ],
                    selected: {accountType},
                    onSelectionChanged: (selection) {
                      setDialogState(() => accountType = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isNgo)
                    TextField(
                      controller: organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Organization name',
                      ),
                    ),
                  if (isNgo) const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Verification note',
                      hintText:
                          'Share website, registration, college, or local reference details.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (submitted != true) {
      organizationController.dispose();
      noteController.dispose();
      return;
    }

    final note = noteController.text.trim();
    final organization = organizationController.text.trim();
    organizationController.dispose();
    noteController.dispose();

    if (note.length < 12) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a little more verification detail.')),
      );
      return;
    }

    await ref.read(profileControllerProvider.notifier).requestVerification(
          accountType: accountType,
          organizationName: accountType == 'ngo' ? organization : null,
          note: note,
        );

    if (!mounted) return;
    final error = ref.read(profileControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Verification request submitted.'
              : 'Verification request failed: $error',
        ),
      ),
    );
  }

  String _verificationTitle(String status) {
    switch (status) {
      case 'verified':
        return 'Verified profile';
      case 'pending':
        return 'Verification under review';
      case 'rejected':
        return 'Verification needs more detail';
      default:
        return 'Unverified profile';
    }
  }

  String _verificationMessage(String status) {
    switch (status) {
      case 'verified':
        return 'This profile has passed a manual trust review.';
      case 'pending':
        return 'Your details are waiting for a reviewer.';
      case 'rejected':
        return 'Submit stronger identity, organization, or community reference details.';
      default:
        return 'Verified profiles help volunteers, NGOs, and donors decide who to trust.';
    }
  }
}

class _VerificationChip extends StatelessWidget {
  final String status;
  final String accountType;

  const _VerificationChip({required this.status, required this.accountType});

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified';
    final isPending = status == 'pending';
    final label = isVerified
        ? accountType == 'ngo'
            ? 'Verified NGO'
            : 'Verified'
        : isPending
        ? 'Pending review'
        : 'Unverified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withValues(alpha: 0.12)
            : AppColors.white,
        border: Border.all(
          color: isVerified ? Colors.green : AppColors.tan1,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.verified_outlined,
            size: 15,
            color: isVerified ? Colors.green : AppColors.textLight,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.textTheme.labelSmall),
        ],
      ),
    );
  }
}
