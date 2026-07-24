import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:goodwill_circle/features/wish/tasks/virtue_task_repository.dart';

class WishTaskGenerator {
  final GenerativeModel _model;

  WishTaskGenerator() : _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');

  Future<List<Map<String, dynamic>>> generateDualTrackTasks({
    required String wish,
    required String virtue,
    required int currentLevel,
  }) async {
    final prompt = '''
You are a task generation engine. The user has the wish: "$wish".
They are trying to develop the virtue of: "$virtue" (Current Level: $currentLevel).

Generate 2 distinct tasks they can choose from to earn XP in this virtue:
1. A "Solo Task" they can do alone (e.g. read a book, meditate, exercise, journal).
2. A "Community Task" they can do to help others (e.g. mentor someone, volunteer, listen to a friend).

Format the output strictly as JSON like this:
[
  {
    "type": "solo",
    "title": "Short title of solo task",
    "description": "Detailed description of how to complete it.",
    "xp": 10
  },
  {
    "type": "community",
    "title": "Short title of community task",
    "description": "Detailed description of how to complete it.",
    "xp": 15
  }
]
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      // Simple extraction of JSON from markdown blocks if present
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']');
      
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonString = text.substring(jsonStart, jsonEnd + 1);
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
      
      return _fallbackTasks(virtue);
    } catch (e) {
      return _fallbackTasks(virtue);
    }
  }
  
  List<Map<String, dynamic>> _fallbackTasks(String virtue) {
    return [
      {
        "type": "solo",
        "title": "Reflect on $virtue",
        "description": "Spend 10 minutes writing about what $virtue means to you.",
        "xp": 10
      },
      {
        "type": "community",
        "title": "Express $virtue to someone",
        "description": "Reach out to a friend or family member and demonstrate $virtue.",
        "xp": 15
      }
    ];
  }
}
