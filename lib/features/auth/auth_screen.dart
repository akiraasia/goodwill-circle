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
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
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
              await Supabase.instance.client
                  .from('profiles')
                  .update({'phone': _phoneController.text.trim()})
                  .eq('id', response.user!.id);
            } on PostgrestException {
              // Older Supabase schemas may not have the phone column yet.
            }
            if (!mounted) return;
            context.go('/trust');
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Check your email to confirm your account, then sign in.',
              ),
            ),
          );
          setState(() {
            _mode = _AuthMode.signIn;
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
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
        data: {
          'full_name': 'Guest helper',
          'signup_source': 'guest',
        },
      );
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  String _authErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('anonymous') || normalized.contains('disabled')) {
      return 'Guest login is not enabled yet. Please sign up or sign in.';
    }
    if (normalized.contains('rate') && normalized.contains('email')) {
      return 'Supabase has temporarily limited confirmation emails for this project. Please wait a few minutes, or sign in if your account is already confirmed.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (normalized.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
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
                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<_AuthMode>(
                  segments: const [
                    ButtonSegment(
                      value: _AuthMode.signUp,
                      icon: Icon(Icons.person_add_alt_1_outlined),
                      label: Text('Sign up'),
                    ),
                    ButtonSegment(
                      value: _AuthMode.signIn,
                      icon: Icon(Icons.login_outlined),
                      label: Text('Sign in'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _isLoading
                      ? null
                      : (selection) {
                          setState(() => _mode = selection.first);
                        },
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
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  child: const Text(
                    'Continue as guest',
                  ),
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
