import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A Flame game that handles layered rendering of backgrounds,
/// character sprites, and VFX for the visual novel mode.
class StoryEngine extends FlameGame {
  late SpriteComponent _background;
  late SpriteComponent _character;
  
  String currentBackground;
  String currentCharacter;
  String emotion;

  StoryEngine({
    this.currentBackground = 'bg_village_day.png', // placeholders
    this.currentCharacter = 'npc_mentor_idle.png',
    this.emotion = 'neutral',
  });

  @override
  Future<void> onLoad() async {
    // 1. Load Background Layer
    // Assuming images are in assets/images/
    // We use a placeholder rectangle for now since we don't have actual assets loaded yet.
    
    // In a real scenario with assets, we'd do:
    // _background = SpriteComponent()
    //   ..sprite = await loadSprite(currentBackground)
    //   ..size = size;
    // add(_background);

    // Fallback colored background for now
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF1E2124),
    ));

    // 2. Load Character Layer
    // _character = SpriteComponent()
    //   ..sprite = await loadSprite(currentCharacter)
    //   ..size = Vector2(300, 600)
    //   ..position = Vector2(size.x / 2 - 150, size.y - 600);
    // add(_character);
    
    // Fallback character
    add(RectangleComponent(
      size: Vector2(200, 400),
      position: Vector2(size.x / 2 - 100, size.y - 400),
      paint: Paint()..color = const Color(0xFF4A90E2),
    ));
    
    // Character face/emotion indicator
    add(CircleComponent(
      radius: 40,
      position: Vector2(size.x / 2 - 40, size.y - 350),
      paint: Paint()..color = emotionColor(),
    ));
  }

  Color emotionColor() {
    switch (emotion) {
      case 'happy': return Colors.green;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      case 'surprised': return Colors.yellow;
      default: return Colors.white;
    }
  }

  void updateScene({String? background, String? character, String? newEmotion}) {
    if (background != null) currentBackground = background;
    if (character != null) currentCharacter = character;
    if (newEmotion != null) emotion = newEmotion;
    
    // In a real app with assets, we would update the sprites here
    // e.g. _background.sprite = await loadSprite(currentBackground);
    
    // Rebuild the scene
    removeAll(children);
    onLoad();
  }
}
