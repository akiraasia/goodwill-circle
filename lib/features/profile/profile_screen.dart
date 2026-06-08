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
import 'package:goodwill_circle/shared/services/media_upload_service.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool promptVerification;

  const ProfileScreen({super.key, this.promptVerification = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _verificationPromptShown = false;
  bool _isUploadingPublicPhoto = false;

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
    final displayName = _displayName(profile);

    if (widget.promptVerification &&
        !_verificationPromptShown &&
        !profile.isVerified &&
        !profile.isVerificationPending) {
      _verificationPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showVerificationDialog(profile);
      });
    }

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
                              displayName.substring(0, 1).toUpperCase(),
                              style: AppTypography.textTheme.displayMedium,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
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

              const SectionHeader(title: 'Profile Photo'),
              AppCard(
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          profile.profilePhotoPublic
                              ? Icons.public_outlined
                              : Icons.lock_outline,
                          color: profile.profilePhotoPublic
                              ? Colors.green
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            profile.profilePhotoPublic
                                ? 'Public on your account'
                                : 'Private to your profile',
                            style: AppTypography.textTheme.titleMedium,
                          ),
                        ),
                        Switch(
                          value: profile.profilePhotoPublic,
                          onChanged: (value) => ref
                              .read(profileControllerProvider.notifier)
                              .updateProfile(profilePhotoPublic: value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Anonymous confessions never show your name or account photo.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _isUploadingPublicPhoto
                          ? null
                          : _pickPublicProfilePhoto,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(
                        _isUploadingPublicPhoto
                            ? 'Uploading...'
                            : profile.photoUrl == null ||
                                  profile.photoUrl!.isEmpty
                            ? 'Upload account photo'
                            : 'Change account photo',
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
              BadgesSection(stats: stats, gamificationState: gamificationState),
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
    final linkedinController = TextEditingController();
    final phoneController = TextEditingController(text: profile.phone ?? '');
    final otpController = TextEditingController();
    var accountType = profile.accountType as String;
    var sendingOtp = false;
    var verifyingOtp = false;
    var uploadingPhoto = false;
    String? profilePhotoUrl;
    var phoneOtpVerified =
        Supabase.instance.client.auth.currentUser?.phoneConfirmedAt != null;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNgo = accountType == 'ngo';
          final hasPhoto = profilePhotoUrl?.isNotEmpty == true;
          return AlertDialog(
            title: const Text('Strong verification'),
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
                    controller: linkedinController,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn profile URL (optional)',
                      prefixIcon: Icon(Icons.link),
                      hintText: 'https://www.linkedin.com/in/your-name',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: uploadingPhoto
                        ? null
                        : () async {
                            setDialogState(() => uploadingPhoto = true);
                            try {
                              final url =
                                  await MediaUploadService.pickAndUploadImage(
                                    folder: 'profiles',
                                    bucket: 'goodwill-verification',
                                    returnPublicUrl: false,
                                  );
                              if (url != null) {
                                setDialogState(() => profilePhotoUrl = url);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not upload photo: $e'),
                                  ),
                                );
                              }
                            } finally {
                              setDialogState(() => uploadingPhoto = false);
                            }
                          },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      uploadingPhoto
                          ? 'Uploading...'
                          : hasPhoto
                          ? 'Replace private verification photo'
                          : 'Upload private verification photo',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone number for OTP',
                      prefixIcon: Icon(Icons.phone_iphone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: sendingOtp
                              ? null
                              : () async {
                                  final phone = phoneController.text.trim();
                                  final phoneError = _phoneValidationError(
                                    phone,
                                  );
                                  if (phoneError != null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(phoneError)),
                                      );
                                    }
                                    return;
                                  }
                                  setDialogState(() => sendingOtp = true);
                                  try {
                                    await Supabase.instance.client.auth
                                        .updateUser(
                                          UserAttributes(phone: phone),
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Phone OTP sent.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _friendlyOtpError(e, 'send'),
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    setDialogState(() => sendingOtp = false);
                                  }
                                },
                          icon: const Icon(Icons.sms_outlined, size: 18),
                          label: Text(sendingOtp ? 'Sending...' : 'Send OTP'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpController,
                          decoration: const InputDecoration(
                            labelText: 'OTP code',
                            prefixIcon: Icon(Icons.password_outlined),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: verifyingOtp
                            ? null
                            : () async {
                                final phone = phoneController.text.trim();
                                final token = otpController.text.trim();
                                final phoneError = _phoneValidationError(phone);
                                if (phoneError != null || token.isEmpty) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          phoneError ?? 'Enter the OTP code.',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                setDialogState(() => verifyingOtp = true);
                                try {
                                  await Supabase.instance.client.auth.verifyOTP(
                                    phone: phone,
                                    token: token,
                                    type: OtpType.phoneChange,
                                  );
                                  setDialogState(() => phoneOtpVerified = true);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _friendlyOtpError(e, 'verify'),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  setDialogState(() => verifyingOtp = false);
                                }
                              },
                        child: Text(verifyingOtp ? '...' : 'Verify'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _VerificationRequirementRow(
                    icon: Icons.mark_email_read_outlined,
                    label:
                        Supabase
                                .instance
                                .client
                                .auth
                                .currentUser
                                ?.emailConfirmedAt !=
                            null
                        ? 'Email confirmed'
                        : 'Confirm your email before submitting',
                    complete:
                        Supabase
                            .instance
                            .client
                            .auth
                            .currentUser
                            ?.emailConfirmedAt !=
                        null,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _VerificationRequirementRow(
                    icon: Icons.phone_android_outlined,
                    label: phoneOtpVerified
                        ? 'Phone OTP verified'
                        : 'Phone OTP must be verified',
                    complete: phoneOtpVerified,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _VerificationRequirementRow(
                    icon: Icons.image_search_outlined,
                    label: hasPhoto
                        ? 'Private photo will be checked by Reality Defender'
                        : 'Upload a private verification photo',
                    complete: hasPhoto,
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
      linkedinController.dispose();
      phoneController.dispose();
      otpController.dispose();
      return;
    }

    final organization = organizationController.text.trim();
    final linkedin = linkedinController.text.trim();
    final phone = phoneController.text.trim();
    final photoUrl = profilePhotoUrl?.trim();
    final user = Supabase.instance.client.auth.currentUser;
    organizationController.dispose();
    linkedinController.dispose();
    phoneController.dispose();
    otpController.dispose();

    if (user?.emailConfirmedAt == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirm your email before verification.'),
        ),
      );
      return;
    }
    if (user?.phoneConfirmedAt == null && !phoneOtpVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify your phone with OTP first.')),
      );
      return;
    }
    final phoneError = _phoneValidationError(phone);
    if (phoneError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(phoneError)));
      return;
    }
    if (linkedin.isNotEmpty && !_isLinkedInUrl(linkedin)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid LinkedIn URL or leave it blank.'),
        ),
      );
      return;
    }
    if (photoUrl == null || photoUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload a private verification photo first.'),
        ),
      );
      return;
    }

    await ref
        .read(profileControllerProvider.notifier)
        .requestVerification(
          accountType: accountType,
          organizationName: accountType == 'ngo' ? organization : null,
          linkedinUrl: linkedin.isEmpty ? null : linkedin,
          phoneNumber: phone.isEmpty ? null : phone,
          profilePhotoUrl: photoUrl,
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

  Future<void> _pickPublicProfilePhoto() async {
    setState(() => _isUploadingPublicPhoto = true);
    try {
      final url = await MediaUploadService.pickAndUploadImage(
        folder: 'profiles',
      );
      if (url == null) return;
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(photoUrl: url, profilePhotoPublic: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPublicPhoto = false);
    }
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

  bool _isLinkedInUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return (host == 'linkedin.com' || host.endsWith('.linkedin.com')) &&
        uri.pathSegments.isNotEmpty;
  }

  String _friendlyOtpError(Object error, String action) {
    final message = error.toString();
    final normalized = message.toLowerCase();
    if (normalized.contains('sms provider') ||
        normalized.contains('unable to get sms') ||
        normalized.contains('unexpected_failure')) {
      return 'Supabase SMS is not configured yet. Enable a real SMS provider in Supabase Auth to send phone OTP.';
    }
    if (normalized.contains('expired')) {
      return 'That OTP has expired. Request a new code.';
    }
    if (normalized.contains('invalid') || normalized.contains('token')) {
      return 'That OTP code is invalid. Check the code or request a new one.';
    }
    return action == 'verify'
        ? 'OTP verification failed: $message'
        : 'Could not send OTP: $message';
  }

  String? _phoneValidationError(String phone) {
    if (phone.isEmpty) return 'Enter your phone number.';
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      return 'Use international format, for example +919876543210.';
    }
    return null;
  }

  String _displayName(dynamic profile) {
    final profileName = (profile.name as String?)?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final user = Supabase.instance.client.auth.currentUser;
    final metadataName =
        (user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'])
            ?.toString()
            .trim();
    if (metadataName != null && metadataName.isNotEmpty) return metadataName;

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'Goodwill member';
  }
}

class _VerificationRequirementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool complete;

  const _VerificationRequirementRow({
    required this.icon,
    required this.label,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          complete ? Icons.check_circle : icon,
          color: complete ? Colors.green : AppColors.textLight,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: complete ? AppColors.textDark : AppColors.textMid,
            ),
          ),
        ),
      ],
    );
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
        border: Border.all(color: isVerified ? Colors.green : AppColors.tan1),
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
