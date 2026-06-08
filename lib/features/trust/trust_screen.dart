import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/profile/profile_controller.dart';
import 'package:goodwill_circle/features/trust/trust_repository.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TrustScreen extends ConsumerStatefulWidget {
  const TrustScreen({super.key});

  @override
  ConsumerState<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends ConsumerState<TrustScreen> {
  final _codeController = TextEditingController();
  final _messageController = TextEditingController();
  TrustedInvite? _invite;
  ScamCheckup? _checkup;
  bool _isCreatingInvite = false;
  bool _isRedeeming = false;
  bool _isChecking = false;

  @override
  void dispose() {
    _codeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).profile;
    final trusted = profile?.isTrusted == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileControllerProvider.notifier).loadProfile();
          ref.invalidate(platformImpactProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 120,
          ),
          children: [
            const SectionHeader(title: 'Trust Center'),
            AppCard(
              color: trusted ? AppColors.yellowPale : AppColors.white,
              child: Row(
                children: [
                  Icon(
                    trusted ? Icons.verified_user : Icons.shield_outlined,
                    color: trusted ? Colors.green : AppColors.red,
                    size: 34,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trusted ? 'Trusted account' : 'Basic protection',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          trusted
                              ? profile?.trustNote ??
                                  'Your account has trusted connection signals that help others decide safely.'
                              : 'Complete verification or connect with trusted people to improve account trust.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Connect by QR'),
            AppCard(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_invite == null)
                    OutlinedButton.icon(
                      onPressed: _isCreatingInvite ? null : _createInvite,
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(
                        _isCreatingInvite ? 'Creating...' : 'Create QR invite',
                      ),
                    )
                  else ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        color: AppColors.white,
                        child: QrImageView(
                          data: _invite!.qrPayload,
                          version: QrVersions.auto,
                          size: 180,
                          gapless: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      _invite!.inviteCode,
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.titleSmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Invite code',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _isRedeeming ? null : _redeemInvite,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(_isRedeeming ? 'Connecting...' : 'Connect'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Scam Check'),
            AppCard(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Paste a request or message',
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _runScamCheck,
                    icon: const Icon(Icons.manage_search),
                    label: Text(_isChecking ? 'Checking...' : 'Check safety'),
                  ),
                  if (_checkup != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CheckupResult(checkup: _checkup!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Financial Help Verification'),
            AppCard(
              color: AppColors.yellowPale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Requests for financial help can be marked for extra review. Evidence photos are queued for server-side Reality Defender media checks, while account trust and scam signals stay visible to reviewers.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvite() async {
    setState(() => _isCreatingInvite = true);
    try {
      final invite = await ref.read(trustRepositoryProvider).createTrustedInvite();
      if (mounted) setState(() => _invite = invite);
    } catch (e) {
      _showSnack('Could not create QR invite: $e');
    } finally {
      if (mounted) setState(() => _isCreatingInvite = false);
    }
  }

  Future<void> _redeemInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isRedeeming = true);
    try {
      await ref.read(trustRepositoryProvider).redeemTrustedInvite(code);
      await ref.read(profileControllerProvider.notifier).loadProfile();
      _codeController.clear();
      _showSnack('Trusted connection added.');
    } catch (e) {
      _showSnack('Could not connect: $e');
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  Future<void> _runScamCheck() async {
    final message = _messageController.text.trim();
    if (message.length < 8) {
      _showSnack('Add a little more detail for the check.');
      return;
    }

    setState(() => _isChecking = true);
    try {
      final checkup = await ref.read(trustRepositoryProvider).runScamCheck(
            targetType: 'message',
            message: message,
          );
      if (mounted) setState(() => _checkup = checkup);
    } catch (e) {
      _showSnack('Safety check failed: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CheckupResult extends StatelessWidget {
  final ScamCheckup checkup;

  const _CheckupResult({required this.checkup});

  @override
  Widget build(BuildContext context) {
    final color = switch (checkup.status) {
      'blocked' => AppColors.red,
      'review' => AppColors.yellow,
      _ => Colors.green,
    };
    final title = switch (checkup.status) {
      'blocked' => 'High risk',
      'review' => 'Review before acting',
      _ => 'Looks low risk',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title - ${checkup.riskScore}/100',
              style: AppTypography.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            checkup.signals.isEmpty
                ? 'No common scam wording was detected. Still keep payment and identity checks inside the app.'
                : checkup.signals.join('\n'),
            style: AppTypography.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
