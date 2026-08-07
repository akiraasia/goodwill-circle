import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MascotState {
  idle,
  celebrating,
  welcoming,
  listening,
}

class MascotWidget extends StatelessWidget {
  final double height;
  final double? width;
  final MascotState state;

  const MascotWidget({
    super.key,
    this.height = 120,
    this.width,
    this.state = MascotState.idle,
  });

  @override
  Widget build(BuildContext context) {
    Widget svgWidget = SvgPicture.asset(
      'character/preview_composite.svg',
      height: height,
      width: width,
      fit: BoxFit.contain,
    );

    switch (state) {
      case MascotState.celebrating:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1.05),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: svgWidget,
        );
      case MascotState.welcoming:
      case MascotState.listening:
      case MascotState.idle:
      default:
        return svgWidget;
    }
  }
}
