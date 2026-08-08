import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MascotState {
  idle,
  winking,
  celebrating,
  sleeping,
  listening,
  welcoming,
}

class MascotWidget extends StatelessWidget {
  final double height;
  final double? width;
  final MascotState state;
  final bool? armsUp;

  const MascotWidget({
    super.key,
    this.height = 120,
    this.width,
    this.state = MascotState.idle,
    this.armsUp,
  });

  bool get _isNighttime {
    final hour = DateTime.now().hour;
    return hour >= 21 || hour < 6;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveState = (state == MascotState.idle && _isNighttime)
        ? MascotState.sleeping
        : state;

    final isArmsUp = armsUp ??
        (effectiveState == MascotState.celebrating ||
            effectiveState == MascotState.welcoming ||
            effectiveState == MascotState.winking);

    final svgString = _buildMascotSvg(
      state: effectiveState,
      isArmsUp: isArmsUp,
    );

    Widget child = SvgPicture.string(
      svgString,
      height: height,
      width: width ?? height,
      fit: BoxFit.contain,
    );

    if (effectiveState == MascotState.celebrating) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 550),
        curve: Curves.elasticOut,
        builder: (context, val, widget) {
          final dy = -14.0 * (1 - (val - 1) * (val - 1));
          return Transform.translate(
            offset: Offset(0, dy < 0 ? dy : 0),
            child: widget,
          );
        },
        child: child,
      );
    }

    if (effectiveState == MascotState.listening) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1.04),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, scale, widget) {
          return Transform.scale(scale: scale, child: widget);
        },
        child: child,
      );
    }

    return child;
  }

  String _buildMascotSvg({
    required MascotState state,
    required bool isArmsUp,
  }) {
    final isSleeping = state == MascotState.sleeping;
    final isWinking = state == MascotState.winking;

    String eyesSvg;
    if (isSleeping) {
      eyesSvg = '''
      <g class="mascot-eyes-closed">
        <path d="M52 58 q4 3 8 0" stroke="#5a3226" stroke-width="2" fill="none" stroke-linecap="round"/>
        <path d="M72 58 q4 3 8 0" stroke="#5a3226" stroke-width="2" fill="none" stroke-linecap="round"/>
      </g>
      ''';
    } else if (isWinking) {
      eyesSvg = '''
      <g class="mascot-eyes">
        <circle cx="56" cy="58" r="3.4" fill="#5a3226"/>
        <line x1="72" y1="58" x2="80" y2="58" stroke="#5a3226" stroke-width="2.5" stroke-linecap="round"/>
      </g>
      ''';
    } else {
      eyesSvg = '''
      <g class="mascot-eyes">
        <circle cx="56" cy="58" r="3.4" fill="#5a3226"/>
        <circle cx="76" cy="58" r="3.4" fill="#5a3226"/>
      </g>
      ''';
    }

    String armsSvg = isArmsUp
        ? '''
      <path d="M38 90 Q 20 70 28 50" stroke="#d9a48f" stroke-width="10" fill="none" stroke-linecap="round"/>
      <path d="M98 90 Q 118 68 112 48" stroke="#d9a48f" stroke-width="10" fill="none" stroke-linecap="round"/>
    '''
        : '''
      <path d="M36 92 Q 28 104 40 112" stroke="#d9a48f" stroke-width="10" fill="none" stroke-linecap="round"/>
      <path d="M100 92 Q 108 104 96 112" stroke="#d9a48f" stroke-width="10" fill="none" stroke-linecap="round"/>
    ''';

    String zzzSvg = isSleeping
        ? '''
      <text x="98" y="30" fill="#f3a89e" font-weight="bold" font-size="16">z</text>
      <text x="108" y="18" fill="#f3a89e" font-weight="bold" font-size="12">z</text>
      <text x="116" y="8" fill="#f3a89e" font-weight="bold" font-size="9">z</text>
    '''
        : '';

    return '''
    <svg viewBox="0 0 140 140" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="70" cy="128" rx="34" ry="6" fill="#e9c9bd" opacity="0.5"/>
      <path d="M96 100 Q 122 95 118 70" stroke="#c98d78" stroke-width="4" fill="none" stroke-linecap="round"/>
      <circle cx="42" cy="38" r="14" fill="#d9a48f"/>
      <circle cx="42" cy="38" r="8" fill="#f3cfc2"/>
      <circle cx="90" cy="34" r="15" fill="#d9a48f"/>
      <circle cx="90" cy="34" r="9" fill="#f3cfc2"/>
      <ellipse cx="68" cy="88" rx="38" ry="34" fill="#d9a48f"/>
      <ellipse cx="68" cy="96" rx="24" ry="20" fill="#f5ddd0"/>
      <circle cx="66" cy="58" r="30" fill="#d9a48f"/>
      <ellipse cx="66" cy="66" rx="17" ry="13" fill="#f5ddd0"/>
      <path d="M46 76 Q66 88 88 76 L84 68 Q66 78 50 68 Z" fill="#c0392b"/>
      <path d="M78 78 l6 14 -10 -2 z" fill="#a8291d"/>
      <g stroke="#b98f7e" stroke-width="1.3">
        <path d="M40 62 L22 58 M40 66 L22 68"/>
        <path d="M92 62 L110 58 M92 66 L110 68"/>
      </g>
      $eyesSvg
      <ellipse cx="66" cy="66" rx="3" ry="2.2" fill="#a8291d"/>
      <circle cx="48" cy="66" r="4" fill="#f3a89e" opacity="0.6"/>
      <circle cx="84" cy="66" r="4" fill="#f3a89e" opacity="0.6"/>
      $armsSvg
      $zzzSvg
    </svg>
    ''';
  }
}

