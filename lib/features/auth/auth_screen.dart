import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/widgets/brand_logo.dart';

enum _AuthMode { signUp, signIn }

class AuthScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final bool initialSignUp;

  const AuthScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialSignUp = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingPasswordReset = false;
  _AuthMode _mode = _AuthMode.signIn;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialSignUp ? _AuthMode.signUp : _AuthMode.signIn;
    _nameController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUp && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _authRedirectUrl('/auth'),
          data: {
            'full_name': _nameController.text.trim(),
            'avatar_url': '',
            'phone': _phoneController.text.trim(),
            'signup_source': 'phase_zero',
          },
        );
        if (mounted) {
          if (response.session != null) {
            try {
              await Supabase.instance.client.from('profiles').upsert({
                'id': response.user!.id,
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
              });
            } on PostgrestException {
              // Older Supabase schemas may not have the phone column yet.
            }
            await _repairCurrentProfile();
            if (!mounted) return;
            context.go('/app');
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created, but Supabase still requires email confirmation before sign in. Disable Confirm email in Supabase Auth to make signup optional.',
              ),
              backgroundColor: AppColors.red,
            ),
          );
          setState(() => _mode = _AuthMode.signIn);
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        await _repairCurrentProfile();
        if (mounted) {
          context.go('/app');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authErrorMessage(error.message)),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously(
        data: {'full_name': 'Guest helper', 'signup_source': 'guest'},
      );
      await _repairCurrentProfile();
      if (mounted) {
        context.go('/app');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authErrorMessage(error.message)),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Guest login is not enabled yet. Please sign up or sign in.',
            ),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithoutVerification() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your password first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _repairCurrentProfile();
      if (!mounted) return;
      context.go('/app');
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(error.message)),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _repairCurrentProfile() async {
    try {
      await Supabase.instance.client.rpc('repair_current_user_profile');
    } on PostgrestException {
      // Week 10 schema may not be applied yet; auth should still continue.
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your account email first.')),
      );
      return;
    }

    setState(() => _isSendingPasswordReset = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: _authRedirectUrl('/reset-password'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(error.message)),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingPasswordReset = false);
    }
  }

  String _authErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('anonymous') || normalized.contains('disabled')) {
      return 'Guest login is not enabled yet. Please sign up or sign in.';
    }
    if (normalized.contains('rate') && normalized.contains('email')) {
      return 'Supabase has temporarily limited confirmation emails for this project. Please wait a few minutes, or sign in if your account is already confirmed.';
    }
    if (normalized.contains('429') ||
        normalized.contains('over email send rate limit') ||
        normalized.contains('security purposes')) {
      return 'Supabase is rate-limiting confirmation emails for this project. Wait a few minutes, or configure production SMTP in Supabase Auth.';
    }
    if (normalized.contains('email_address_invalid')) {
      return 'Supabase rejected that email address. Use a real inbox address.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Supabase is still requiring email confirmation. Disable Confirm email in Supabase Auth to allow sign in without verification.';
    }
    if (normalized.contains('expired') ||
        normalized.contains('otp expired') ||
        normalized.contains('token expired')) {
      return 'That code or link has expired. Please request a new one.';
    }
    if ((normalized.contains('otp') || normalized.contains('token')) &&
        (normalized.contains('invalid') || normalized.contains('not found'))) {
      return 'That code or link is invalid. Please check it or request a new one.';
    }
    if (normalized.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (normalized.contains('already registered') ||
        normalized.contains('already exists') ||
        normalized.contains('user already')) {
      return 'An account already exists for this email. Please sign in instead.';
    }
    return message;
  }

  String _authRedirectUrl(String path) {
    final base = Uri.base;
    return base.replace(path: path, query: '', fragment: '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: const BrandLogo(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Open Goodwill Circle.',
                  style: AppTypography.textTheme.displayLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isSignUp
                      ? 'Create an account to ask, help, and pass goodwill forward.'
                      : 'Sign in, create an account, or continue as a guest.',
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMid,
                  ),
                ),
                if (currentUser != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.tan1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Signed in as ${currentUser.email ?? 'guest'}',
                          style: AppTypography.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.go('/app'),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Open app'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        setState(() => _isLoading = true);
                                        await Supabase.instance.client.auth
                                            .signOut();
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                icon: const Icon(Icons.logout, size: 18),
                                label: const Text('Sign out'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _AuthChoiceButton(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Sign up',
                        selected: _mode == _AuthMode.signUp,
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _mode = _AuthMode.signUp),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _AuthChoiceButton(
                        icon: Icons.login_outlined,
                        label: 'Sign in',
                        selected: _mode == _AuthMode.signIn,
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _mode = _AuthMode.signIn),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  onFieldSubmitted: (_) => _isLoading ? null : _authenticate(),
                ),
                if (!_isSignUp) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSendingPasswordReset
                          ? null
                          : _sendPasswordResetEmail,
                      child: Text(
                        _isSendingPasswordReset
                            ? 'Sending reset...'
                            : 'Forgot password?',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Sign in'),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithoutVerification,
                    icon: const Icon(Icons.no_accounts_outlined),
                    label: const Text('Sign in without verification'),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Continue as guest'),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _AuthChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _AuthChoiceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.textDark;
    final background = selected ? AppColors.red : AppColors.white;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: foreground),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: BorderSide(color: selected ? AppColors.red : AppColors.tan1),
      ),
    );
  }
}
