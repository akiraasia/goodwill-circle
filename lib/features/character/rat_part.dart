import 'package:flutter/widgets.dart';

import 'rat_config.dart';

/// Logical layers in the original SVG paint order.
enum RatPart {
  baseOutline,
  head,
  mouth,
  rightCheek,
  rightEye,
  leftEye,
  leftCheek,
  rightEyebrow,
  leftEyebrow,
  body,
  rightHand,
  rightEar,
  leftEar,
  bandana,
  leftArm,
  tail,
  leftFoot,
  rightFoot,
}

/// An SVG layer plus the anatomical pivot used for transforms.
class RatPartDefinition {
  const RatPartDefinition({
    required this.part,
    required this.assetPath,
    required this.pivot,
    required this.description,
  });

  final RatPart part;
  final String assetPath;
  final Offset pivot;
  final String description;

  Alignment get pivotAlignment => Alignment(
    (pivot.dx / RatConfig.artboardSize * 2) - 1,
    (pivot.dy / RatConfig.artboardSize * 2) - 1,
  );
}

/// The supplied SVG set has 18 independently loadable layers.
///
/// There is no standalone pupil, forearm, upper-arm, whisker, or right-arm
/// file. Those details are embedded in the supplied eye/arm/hand SVGs and are
/// therefore kept as their source groups so the mascot is not redrawn.
class RatParts {
  RatParts._();

  static const List<RatPartDefinition> ordered = <RatPartDefinition>[
    RatPartDefinition(
      part: RatPart.baseOutline,
      assetPath: 'character/base_outline.svg',
      pivot: Offset(627, 650),
      description:
          'Canonical outer silhouette; kept static as the visual anchor.',
    ),
    RatPartDefinition(
      part: RatPart.head,
      assetPath: 'character/head.svg',
      pivot: Offset(640, 710),
      description: 'Head and muzzle, pivoted at the neck.',
    ),
    RatPartDefinition(
      part: RatPart.mouth,
      assetPath: 'character/mouth.svg',
      pivot: Offset(650, 625),
      description: 'Mouth group; no alternate mouth asset was supplied.',
    ),
    RatPartDefinition(
      part: RatPart.rightCheek,
      assetPath: 'character/right_cheek.svg',
      pivot: Offset(815, 580),
      description: 'Right cheek blush.',
    ),
    RatPartDefinition(
      part: RatPart.rightEye,
      assetPath: 'character/right_eye.svg',
      pivot: Offset(750, 530),
      description: 'Right eye with its embedded pupil/highlights.',
    ),
    RatPartDefinition(
      part: RatPart.leftEye,
      assetPath: 'character/left_eye.svg',
      pivot: Offset(590, 530),
      description: 'Left eye with its embedded pupil/highlights.',
    ),
    RatPartDefinition(
      part: RatPart.leftCheek,
      assetPath: 'character/left_cheek.svg',
      pivot: Offset(500, 580),
      description: 'Left cheek blush.',
    ),
    RatPartDefinition(
      part: RatPart.rightEyebrow,
      assetPath: 'character/right_eyebrow.svg',
      pivot: Offset(735, 415),
      description: 'Right eyebrow.',
    ),
    RatPartDefinition(
      part: RatPart.leftEyebrow,
      assetPath: 'character/left_eyebrow.svg',
      pivot: Offset(565, 415),
      description: 'Left eyebrow.',
    ),
    RatPartDefinition(
      part: RatPart.body,
      assetPath: 'character/body.svg',
      pivot: Offset(640, 840),
      description: 'Torso and belly.',
    ),
    RatPartDefinition(
      part: RatPart.rightHand,
      assetPath: 'character/right_hand.svg',
      pivot: Offset(866, 646),
      description: 'Right arm/hand is one supplied grouped asset.',
    ),
    RatPartDefinition(
      part: RatPart.rightEar,
      assetPath: 'character/right_ear.svg',
      pivot: Offset(780, 355),
      description: 'Right ear, attached to the head.',
    ),
    RatPartDefinition(
      part: RatPart.leftEar,
      assetPath: 'character/left_ear.svg',
      pivot: Offset(500, 355),
      description: 'Left ear, attached to the head.',
    ),
    RatPartDefinition(
      part: RatPart.bandana,
      assetPath: 'character/bandana.svg',
      pivot: Offset(640, 720),
      description: 'Bandana and heart emblem, attached to the head/neck.',
    ),
    RatPartDefinition(
      part: RatPart.leftArm,
      assetPath: 'character/left_arm.svg',
      pivot: Offset(510, 745),
      description: 'Left arm and paw are one supplied grouped asset.',
    ),
    RatPartDefinition(
      part: RatPart.tail,
      assetPath: 'character/tail.svg',
      pivot: Offset(455, 1035),
      description: 'Tail, pivoted at its body connection.',
    ),
    RatPartDefinition(
      part: RatPart.leftFoot,
      assetPath: 'character/left_foot.svg',
      pivot: Offset(520, 1060),
      description: 'Left foot.',
    ),
    RatPartDefinition(
      part: RatPart.rightFoot,
      assetPath: 'character/right_foot.svg',
      pivot: Offset(760, 1060),
      description: 'Right foot.',
    ),
  ];
}
