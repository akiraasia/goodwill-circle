import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';

import 'wish_module_models.dart';

class WishAgentService {
  GenerativeModel? _model;

  WishAgentService() {
    try {
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        systemInstruction: Content.system('''
You are the Goodwill Circle wish-planning agent. Convert a user's wish and
emotional context into small, safe, practical actions. Use the supplied open
community requests as possible goodwill tasks. Always return concise JSON.
'''),
      );
    } catch (_) {
      _model = null;
    }
  }

  Future<WishAgentInsight> analyzeWish({
    required String wishText,
    required String focusArea,
    required String feeling,
    required List<HelpRequest> requests,
    required int streakDays,
  }) async {
    final fallback = _fallbackInsight(
      wishText: wishText,
      focusArea: focusArea,
      feeling: feeling,
      requests: requests,
      streakDays: streakDays,
    );
    if (_model == null) return fallback;

    try {
      final prompt = '''
Wish: $wishText
Focus area: $focusArea
Feeling: $feeling
Current streak days: $streakDays
Open help requests:
${jsonEncode(requests.map((request) => request.wishAgentSummary).toList())}

Return exactly this JSON shape:
{
  "sentiment": "positive|mixed|anxious|sad|neutral",
  "primary_virtue": "Courage|Wisdom|Compassion|Discipline|Integrity",
  "reply_style": "Warm|Moody|Cool|Playful|Direct",
  "tasks": [
    {"title":"...","description":"...","virtue":"...","difficulty":"easy|hard","reward_points":10,"duration_minutes":5,"linked_request_id":null}
  ]
}
Include one easy task, one hard task, and one help-request task when a request is relevant.
For streaks of 7 or more, make the hard task more challenging and use 20+ reward points.
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final decoded = _decodeJson(response.text ?? '');
      if (decoded == null) return fallback;
      return _parseInsight(decoded, fallback, requests, streakDays);
    } catch (_) {
      return fallback;
    }
  }

  Future<String> reply({
    required String wishText,
    required String currentView,
    required String replyStyle,
    required String message,
    required String sentiment,
  }) async {
    if (_model == null) {
      return 'I hear you. One small step toward "$wishText" is enough for today.';
    }
    try {
      final response = await _model!.generateContent([Content.text('''
Reply as a $replyStyle companion in 1-2 short sentences.
Active wish: $wishText
Current wish-module view: $currentView
Detected sentiment: $sentiment
User message: $message
Be supportive, practical, and never pretend to be a therapist.
''')]);
      return response.text?.trim().isNotEmpty == true
          ? response.text!.trim()
          : 'I hear you. Let us choose one kind next step together.';
    } catch (_) {
      return 'I hear you. Let us choose one kind next step together.';
    }
  }

  Map<String, dynamic>? _decodeJson(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'```(?:json)?'), '').replaceAll('```', '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      return jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  WishAgentInsight _parseInsight(
    Map<String, dynamic> json,
    WishAgentInsight fallback,
    List<HelpRequest> requests,
    int streakDays,
  ) {
    final rawTasks = json['tasks'];
    final tasks = rawTasks is List
        ? rawTasks.whereType<Map>().map((task) => WishModuleTaskDraft(
              title: task['title']?.toString() ?? 'Take one small step',
              description: task['description']?.toString() ?? '',
              virtue: _virtue(task['virtue']?.toString()),
              difficulty: task['difficulty']?.toString().toLowerCase() == 'hard' ? 'hard' : 'easy',
              rewardPoints: (task['reward_points'] as num?)?.toInt() ?? (streakDays >= 7 ? 20 : 10),
              durationMinutes: (task['duration_minutes'] as num?)?.toInt() ?? 5,
              linkedRequestId: task['linked_request_id']?.toString(),
            )).toList()
        : <WishModuleTaskDraft>[];
    final normalized = tasks.isEmpty ? fallback.tasks : tasks;
    return WishAgentInsight(
      sentiment: _sentiment(json['sentiment']?.toString()),
      primaryVirtue: _virtue(json['primary_virtue']?.toString()),
      suggestedReplyStyle: _replyStyle(json['reply_style']?.toString()),
      tasks: _ensureTaskMix(normalized, requests, streakDays),
    );
  }

  WishAgentInsight _fallbackInsight({
    required String wishText,
    required String focusArea,
    required String feeling,
    required List<HelpRequest> requests,
    required int streakDays,
  }) {
    final lower = '$wishText $feeling'.toLowerCase();
    final virtue = lower.contains('jump') || lower.contains('fear') || lower.contains('brave')
        ? 'Courage'
        : focusArea == 'Mental'
            ? 'Wisdom'
            : focusArea == 'Ethical'
                ? 'Compassion'
                : 'Discipline';
    final sentiment = lower.contains('anxious') || lower.contains('scared') ? 'anxious' : 'positive';
    final tasks = [
      WishModuleTaskDraft(
        title: 'Name one small step toward your wish',
        description: 'Write it down and make it specific enough to do today.',
        virtue: virtue,
        difficulty: 'easy',
        rewardPoints: 10,
        durationMinutes: 2,
      ),
      WishModuleTaskDraft(
        title: streakDays >= 7 ? 'Take a brave stretch step toward your wish' : 'Spend 10 minutes practicing your next step',
        description: 'Choose a safe action that is slightly beyond your usual comfort zone.',
        virtue: virtue,
        difficulty: 'hard',
        rewardPoints: streakDays >= 7 ? 25 : 15,
        durationMinutes: streakDays >= 7 ? 20 : 10,
      ),
    ];
    return WishAgentInsight(
      sentiment: sentiment,
      primaryVirtue: virtue,
      suggestedReplyStyle: sentiment == 'anxious' ? 'Warm' : 'Cool',
      tasks: _ensureTaskMix(tasks, requests, streakDays),
    );
  }

  List<WishModuleTaskDraft> _ensureTaskMix(
    List<WishModuleTaskDraft> tasks,
    List<HelpRequest> requests,
    int streakDays,
  ) {
    final result = [...tasks];
    if (!result.any((task) => task.difficulty == 'easy')) {
      result.insert(0, WishModuleTaskDraft(
        title: 'Take one easy first step',
        description: 'Make progress feel possible today.',
        virtue: result.firstOrNull?.virtue ?? 'Courage',
        difficulty: 'easy',
        rewardPoints: 10,
        durationMinutes: 2,
      ));
    }
    if (!result.any((task) => task.difficulty == 'hard')) {
      result.add(WishModuleTaskDraft(
        title: 'Practice your wish beyond the familiar',
        description: 'Choose a safe challenge that builds your identified virtue.',
        virtue: result.firstOrNull?.virtue ?? 'Courage',
        difficulty: 'hard',
        rewardPoints: streakDays >= 7 ? 25 : 15,
        durationMinutes: streakDays >= 7 ? 20 : 10,
      ));
    }
    if (requests.isNotEmpty && !result.any((task) => task.isHelpRequest)) {
      final request = requests.first;
      result.add(WishModuleTaskDraft(
        title: 'Help: ${request.title}',
        description: request.description,
        virtue: 'Compassion',
        difficulty: request.difficulty?.toLowerCase() == 'hard' ? 'hard' : 'easy',
        rewardPoints: request.goodwillReward > 0 ? request.goodwillReward : 20,
        durationMinutes: 15,
        linkedRequestId: request.id,
      ));
    }
    return result.take(5).toList();
  }

  String _virtue(String? value) {
    const values = {'Courage', 'Wisdom', 'Compassion', 'Discipline', 'Integrity'};
    return values.contains(value) ? value! : 'Courage';
  }

  String _sentiment(String? value) {
    const values = {'positive', 'mixed', 'anxious', 'sad', 'neutral'};
    return values.contains(value) ? value! : 'neutral';
  }

  String _replyStyle(String? value) {
    const values = {'Warm', 'Moody', 'Cool', 'Playful', 'Direct'};
    return values.contains(value) ? value! : 'Warm';
  }
}
