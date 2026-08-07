import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'rat_animation.dart';

/// Owns the one master Flutter animation controller used by a mascot.
///
/// The widget attaches a ticker in its State, so callers can create the
/// controller with `RatController()` and retain it for event-driven playback.
class RatController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  RatController({bool reduceMotion = false}) : _reduceMotion = reduceMotion;

  AnimationController? _animationController;
  RatAnimation _current = RatAnimation.idle;
  bool _reduceMotion;
  bool _disposed = false;

  RatAnimation get currentAnimation => _current;
  bool get reduceMotion => _reduceMotion;
  bool get isAttached => _animationController != null;

  /// A stable animation object for AnimatedBuilder/CurvedAnimation consumers.
  Animation<double> get animation =>
      _animationController ?? const AlwaysStoppedAnimation<double>(0);

  void attach(TickerProvider vsync) {
    if (_disposed || _animationController != null) return;

    final controller = AnimationController(
      vsync: vsync,
      duration: RatAnimation.idle.duration,
      value: 0,
    );
    controller.addListener(notifyListeners);
    controller.addStatusListener(_handleStatus);
    _animationController = controller;
    if (_current.loops) {
      controller.repeat();
    } else {
      controller.duration = _current.duration;
      controller.forward();
    }
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
  }

  /// Plays an animation unless a currently active animation has higher
  /// priority. Temporary animations always return to the looping idle state.
  void play(RatAnimation animation) {
    if (_disposed) return;
    if (animation != RatAnimation.idle &&
        _current != RatAnimation.idle &&
        animation.priority < _current.priority) {
      return;
    }

    _current = animation;
    final controller = _animationController;
    if (controller != null) {
      controller.stop();
      controller.duration = animation.duration;
      controller.value = 0;
      if (animation.loops) {
        controller.repeat();
      } else {
        controller.forward();
      }
    }
    notifyListeners();
  }

  void blink() => play(RatAnimation.blink);

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _current == RatAnimation.idle ||
        _disposed) {
      return;
    }

    _current = RatAnimation.idle;
    final controller = _animationController;
    if (controller != null) {
      controller.duration = RatAnimation.idle.duration;
      controller.repeat();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _animationController?.dispose();
    _animationController = null;
    super.dispose();
  }
}
