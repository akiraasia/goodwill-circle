import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/widgets/brand_logo.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  bool _hasRecoverySession =
      Supabase.instance.client.auth.currentSession != null;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery ||
          state.event == AuthChangeEvent.signedIn) {
        setState(() => _hasRecoverySession = state.session != null);
      }
    });
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_hasRecoverySession) {
      _showError('Open the latest password reset link from your email.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go('/auth');
    } on AuthException catch (error) {
      _showError(_authErrorMessage(error.message));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  String _authErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('expired')) {
      return 'This reset link has expired. Request a new password reset email.';
    }
    if (normalized.contains('session') ||
        normalized.contains('jwt') ||
        normalized.contains('token')) {
      return 'This reset link is no longer valid. Request a new password reset email.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  AppSpacing.xl * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BrandLogo(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Reset password',
                  style: AppTypography.textTheme.displayLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _hasRecoverySession
                      ? 'Choose a new password for your Goodwill Circle account.'
                      : 'Open the latest reset link from your email to continue.',
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _passwordController,
                  enabled: _hasRecoverySession && !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: _hasRecoverySession && !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  obscureText: true,
                  onFieldSubmitted: (_) =>
                      _isLoading ? null : _updatePassword(),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _hasRecoverySession && !_isLoading
                      ? _updatePassword
                      : null,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(_isLoading ? 'Updating...' : 'Update password'),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => context.go('/auth'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
