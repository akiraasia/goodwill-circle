/// Shared constants for the canonical character artwork.
class RatConfig {
  RatConfig._();

  /// Every supplied SVG uses this same normalized viewBox.
  static const double artboardSize = 1254;

  /// A conservative default for previews and unconstrained layouts.
  static const double defaultSize = 220;

  static const double idleBreathScale = 0.015;
  static const double idleBodyTravel = 2.5;
  static const double idleHeadTravel = 1.5;
  static const double idleTailRotation = 0.025;

  static const String semanticsLabel = 'Goodwill Circle rat mascot';
}
