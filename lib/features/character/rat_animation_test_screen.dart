import 'package:flutter/material.dart';

import 'goodwill_rat.dart';
import 'rat_animation.dart';
import 'rat_controller.dart';

/// Development-only screen for manually checking every public animation.
class RatAnimationTestScreen extends StatefulWidget {
  const RatAnimationTestScreen({super.key});

  @override
  State<RatAnimationTestScreen> createState() => _RatAnimationTestScreenState();
}

class _RatAnimationTestScreenState extends State<RatAnimationTestScreen> {
  late final RatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RatController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goodwill Rat animation test')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EA),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SizedBox(
                  height: 300,
                  child: GoodwillRat(controller: _controller),
                ),
              ),
              const SizedBox(height: 18),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Text(
                  _controller.currentAnimation.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce motion'),
                  subtitle: const Text(
                    'Keep state changes while reducing movement and particles.',
                  ),
                  value: _controller.reduceMotion,
                  onChanged: _controller.setReduceMotion,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final animation in RatAnimation.values)
                    OutlinedButton(
                      onPressed: () => _controller.play(animation),
                      child: Text(animation.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
