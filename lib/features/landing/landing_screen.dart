import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/shared/widgets/brand_logo.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _reserveSpot() {
    final uri = Uri(
      path: '/auth',
      queryParameters: {
        'mode': 'signup',
        if (_nameController.text.trim().isNotEmpty)
          'name': _nameController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
      },
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _hasCurrentSession();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const BrandLogo(),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/auth?mode=signin'),
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: () =>
                          context.go(signedIn ? '/app' : '/auth?mode=signup'),
                      child: Text(signedIn ? 'Open app' : 'Open app'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final text = _HeroCopy(
                      wide: wide,
                      nameController: _nameController,
                      emailController: _emailController,
                      onReserveSpot: _reserveSpot,
                    );
                    final image = const _HeroImage();

                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text,
                          const SizedBox(height: AppSpacing.xl),
                          image,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: 48),
                        Expanded(child: image),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _WhatSection()),
            const SliverToBoxAdapter(child: _HowSection()),
            const SliverToBoxAdapter(child: _ContrastSection()),
            const SliverToBoxAdapter(child: _ChainsSection()),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }

  bool _hasCurrentSession() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }
}

class _HeroCopy extends StatelessWidget {
  final bool wide;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onReserveSpot;

  const _HeroCopy({
    required this.wide,
    required this.nameController,
    required this.emailController,
    required this.onReserveSpot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tan1.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRE-LAUNCH · PHASE 0',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Kindness, '),
              TextSpan(
                text: 'in chains.',
                style: TextStyle(
                  color: AppColors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          style:
              (wide
                      ? AppTypography.textTheme.displayLarge
                      : AppTypography.textTheme.headlineLarge)
                  ?.copyWith(
                    fontFamily: 'Georgia',
                    fontSize: wide ? 72 : 48,
                    height: 1.05,
                    fontWeight: FontWeight.w400,
                  ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Goodwill Circle is a self-sustaining ecosystem where one act of help sparks the next. Not likes. Not followers. Real help, traveling person to person.',
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMid,
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: wide ? 420 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Your name (optional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Your name (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: onReserveSpot,
                child: const Text('Reserve my spot'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No spam. One email when early access opens.',
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'goodwill-kindred-loop-main/src/assets/hero-hands.jpg',
        fit: BoxFit.cover,
        height: 420,
        width: double.infinity,
      ),
    );
  }
}

class _WhatSection extends StatelessWidget {
  const _WhatSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 72,
      ),
      decoration: BoxDecoration(
        color: AppColors.tan1.withValues(alpha: 0.35),
        border: const Border.symmetric(
          horizontal: BorderSide(color: AppColors.tan1),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            Text(
              'WHAT IS GOODWILL CIRCLE',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'A network built on help given, not attention earned.',
              style: AppTypography.textTheme.displayMedium?.copyWith(
                fontFamily: 'Georgia',
                height: 1.12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Anyone can ask for help with school, work, food, health, money, a place to stay, or just someone to listen. Anyone can give help.',
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: AppColors.textMid,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowSection extends StatelessWidget {
  const _HowSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        '01',
        'Ask or offer',
        'Post a request, or browse the ones nearby. First request is always free.',
      ),
      (
        '02',
        'Help happens',
        'Someone steps in. You can stay public, or keep it fully anonymous.',
      ),
      (
        '03',
        'Pay it forward',
        'Helping earns credits. Credits fund someone else’s ask. The chain grows.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 72,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW PAY-IT-FORWARD WORKS',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Three steps. No middlemen.',
            style: AppTypography.textTheme.displayMedium?.copyWith(
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final cards = steps
                  .map(
                    (step) => Expanded(
                      child: _StepCard(
                        number: step.$1,
                        title: step.$2,
                        body: step.$3,
                      ),
                    ),
                  )
                  .toList();

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cards[0],
                    const SizedBox(width: AppSpacing.md),
                    cards[1],
                    const SizedBox(width: AppSpacing.md),
                    cards[2],
                  ],
                );
              }

              return Column(
                children: steps
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _StepCard(
                          number: step.$1,
                          title: step.$2,
                          body: step.$3,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.tan1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: AppTypography.textTheme.displayMedium?.copyWith(
              color: AppColors.red.withValues(alpha: 0.7),
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContrastSection extends StatelessWidget {
  const _ContrastSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.textDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 72,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(light: true),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'The opposite of social media.',
            style: AppTypography.textTheme.displayMedium?.copyWith(
              color: AppColors.cream,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ContrastRow(
            label: 'Currency',
            old: 'Likes, follows, outrage',
            now: 'Help completed, lives touched',
          ),
          _ContrastRow(
            label: 'Feed',
            old: 'What’s loudest',
            now: 'What’s kindest',
          ),
          _ContrastRow(
            label: 'End state',
            old: 'Doomscroll',
            now: 'Goodwill chain',
          ),
        ],
      ),
    );
  }
}

class _ContrastRow extends StatelessWidget {
  final String label;
  final String old;
  final String now;

  const _ContrastRow({
    required this.label,
    required this.old,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.cream,
                fontFamily: 'Georgia',
              ),
            ),
          ),
          Expanded(
            child: Text(
              old,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.cream.withValues(alpha: 0.55),
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.cream.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: Text(
              now,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainsSection extends StatelessWidget {
  const _ChainsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 72,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WHY GOODWILL CHAINS MATTER',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'One act of help is a story. A thousand is a movement.',
                style: AppTypography.textTheme.displayMedium?.copyWith(
                  fontFamily: 'Georgia',
                  height: 1.12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'When A helps B, and B helps C, and C helps D, we trace it. You can see the chain of everyone your kindness touched.',
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMid,
                  height: 1.55,
                ),
              ),
            ],
          );
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'goodwill-kindred-loop-main/src/assets/chain.jpg',
              fit: BoxFit.cover,
              height: 360,
              width: double.infinity,
            ),
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.xl),
                image,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 48),
              Expanded(child: image),
            ],
          );
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.tan1)),
      ),
      child: Text(
        'Goodwill Circle — Phase 0',
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textLight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
