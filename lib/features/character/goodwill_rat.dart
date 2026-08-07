import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'rat_animation.dart';
import 'rat_config.dart';
import 'rat_controller.dart';
import 'rat_part.dart';

/// A reusable, vector-only Goodwill Circle mascot.
///
/// The SVG files are deliberately rendered as separate layers from the
/// project's `character/` folder. They all share the same 1254 square viewBox,
/// so a full-size Stack preserves the source artwork's exact proportions.
class GoodwillRat extends StatefulWidget {
  const GoodwillRat({
    super.key,
    this.controller,
    this.reduceMotion = false,
    this.semanticsLabel = RatConfig.semanticsLabel,
  });

  final RatController? controller;
  final bool reduceMotion;
  final String semanticsLabel;

  @override
  State<GoodwillRat> createState() => _GoodwillRatState();
}

class _GoodwillRatState extends State<GoodwillRat>
    with SingleTickerProviderStateMixin {
  late RatController _controller;
  late bool _ownsController;
  late CurvedAnimation _eased;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? RatController();
    _controller.attach(this);
    _controller.setReduceMotion(widget.reduceMotion);
    _eased = CurvedAnimation(
      parent: _controller.animation,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant GoodwillRat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _eased.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? RatController();
      _controller.attach(this);
      _eased = CurvedAnimation(
        parent: _controller.animation,
        curve: Curves.easeInOut,
      );
    }
    _controller.setReduceMotion(widget.reduceMotion);
  }

  @override
  void dispose() {
    _eased.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : double.infinity;
          final maxHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : double.infinity;
          final dimension = math.min(maxWidth, maxHeight);
          final size = dimension.isFinite && dimension > 0
              ? dimension
              : RatConfig.defaultSize;

          return SizedBox.square(
            dimension: size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = Tween<double>(
                  begin: 0,
                  end: 1,
                ).evaluate(_eased);
                final pose = _RatPose.from(
                  _controller.currentAnimation,
                  progress,
                  reduceMotion: _controller.reduceMotion,
                );
                return _RatArtwork(pose: pose, size: size);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RatArtwork extends StatelessWidget {
  const _RatArtwork({required this.pose, required this.size});

  final _RatPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final unit = size / RatConfig.artboardSize;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: <Widget>[
        for (final definition in RatParts.ordered)
          Positioned.fill(
            child: _RatLayer(definition: definition, pose: pose, unit: unit),
          ),
        if (pose.particles > 0 || pose.glow > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RatParticlesPainter(
                  progress: pose.progress,
                  particles: pose.particles,
                  glow: pose.glow,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RatLayer extends StatelessWidget {
  const _RatLayer({
    required this.definition,
    required this.pose,
    required this.unit,
  });

  final RatPartDefinition definition;
  final _RatPose pose;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final part = definition.part;
    final transform = pose.transformFor(part);
    return Transform.translate(
      offset: Offset(0, transform.translateY * unit),
      child: Transform.rotate(
        angle: transform.rotation,
        alignment: definition.pivotAlignment,
        child: Transform.scale(
          scale: transform.scale,
          alignment: definition.pivotAlignment,
          child: SvgPicture.asset(
            definition.assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticsLabel: null,
          ),
        ),
      ),
    );
  }
}

class _RatTransform {
  const _RatTransform({this.translateY = 0, this.rotation = 0, this.scale = 1});

  final double translateY;
  final double rotation;
  final double scale;
}

class _RatPose {
  const _RatPose({
    required this.progress,
    this.bodyScale = 1,
    this.bodyY = 0,
    this.headScale = 1,
    this.headY = 0,
    this.headRotation = 0,
    this.earRotation = 0,
    this.tailRotation = 0,
    this.leftArmRotation = 0,
    this.rightHandRotation = 0,
    this.leftFootY = 0,
    this.rightFootY = 0,
    this.eyeScale = 1,
    this.mouthY = 0,
    this.glow = 0,
    this.particles = 0,
  });

  final double progress;
  final double bodyScale;
  final double bodyY;
  final double headScale;
  final double headY;
  final double headRotation;
  final double earRotation;
  final double tailRotation;
  final double leftArmRotation;
  final double rightHandRotation;
  final double leftFootY;
  final double rightFootY;
  final double eyeScale;
  final double mouthY;
  final double glow;
  final double particles;

  static _RatPose _fromAnimation(
    RatAnimation animation,
    double progress, {
    required bool reduceMotion,
  }) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    final triangle = _triangle(t);
    final soft = math.sin(math.pi * t);
    final motion = reduceMotion ? 0.35 : 1.0;

    switch (animation) {
      case RatAnimation.idle:
        final delayedHead = _triangle((t - 0.08 + 1) % 1);
        return _RatPose(
          progress: t,
          bodyScale: 1 + RatConfig.idleBreathScale * triangle * motion,
          bodyY: -RatConfig.idleBodyTravel * triangle * motion,
          headY: -RatConfig.idleHeadTravel * delayedHead * motion,
          earRotation: 0.012 * math.sin(t * math.pi * 2) * motion,
          tailRotation:
              RatConfig.idleTailRotation * math.sin(t * math.pi * 2) * motion,
        );
      case RatAnimation.blink:
        return _RatPose(
          progress: t,
          eyeScale: 1 - triangle,
          headY: -0.5 * soft * motion,
        );
      case RatAnimation.happy:
        return _RatPose(
          progress: t,
          bodyScale: 1 + 0.012 * soft * motion,
          bodyY: -8 * soft * motion,
          headY: -9 * soft * motion,
          headRotation: -0.025 * soft * motion,
          leftArmRotation: -0.08 * soft * motion,
          rightHandRotation: 0.08 * soft * motion,
          mouthY: -2.5 * soft * motion,
        );
      case RatAnimation.wave:
        final wave = math.sin(math.pi * t);
        final forearm = math.sin(t * math.pi * 4) * wave;
        return _RatPose(
          progress: t,
          bodyY: -3 * wave * motion,
          headY: -3 * wave * motion,
          rightHandRotation: (-0.42 * wave + 0.12 * forearm) * motion,
          leftArmRotation: -0.03 * wave * motion,
        );
      case RatAnimation.taskComplete:
        final jump = math.sin(math.pi * t);
        final anticipation = math.sin(math.pi * math.min(t * 2, 1));
        return _RatPose(
          progress: t,
          bodyScale: 1 + (0.018 * jump - 0.008 * anticipation) * motion,
          bodyY: (-14 * jump + 3 * anticipation) * motion,
          headY: -11 * jump * motion,
          headScale: 1 + 0.008 * jump * motion,
          leftArmRotation: -0.22 * jump * motion,
          rightHandRotation: 0.24 * jump * motion,
          mouthY: -4 * jump * motion,
          particles: reduceMotion ? 0 : 0.6 * jump,
        );
      case RatAnimation.helpComplete:
        final warm = math.sin(math.pi * t);
        return _RatPose(
          progress: t,
          bodyScale: 1 + 0.014 * warm * motion,
          bodyY: -10 * warm * motion,
          headY: -8 * warm * motion,
          leftArmRotation: 0.16 * warm * motion,
          rightHandRotation: -0.18 * warm * motion,
          mouthY: -3.5 * warm * motion,
          glow: reduceMotion ? 0.1 * warm : 0.3 * warm,
          particles: reduceMotion ? 0 : 0.9 * warm,
        );
      case RatAnimation.virtueGrowth:
        final growth = math.sin(math.pi * t);
        return _RatPose(
          progress: t,
          bodyScale: 1 + 0.025 * growth * motion,
          headScale: 1 + 0.012 * growth * motion,
          bodyY: -4 * growth * motion,
          headY: -6 * growth * motion,
          headRotation: -0.018 * growth * motion,
          leftArmRotation: -0.12 * growth * motion,
          rightHandRotation: 0.12 * growth * motion,
          glow: reduceMotion ? 0.12 * growth : 0.45 * growth,
          particles: reduceMotion ? 0 : 0.8 * growth,
        );
      case RatAnimation.milestone:
        final celebration = math.sin(math.pi * t);
        final squash = math.sin(math.pi * math.min(t * 2, 1));
        return _RatPose(
          progress: t,
          bodyScale: 1 + (0.025 * celebration - 0.01 * squash) * motion,
          bodyY: -20 * celebration * motion,
          headY: -15 * celebration * motion,
          headScale: 1 + 0.015 * celebration * motion,
          leftArmRotation: -0.34 * celebration * motion,
          rightHandRotation: 0.38 * celebration * motion,
          mouthY: -5 * celebration * motion,
          glow: reduceMotion ? 0.16 * celebration : 0.5 * celebration,
          particles: reduceMotion ? 0 : celebration,
          leftFootY: -2 * celebration * motion,
          rightFootY: -2 * celebration * motion,
        );
    }
  }

  static _RatPose from(
    RatAnimation animation,
    double progress, {
    required bool reduceMotion,
  }) {
    return _RatPose._fromAnimation(
      animation,
      progress,
      reduceMotion: reduceMotion,
    );
  }

  _RatTransform transformFor(RatPart part) {
    if (part == RatPart.baseOutline) return const _RatTransform();
    if (part == RatPart.body) {
      return _RatTransform(translateY: bodyY, scale: bodyScale);
    }
    if (part == RatPart.head ||
        part == RatPart.mouth ||
        part == RatPart.rightCheek ||
        part == RatPart.leftCheek ||
        part == RatPart.rightEye ||
        part == RatPart.leftEye ||
        part == RatPart.rightEyebrow ||
        part == RatPart.leftEyebrow ||
        part == RatPart.rightEar ||
        part == RatPart.leftEar ||
        part == RatPart.bandana) {
      var rotation = headRotation;
      var scale = headScale;
      var y = headY;
      if (part == RatPart.rightEar || part == RatPart.leftEar) {
        rotation += earRotation;
      }
      if (part == RatPart.rightEye || part == RatPart.leftEye) {
        scale *= eyeScale;
      }
      if (part == RatPart.mouth) {
        y += mouthY;
      }
      return _RatTransform(translateY: y, rotation: rotation, scale: scale);
    }
    if (part == RatPart.leftArm) {
      return _RatTransform(rotation: leftArmRotation);
    }
    if (part == RatPart.rightHand) {
      return _RatTransform(rotation: rightHandRotation);
    }
    if (part == RatPart.tail) {
      return _RatTransform(rotation: tailRotation);
    }
    if (part == RatPart.leftFoot) {
      return _RatTransform(translateY: bodyY + leftFootY);
    }
    return _RatTransform(translateY: bodyY + rightFootY);
  }
}

double _triangle(double value) {
  final t = value.clamp(0.0, 1.0).toDouble();
  return t <= 0.5 ? t * 2 : (1 - t) * 2;
}

class _RatParticlesPainter extends CustomPainter {
  const _RatParticlesPainter({
    required this.progress,
    required this.particles,
    required this.glow,
  });

  final double progress;
  final double particles;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.48);
    if (glow > 0) {
      final glowPaint = Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                const Color(0xFFFFD98F).withValues(alpha: 0.22 * glow),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.46),
            );
      canvas.drawCircle(center, size.width * 0.46, glowPaint);
    }

    if (particles <= 0) return;
    final particlePaint = Paint()
      ..color = const Color(0xFFFFC972).withValues(alpha: 0.82 * particles)
      ..style = PaintingStyle.fill;
    final positions = <Offset>[
      Offset(size.width * 0.22, size.height * 0.58),
      Offset(size.width * 0.78, size.height * 0.54),
      Offset(size.width * 0.3, size.height * 0.34),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.2),
    ];
    for (var index = 0; index < positions.length; index++) {
      final phase = ((progress * 1.35) + index * 0.19) % 1;
      final travel = math.sin(phase * math.pi) * size.height * 0.11;
      final point = positions[index] + Offset(0, -travel);
      final opacity = math.sin(phase * math.pi) * particles;
      particlePaint.color = const Color(
        0xFFFFC972,
      ).withValues(alpha: 0.8 * opacity);
      if (index.isEven) {
        _drawHeart(canvas, point, size.width * 0.022, particlePaint);
      } else {
        _drawStar(canvas, point, size.width * 0.028, particlePaint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..cubicTo(
        center.dx - radius * 1.7,
        center.dy - radius * 0.1,
        center.dx - radius,
        center.dy - radius * 1.5,
        center.dx,
        center.dy - radius * 0.55,
      )
      ..cubicTo(
        center.dx + radius,
        center.dy - radius * 1.5,
        center.dx + radius * 1.7,
        center.dy - radius * 0.1,
        center.dx,
        center.dy + radius,
      );
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var index = 0; index < 8; index++) {
      final angle = -math.pi / 2 + index * math.pi / 4;
      final distance = index.isEven ? radius : radius * 0.35;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RatParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.particles != particles ||
      oldDelegate.glow != glow;
}
