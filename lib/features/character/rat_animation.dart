/// The public animation vocabulary for the Goodwill Circle mascot.
enum RatAnimation {
  idle,
  blink,
  happy,
  wave,
  taskComplete,
  helpComplete,
  virtueGrowth,
  milestone,
}

extension RatAnimationDetails on RatAnimation {
  String get label {
    switch (this) {
      case RatAnimation.idle:
        return 'Idle';
      case RatAnimation.blink:
        return 'Blink';
      case RatAnimation.happy:
        return 'Happy';
      case RatAnimation.wave:
        return 'Wave';
      case RatAnimation.taskComplete:
        return 'Task Complete';
      case RatAnimation.helpComplete:
        return 'Help Complete';
      case RatAnimation.virtueGrowth:
        return 'Virtue Growth';
      case RatAnimation.milestone:
        return 'Milestone';
    }
  }

  int get priority {
    switch (this) {
      case RatAnimation.idle:
        return 0;
      case RatAnimation.blink:
        return 1;
      case RatAnimation.happy:
        return 2;
      case RatAnimation.wave:
        return 2;
      case RatAnimation.taskComplete:
        return 3;
      case RatAnimation.helpComplete:
        return 4;
      case RatAnimation.virtueGrowth:
        return 5;
      case RatAnimation.milestone:
        return 6;
    }
  }

  Duration get duration {
    switch (this) {
      case RatAnimation.idle:
        return const Duration(milliseconds: 1800);
      case RatAnimation.blink:
        return const Duration(milliseconds: 160);
      case RatAnimation.happy:
        return const Duration(milliseconds: 800);
      case RatAnimation.wave:
        return const Duration(milliseconds: 1400);
      case RatAnimation.taskComplete:
        return const Duration(milliseconds: 1400);
      case RatAnimation.helpComplete:
        return const Duration(milliseconds: 2000);
      case RatAnimation.virtueGrowth:
        return const Duration(milliseconds: 2300);
      case RatAnimation.milestone:
        return const Duration(milliseconds: 2800);
    }
  }

  bool get loops => this == RatAnimation.idle;
}
