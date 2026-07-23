import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen shooting star animation overlay.
/// Display via [ShootingStarOverlay.show] for a ~2.8 second cinematic moment.
class ShootingStarOverlay extends StatefulWidget {
  final String wishText;
  final VoidCallback onComplete;

  const ShootingStarOverlay({
    super.key,
    required this.wishText,
    required this.onComplete,
  });

  /// Show the overlay as a full-screen route, then call [onComplete].
  static Future<void> show(
    BuildContext context, {
    required String wishText,
    required VoidCallback onComplete,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, _) => ShootingStarOverlay(
        wishText: wishText,
        onComplete: onComplete,
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    );
  }

  @override
  State<ShootingStarOverlay> createState() => _ShootingStarOverlayState();
}

class _ShootingStarOverlayState extends State<ShootingStarOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _starController;
  late final AnimationController _textController;
  late final AnimationController _exitController;

  late final Animation<double> _starProgress;
  late final Animation<double> _textOpacity;
  late final Animation<double> _exitOpacity;

  final Random _rng = Random(42);
  late final List<_StarParticle> _backgroundStars;

  @override
  void initState() {
    super.initState();

    // Seed background twinkling stars
    _backgroundStars = List.generate(80, (i) => _StarParticle(_rng));

    // Background slow twinkle
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Main shooting star trajectory (0.0 → 1.0 over 1.4s)
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _starProgress = CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    );

    // Wish text fade-in after star completes
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    // Exit fade-out
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitOpacity =
        Tween<double>(begin: 1.0, end: 0.0).animate(_exitController);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _starController.forward();
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await _exitController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _starController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (context, child) => Opacity(
        opacity: _exitOpacity.value,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF020A18),
                Color(0xFF06142B),
                Color(0xFF0C1F3F),
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Background twinkling stars ──────────────────────────
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: _BackgroundStarsPainter(
                      stars: _backgroundStars,
                      phase: _bgController.value,
                    ),
                  );
                },
              ),

              // ── Shooting star ────────────────────────────────────────
              AnimatedBuilder(
                animation: _starProgress,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: _ShootingStarPainter(
                      progress: _starProgress.value,
                    ),
                  );
                },
              ),

              // ── Wish text reveal ─────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '✦  YOUR WISH HAS BEEN HEARD  ✦',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF5C842),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '"${widget.wishText}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _PulsingStarRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing decorative stars ────────────────────────────────────────────────

class _PulsingStarRow extends StatefulWidget {
  @override
  State<_PulsingStarRow> createState() => _PulsingStarRowState();
}

class _PulsingStarRowState extends State<_PulsingStarRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + _ctrl.value * 0.6,
        child: const Text(
          '★  ★  ★',
          style: TextStyle(
            color: Color(0xFFF5C842),
            fontSize: 18,
            letterSpacing: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Background Stars Painter ─────────────────────────────────────────────────

class _StarParticle {
  final double x;
  final double y;
  final double radius;
  final double phaseOffset;

  _StarParticle(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        radius = rng.nextDouble() * 1.6 + 0.4,
        phaseOffset = rng.nextDouble();
}

class _BackgroundStarsPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double phase;

  _BackgroundStarsPainter({required this.stars, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final twinkle = (sin((phase + star.phaseOffset) * pi) * 0.5 + 0.5);
      paint.color = Colors.white.withOpacity(0.15 + twinkle * 0.55);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundStarsPainter old) =>
      old.phase != phase;
}

// ─── Shooting Star Painter ────────────────────────────────────────────────────

class _ShootingStarPainter extends CustomPainter {
  final double progress;

  _ShootingStarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Trajectory: bottom-left → upper-right diagonal
    final startX = size.width * 0.05;
    final startY = size.height * 0.75;
    final endX = size.width * 0.88;
    final endY = size.height * 0.15;

    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    // Tail length (fade out behind)
    const tailLength = 0.18;
    final tailStartT = (progress - tailLength).clamp(0.0, 1.0);
    final tailX = startX + (endX - startX) * tailStartT;
    final tailY = startY + (endY - startY) * tailStartT;

    // Draw glowing tail
    final tailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFF5C842).withOpacity(0.15),
          const Color(0xFFF5C842).withOpacity(0.7),
          Colors.white,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromPoints(
        Offset(tailX, tailY),
        Offset(currentX, currentY),
      ))
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(tailX, tailY), Offset(currentX, currentY), tailPaint);

    // Draw bright head
    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFF5C842).withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(currentX, currentY), 10, glowPaint);
    canvas.drawCircle(Offset(currentX, currentY), 4, headPaint);

    // Sparkle particles near head
    if (progress > 0.1) {
      _drawSparkles(canvas, Offset(currentX, currentY), progress);
    }
  }

  void _drawSparkles(Canvas canvas, Offset center, double t) {
    final rng = Random((t * 100).toInt());
    final sparkPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * 18 + 6;
      final sparkRadius = rng.nextDouble() * 1.4 + 0.4;
      canvas.drawCircle(
        Offset(
          center.dx + cos(angle) * dist,
          center.dy + sin(angle) * dist,
        ),
        sparkRadius,
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) => old.progress != progress;
}
