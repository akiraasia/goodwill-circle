import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goodwill_circle/shared/widgets/mascot_widget.dart';

class WishMascot extends StatefulWidget {
  final double height;
  final MascotState state;
  final bool armsUp;

  const WishMascot({
    super.key,
    this.height = 120,
    this.state = MascotState.idle,
    this.armsUp = false,
  });

  @override
  State<WishMascot> createState() => _WishMascotState();
}

class _WishMascotState extends State<WishMascot> {
  Timer? _blinkTimer;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || _isSleeping || widget.state != MascotState.idle) return;
      setState(() => _isBlinking = true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (mounted) setState(() => _isBlinking = false);
    });
  }

  bool get _isSleeping {
    final hour = DateTime.now().hour;
    return hour >= 21 || hour < 6;
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _isSleeping
        ? MascotState.sleeping
        : (_isBlinking ? MascotState.winking : widget.state);
    return MascotWidget(height: widget.height, state: state, armsUp: widget.armsUp);
  }
}
