import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final wishRepositoryProvider = Provider<WishRepository>((ref) {
  return WishRepository(Supabase.instance.client);
});

class WishStats {
  final double physical;
  final double mental;
  final double ethicalEmotional;
  final Map<String, double> physicalDetails;
  final Map<String, double> mentalDetails;
  final Map<String, double> ethicalDetails;

  const WishStats({
    required this.physical,
    required this.mental,
    required this.ethicalEmotional,
    this.physicalDetails = const {},
    this.mentalDetails = const {},
    this.ethicalDetails = const {},
  });

  factory WishStats.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseDetails(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
      }
      return {};
    }

    return WishStats(
      physical: (json['physical'] as num?)?.toDouble() ?? 10.0,
      mental: (json['mental'] as num?)?.toDouble() ?? 10.0,
      ethicalEmotional: (json['ethical_emotional'] as num?)?.toDouble() ?? 10.0,
      physicalDetails: parseDetails(json['physical_details']),
      mentalDetails: parseDetails(json['mental_details']),
      ethicalDetails: parseDetails(json['ethical_details']),
    );
  }

  Map<String, dynamic> toJson() => {
    'physical': physical,
    'mental': mental,
    'ethical_emotional': ethicalEmotional,
    'physical_details': physicalDetails,
    'mental_details': mentalDetails,
    'ethical_details': ethicalDetails,
  };
}

class WishTask {
  final String id;
  final String userId;
  final String taskText;
  final String targetStatCategory;
  final String targetSubStat;
  final int rewardAmount;
  final String status;
  final DateTime createdAt;

  WishTask({
    required this.id,
    required this.userId,
    required this.taskText,
    required this.targetStatCategory,
    required this.targetSubStat,
    required this.rewardAmount,
    required this.status,
    required this.createdAt,
  });

  factory WishTask.fromJson(Map<String, dynamic> json) {
    return WishTask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskText: json['task_text'] as String,
      targetStatCategory: json['target_stat_category'] as String,
      targetSubStat: json['target_sub_stat'] as String,
      rewardAmount: json['reward_amount'] as int? ?? 1,
      status: json['status'] as String? ?? 'assigned',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Novel {
  final String id;
  final String title;
  final String description;
  final String category;

  const Novel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });

  factory Novel.fromJson(Map<String, dynamic> json) {
    return Novel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
    );
  }
}

class NovelScene {
  final String id;
  final String novelId;
  final String title;
  final String content;
  final bool isEnding;

  const NovelScene({
    required this.id,
    required this.novelId,
    required this.title,
    required this.content,
    required this.isEnding,
  });

  factory NovelScene.fromJson(Map<String, dynamic> json) {
    return NovelScene(
      id: json['id'] as String,
      novelId: json['novel_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isEnding: json['is_ending'] as bool? ?? false,
    );
  }
}

class NovelChoice {
  final String id;
  final String sceneId;
  final String choiceText;
  final String? targetSceneId;
  final double requiredPhysical;
  final double requiredMental;
  final double requiredEthical;
  final double rewardPhysical;
  final double rewardMental;
  final double rewardEthical;
  final Map<String, double> requiredSubStats;

  const NovelChoice({
    required this.id,
    required this.sceneId,
    required this.choiceText,
    this.targetSceneId,
    required this.requiredPhysical,
    required this.requiredMental,
    required this.requiredEthical,
    required this.rewardPhysical,
    required this.rewardMental,
    required this.rewardEthical,
    this.requiredSubStats = const {},
  });

  factory NovelChoice.fromJson(Map<String, dynamic> json) {
    return NovelChoice(
      id: json['id'] as String? ?? '',
      sceneId: json['scene_id'] as String? ?? '',
      choiceText: json['choice_text'] as String? ?? '',
      targetSceneId: json['target_scene_id'] as String?,
      requiredPhysical: (json['required_physical'] as num?)?.toDouble() ?? 0.0,
      requiredMental: (json['required_mental'] as num?)?.toDouble() ?? 0.0,
      requiredEthical: (json['required_ethical'] as num?)?.toDouble() ?? 0.0,
      rewardPhysical: (json['reward_physical'] as num?)?.toDouble() ?? 0.0,
      rewardMental: (json['reward_mental'] as num?)?.toDouble() ?? 0.0,
      rewardEthical: (json['reward_ethical'] as num?)?.toDouble() ?? 0.0,
      requiredSubStats: _parseSubStats(json['req_sub_stats']),
    );
  }

  static Map<String, double> _parseSubStats(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()));
    }
    return {};
  }
}

class WishChatMessage {
  final String id;
  final String category;
  final String senderName;
  final String message;
  final DateTime createdAt;

  const WishChatMessage({
    required this.id,
    required this.category,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });
}

// ─── New v2 Domain Models ────────────────────────────────────────────────────

const List<String> kAllVirtues = [
  'Courage',
  'Wisdom',
  'Compassion',
  'Discipline',
  'Integrity',
];

const Map<String, String> kVirtueStatCategory = {
  'Courage': 'physical',
  'Discipline': 'physical',
  'Wisdom': 'mental',
  'Integrity': 'mental',
  'Compassion': 'ethical',
};

const Map<String, String> kVirtueDescription = {
  'Courage': 'The strength to act despite fear. Face discomfort, speak up, and take bold steps.',
  'Wisdom': 'The ability to see clearly and decide well. Learn, reflect, and grow through experience.',
  'Compassion': 'Care for others and yourself. Empathise, support, and connect with kindness.',
  'Discipline': 'The power of consistent action. Build habits, stay focused, and follow through.',
  'Integrity': 'Alignment between values and actions. Be honest, accountable, and principled.',
};

class UserVirtue {
  final String id;
  final String userId;
  final String virtueName;
  final String statCategory;
  int level;
  int xp;

  UserVirtue({
    required this.id,
    required this.userId,
    required this.virtueName,
    required this.statCategory,
    required this.level,
    required this.xp,
  });

  factory UserVirtue.fromJson(Map<String, dynamic> json) => UserVirtue(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        virtueName: json['virtue_name'] as String,
        statCategory: json['stat_category'] as String,
        level: json['level'] as int? ?? 1,
        xp: json['xp'] as int? ?? 0,
      );

  int get xpToNextLevel => level * 100;
  double get xpProgress => xp / xpToNextLevel;
}

class VirtueTask {
  final String id;
  final String userId;
  final String virtueName;
  final String taskType; // 'social' | 'individual'
  final String title;
  final String description;
  final int xpReward;
  String status; // 'pending' | 'in_progress' | 'completed'
  final String? linkedRequestId;
  final String? socialRole; // 'helper' | 'helpee'

  VirtueTask({
    required this.id,
    required this.userId,
    required this.virtueName,
    required this.taskType,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.status,
    this.linkedRequestId,
    this.socialRole,
  });

  factory VirtueTask.fromJson(Map<String, dynamic> json) => VirtueTask(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        virtueName: json['virtue_name'] as String,
        taskType: json['task_type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        xpReward: json['xp_reward'] as int? ?? 20,
        status: json['status'] as String? ?? 'pending',
        linkedRequestId: json['linked_request_id'] as String?,
        socialRole: json['social_role'] as String?,
      );
}

class VirtueMaterial {
  final String id;
  final String userId;
  final String virtueName;
  final String materialType; // 'meme' | 'book' | 'song' | 'video' | 'article'
  final String title;
  final String? description;
  final String? url;
  final String? imageUrl;
  final String posterName;
  final int upvotes;
  final DateTime createdAt;

  VirtueMaterial({
    required this.id,
    required this.userId,
    required this.virtueName,
    required this.materialType,
    required this.title,
    this.description,
    this.url,
    this.imageUrl,
    required this.posterName,
    required this.upvotes,
    required this.createdAt,
  });

  factory VirtueMaterial.fromJson(Map<String, dynamic> json) => VirtueMaterial(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        virtueName: json['virtue_name'] as String,
        materialType: json['material_type'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        url: json['url'] as String?,
        imageUrl: json['image_url'] as String?,
        posterName: json['poster_name'] as String? ?? 'Anonymous',
        upvotes: json['upvotes'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class VirtueChatMessage {
  final String id;
  final String virtueName;
  final String senderName;
  final String message;
  final DateTime createdAt;

  VirtueChatMessage({
    required this.id,
    required this.virtueName,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory VirtueChatMessage.fromJson(Map<String, dynamic> json) =>
      VirtueChatMessage(
        id: json['id'] as String,
        virtueName: json['virtue_name'] as String,
        senderName: json['sender_name'] as String? ?? 'Anonymous',
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class WishInterviewQA {
  final String question;
  final String answer;
  const WishInterviewQA({required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };
}

class AssignedStats {
  final double physical;
  final double mental;
  final double ethical;
  final Map<String, double> physicalDetails;
  final Map<String, double> mentalDetails;
  final Map<String, double> ethicalDetails;

  const AssignedStats({
    required this.physical,
    required this.mental,
    required this.ethical,
    required this.physicalDetails,
    required this.mentalDetails,
    required this.ethicalDetails,
  });
}

class WishRepository {
  final SupabaseClient _client;

  WishRepository(this._client);

  bool _isMock = false;

  // --- Local Session Cache for Mock Mode ---
  Map<String, dynamic>? _mockWish;
  WishStats _mockStats = const WishStats(physical: 10.0, mental: 10.0, ethicalEmotional: 10.0);
  List<UserVirtue> _mockVirtues = [];
  final List<WishChatMessage> _mockChatMessages = [];
  final List<VirtueChatMessage> _mockVirtueChat = [];
  final List<VirtueMaterial> _mockMaterials = [];
  final List<VirtueTask> _mockTasks = [];
  final Map<String, String> _userNovelProgress = {}; // novelId -> currentSceneId

  // --- 1. Wishes ---

  Future<Map<String, dynamic>?> getActiveWish() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      final cachedStr = prefs.getString('cached_active_wish');
      if (cachedStr != null) {
        _mockWish = jsonDecode(cachedStr);
        _isMock = true;
        return _mockWish;
      }
      return null;
    }

    if (_isMock) {
      if (_mockWish == null) {
        final cachedStr = prefs.getString('cached_active_wish');
        if (cachedStr != null) {
          _mockWish = jsonDecode(cachedStr);
        }
      }
      return _mockWish;
    }

    try {
      final data = await _client
          .from('wishes')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      if (data != null) {
        prefs.setString('cached_active_wish', jsonEncode(data));
      }
      return data;
    } catch (e) {
      debugPrint('WishRepository: getActiveWish error (switching to mock): $e');
      _isMock = true;
      if (_mockWish == null) {
        final cachedStr = prefs.getString('cached_active_wish');
        if (cachedStr != null) {
          _mockWish = jsonDecode(cachedStr);
        }
      }
      return _mockWish;
    }
  }

  Future<void> createUserWish({
    required String wishStatement,
    required String physicalCondition,
    required String mentalCondition,
    List<WishInterviewQA> interviewData = const [],
    AssignedStats? assignedStats,
    String pathMode = 'task',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final physicalStart = assignedStats?.physical ?? 10.0;
    final mentalStart = assignedStats?.mental ?? 10.0;
    final ethicalStart = assignedStats?.ethical ?? 10.0;

    final wishData = {
      'user_id': userId,
      'wish_statement': wishStatement,
      'physical_condition': physicalCondition,
      'mental_condition': mentalCondition,
      'category': 'Self-Improvement',
      'status': 'active',
      'interview_data': interviewData.map((qa) => qa.toJson()).toList(),
      'path_mode': pathMode,
    };

    if (_isMock) {
      _mockWish = wishData;
      _mockStats = WishStats(
        physical: physicalStart,
        mental: mentalStart,
        ethicalEmotional: ethicalStart,
        physicalDetails: assignedStats?.physicalDetails ?? {},
        mentalDetails: assignedStats?.mentalDetails ?? {},
        ethicalDetails: assignedStats?.ethicalDetails ?? {},
      );
      
      // Seed mockup virtues from sub-stats
      _mockVirtues = [];
      void addMockVirtues(Map<String, double> details, String category) {
        details.forEach((key, value) {
          _mockVirtues.add(UserVirtue(
            id: DateTime.now().millisecondsSinceEpoch.toString() + key,
            userId: userId,
            virtueName: key,
            statCategory: category,
            level: value.toInt(),
            xp: 0,
          ));
        });
      }
      
      if (assignedStats != null) {
        addMockVirtues(assignedStats.physicalDetails, 'physical');
        addMockVirtues(assignedStats.mentalDetails, 'mental');
        addMockVirtues(assignedStats.ethicalDetails, 'ethical');
      }
      
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('cached_active_wish', jsonEncode(_mockWish));
      return;
    }

    try {
      // Check if user has active vision first, create one if not
      var vision = await _client.from('life_visions').select('id').eq('user_id', userId).eq('status', 'active').maybeSingle();
      String visionId;
      if (vision == null) {
        final newVision = await _client.from('life_visions').insert({
          'user_id': userId,
          'vision_statement': 'Self development journey for my wishes',
          'status': 'active',
        }).select('id').single();
        visionId = newVision['id'] as String;
      } else {
        visionId = vision['id'] as String;
      }

      wishData['vision_id'] = visionId;

      await _client.from('wishes').insert(wishData);

      // Initialize stats with specific sub-stats
      await _client.from('hgos_wish_stats').upsert({
        'user_id': userId,
        'physical': physicalStart,
        'mental': mentalStart,
        'ethical_emotional': ethicalStart,
        'physical_details': assignedStats?.physicalDetails ?? {},
        'mental_details': assignedStats?.mentalDetails ?? {},
        'ethical_details': assignedStats?.ethicalDetails ?? {},
      });

      // Create virtue entries mapping sub-stats to wish_virtues table for the hub views
      final allSubStats = {
        ...?assignedStats?.physicalDetails.map((k, v) => MapEntry(k, 'physical')),
        ...?assignedStats?.mentalDetails.map((k, v) => MapEntry(k, 'mental')),
        ...?assignedStats?.ethicalDetails.map((k, v) => MapEntry(k, 'ethical')),
      };

      for (final statEntry in allSubStats.entries) {
        await _client.from('wish_virtues').upsert({
          'user_id': userId,
          'virtue_name': statEntry.key,
          'stat_category': statEntry.value,
          'level': assignedStats?.physicalDetails[statEntry.key]?.toInt() ?? 
                   assignedStats?.mentalDetails[statEntry.key]?.toInt() ?? 
                   assignedStats?.ethicalDetails[statEntry.key]?.toInt() ?? 1,
          'xp': 0,
        });
      }
    } catch (e) {
      debugPrint('WishRepository: createUserWish error (falling back to mock): $e');
      _isMock = true;
      _mockWish = wishData;
      _mockStats = WishStats(
        physical: physicalStart,
        mental: mentalStart,
        ethicalEmotional: ethicalStart,
      );
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('cached_active_wish', jsonEncode(_mockWish));
    }
  }

  // --- 2. Stats ---

  Future<WishStats> getUserStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _mockStats;

    if (_isMock) return _mockStats;

    try {
      final data = await _client
          .from('hgos_wish_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        return WishStats.fromJson(data);
      } else {
        // Create stats if not exist
        await _client.from('hgos_wish_stats').insert({
          'user_id': userId,
          'physical': 10.0,
          'mental': 10.0,
          'ethical_emotional': 10.0,
        });
        return const WishStats(physical: 10.0, mental: 10.0, ethicalEmotional: 10.0);
      }
    } catch (e) {
      debugPrint('WishRepository: getUserStats error: $e');
      return _mockStats;
    }
  }

  Future<void> updateStats({
    required double physical,
    required double mental,
    required double ethical,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (_isMock) {
      _mockStats = WishStats(physical: physical, mental: mental, ethicalEmotional: ethical);
      return;
    }

    try {
      await _client.from('hgos_wish_stats').upsert({
        'user_id': userId,
        'physical': physical,
        'mental': mental,
        'ethical_emotional': ethical,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('WishRepository: updateStats error: $e');
      _mockStats = WishStats(physical: physical, mental: mental, ethicalEmotional: ethical);
    }
  }

  // --- 2.5 Tasks ---

  Future<List<WishTask>> getUserTasks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      final data = await _client
          .from('wish_tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data.map((j) => WishTask.fromJson(j)).toList();
    } catch (e) {
      debugPrint('WishRepository: getUserTasks error: $e');
      return [];
    }
  }

  Future<void> assignTask({
    required String taskText,
    required String targetStatCategory,
    required String targetSubStat,
    int rewardAmount = 1,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await _client.from('wish_tasks').insert({
        'user_id': userId,
        'task_text': taskText,
        'target_stat_category': targetStatCategory,
        'target_sub_stat': targetSubStat,
        'reward_amount': rewardAmount,
        'status': 'assigned',
      });
    } catch (e) {
      debugPrint('WishRepository: assignTask error: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      final data = await _client.from('wish_tasks')
        .update({'status': 'completed', 'completed_at': DateTime.now().toIso8601String()})
        .eq('id', taskId)
        .eq('user_id', userId)
        .select()
        .single();
        
      // Increment the specific sub-stat and main stat
      final cat = data['target_stat_category'] as String;
      final subStat = data['target_sub_stat'] as String;
      final reward = data['reward_amount'] as int;
      
      final currentStats = await getUserStats();
      
      // Update logic would need an RPC or complex update. For now, doing it client side.
      Map<String, double> updatedDetails;
      if (cat == 'physical') {
        updatedDetails = Map.from(currentStats.physicalDetails);
        updatedDetails[subStat] = (updatedDetails[subStat] ?? 0) + reward;
        await _client.from('hgos_wish_stats').update({
          'physical': currentStats.physical + reward,
          'physical_details': updatedDetails,
        }).eq('user_id', userId);
      } else if (cat == 'mental') {
        updatedDetails = Map.from(currentStats.mentalDetails);
        updatedDetails[subStat] = (updatedDetails[subStat] ?? 0) + reward;
        await _client.from('hgos_wish_stats').update({
          'mental': currentStats.mental + reward,
          'mental_details': updatedDetails,
        }).eq('user_id', userId);
      } else if (cat == 'ethical') {
        updatedDetails = Map.from(currentStats.ethicalDetails);
        updatedDetails[subStat] = (updatedDetails[subStat] ?? 0) + reward;
        await _client.from('hgos_wish_stats').update({
          'ethical_emotional': currentStats.ethicalEmotional + reward,
          'ethical_details': updatedDetails,
        }).eq('user_id', userId);
      }
      
    } catch (e) {
      debugPrint('WishRepository: completeTask error: $e');
    }
  }

  // --- 3. Choice Novels ---

  Future<List<Novel>> getNovels() async {
    if (_isMock) {
      return _staticNovels;
    }

    try {
      final data = await _client.from('hgos_novels').select();
      return data.map((json) => Novel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('WishRepository: getNovels error: $e');
      return _staticNovels;
    }
  }

  Future<List<NovelScene>> getNovelScenes(String novelId) async {
    if (_isMock) {
      return _staticScenes.where((scene) => scene.novelId == novelId).toList();
    }

    try {
      final data = await _client
          .from('hgos_novel_scenes')
          .select()
          .eq('novel_id', novelId);
      return data.map((json) => NovelScene.fromJson(json)).toList();
    } catch (e) {
      debugPrint('WishRepository: getNovelScenes error: $e');
      return _staticScenes.where((scene) => scene.novelId == novelId).toList();
    }
  }

  Future<List<NovelChoice>> getSceneChoices(String sceneId) async {
    if (_isMock) {
      return _staticChoices.where((choice) => choice.sceneId == sceneId).toList();
    }

    try {
      final data = await _client
          .from('hgos_novel_choices')
          .select()
          .eq('scene_id', sceneId);
      return data.map((json) => NovelChoice.fromJson(json)).toList();
    } catch (e) {
      debugPrint('WishRepository: getSceneChoices error: $e');
      return _staticChoices.where((choice) => choice.sceneId == sceneId).toList();
    }
  }

  Future<Map<String, dynamic>?> getNovelProgress(String novelId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    if (_isMock) {
      final sceneId = _userNovelProgress[novelId];
      if (sceneId == null) return null;
      final scene = _staticScenes.firstWhere((s) => s.id == sceneId);
      return {
        'current_scene_id': sceneId,
        'completed': scene.isEnding,
      };
    }

    try {
      final data = await _client
          .from('hgos_user_novel_progress')
          .select()
          .eq('user_id', userId)
          .eq('novel_id', novelId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('WishRepository: getNovelProgress error: $e');
      final sceneId = _userNovelProgress[novelId];
      if (sceneId == null) return null;
      final scene = _staticScenes.firstWhere((s) => s.id == sceneId);
      return {
        'current_scene_id': sceneId,
        'completed': scene.isEnding,
      };
    }
  }

  Future<void> saveNovelProgress(String novelId, String sceneId, bool completed) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (_isMock) {
      _userNovelProgress[novelId] = sceneId;
      return;
    }

    try {
      await _client.from('hgos_user_novel_progress').upsert({
        'user_id': userId,
        'novel_id': novelId,
        'current_scene_id': sceneId,
        'completed': completed,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('WishRepository: saveNovelProgress error: $e');
      _userNovelProgress[novelId] = sceneId;
    }
  }

  // --- 4. Global Category Chat ---

  Future<List<WishChatMessage>> getChatMessages(String category) async {
    if (_isMock) {
      return _mockChatMessages.where((msg) => msg.category == category).toList();
    }

    try {
      final data = await _client
          .from('hgos_wish_chat_messages')
          .select()
          .eq('category', category)
          .order('created_at', ascending: true)
          .limit(50);

      return data.map((json) {
        return WishChatMessage(
          id: json['id'] as String,
          category: json['category'] as String,
          senderName: json['sender_name'] as String? ?? 'Anonymous',
          message: json['message'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('WishRepository: getChatMessages error: $e');
      return _mockChatMessages.where((msg) => msg.category == category).toList();
    }
  }

  Future<void> sendChatMessage(String category, String message) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || message.trim().isEmpty) return;

    String senderName = 'Anonymous';
    try {
      final profile = await _client.from('profiles').select('name').eq('id', userId).maybeSingle();
      if (profile != null && profile['name'] != null) {
        senderName = profile['name'] as String;
      }
    } catch (_) {}

    final newMessage = WishChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      senderName: senderName,
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    if (_isMock) {
      _mockChatMessages.add(newMessage);
      return;
    }

    try {
      await _client.from('hgos_wish_chat_messages').insert({
        'category': category,
        'user_id': userId,
        'sender_name': senderName,
        'message': message.trim(),
      });
    } catch (e) {
      debugPrint('WishRepository: sendChatMessage error: $e');
      _mockChatMessages.add(newMessage);
    }
  }

  dynamic subscribeToChat(String category, Function(WishChatMessage) onNewMessage) {
    if (_isMock) {
      // Just return a dummy subscription in mock mode
      return Stream.periodic(const Duration(seconds: 15)).listen((_) {});
    }

    return _client
        .channel('public:hgos_wish_chat_messages:category=$category')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'hgos_wish_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'category',
            value: category,
          ),
          callback: (payload) {
            final json = payload.newRecord;
            onNewMessage(WishChatMessage(
              id: json['id'] as String,
              category: json['category'] as String,
              senderName: json['sender_name'] as String? ?? 'Anonymous',
              message: json['message'] as String,
              createdAt: DateTime.parse(json['created_at'] as String),
            ));
          },
        )
        .subscribe();
  }

  // --- 5. Tasks & Help Requests Matching ---

  Future<List<HelpRequest>> getRecommendedHelpRequests(String category) async {
    try {
      // We load all open requests
      final openData = await _client
          .from('help_requests')
          .select()
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(30);
      
      final allRequests = openData.map((json) => HelpRequest.fromJson(json)).toList();

      List<HelpRequest> matched = [];
      if (category == 'Physical') {
        matched = allRequests
            .where((req) => req.category == 'Skill Development' || req.tags.contains('physical'))
            .toList();
      } else if (category == 'Mental') {
        matched = allRequests
            .where((req) =>
                req.category == 'Technology' ||
                req.category == 'Education' ||
                req.category == 'Career' ||
                req.tags.contains('mental'))
            .toList();
      } else {
        // Ethical/Emotional
        matched = allRequests
            .where((req) =>
                req.category == 'Entrepreneurship' ||
                req.isCommunityRequest ||
                req.tags.contains('social') ||
                req.tags.contains('ethical'))
            .toList();
      }

      // Return max 3 items
      return matched.take(3).toList();
    } catch (e) {
      debugPrint('WishRepository: getRecommendedHelpRequests error: $e');
      return []; // Return empty list to handle offline gracefully
    }
  }

  // ─── 6. Virtues ─────────────────────────────────────────────────────────────

  Future<List<UserVirtue>> getUserVirtues() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    if (_isMock) return _mockVirtues;
    try {
      final data = await _client
          .from('wish_virtues')
          .select()
          .eq('user_id', userId)
          .order('virtue_name');
      return data.map((j) => UserVirtue.fromJson(j)).toList();
    } catch (e) {
      debugPrint('WishRepository: getUserVirtues error: $e');
      return _mockVirtues;
    }
  }

  Future<void> addXpToVirtue(String virtueName, int xpAmount) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (_isMock) {
      final idx = _mockVirtues.indexWhere((v) => v.virtueName == virtueName);
      if (idx >= 0) {
        _mockVirtues[idx].xp += xpAmount;
        while (_mockVirtues[idx].xp >= _mockVirtues[idx].xpToNextLevel) {
          _mockVirtues[idx].xp -= _mockVirtues[idx].xpToNextLevel;
          _mockVirtues[idx].level++;
        }
      }
      return;
    }

    try {
      final current = await _client
          .from('wish_virtues')
          .select()
          .eq('user_id', userId)
          .eq('virtue_name', virtueName)
          .maybeSingle();
      if (current != null) {
        int newXp = (current['xp'] as int? ?? 0) + xpAmount;
        int level = current['level'] as int? ?? 1;
        final cap = level * 100;
        if (newXp >= cap) {
          newXp -= cap;
          level++;
        }
        await _client.from('wish_virtues').update({
          'xp': newXp,
          'level': level,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId).eq('virtue_name', virtueName);
      }
    } catch (e) {
      debugPrint('WishRepository: addXpToVirtue error: $e');
    }
  }

  // ─── 7. Virtue Tasks ──────────────────────────────────────────────────────

  Future<List<VirtueTask>> getVirtueTasks(String virtueName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    if (_isMock) {
      return _mockTasks.where((t) => t.virtueName == virtueName).toList();
    }
    try {
      final data = await _client
          .from('wish_virtue_tasks')
          .select()
          .eq('user_id', userId)
          .eq('virtue_name', virtueName)
          .order('created_at');
      return data.map((j) => VirtueTask.fromJson(j)).toList();
    } catch (e) {
      debugPrint('WishRepository: getVirtueTasks error: $e');
      return _mockTasks.where((t) => t.virtueName == virtueName).toList();
    }
  }

  Future<void> seedVirtueTasks(String virtueName, List<VirtueTask> tasks) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    if (_isMock) {
      _mockTasks.addAll(tasks);
      return;
    }
    try {
      for (final task in tasks) {
        await _client.from('wish_virtue_tasks').insert({
          'user_id': userId,
          'virtue_name': task.virtueName,
          'task_type': task.taskType,
          'title': task.title,
          'description': task.description,
          'xp_reward': task.xpReward,
          'status': 'pending',
        });
      }
    } catch (e) {
      debugPrint('WishRepository: seedVirtueTasks error: $e');
      _mockTasks.addAll(tasks);
    }
  }

  Future<void> completeVirtueTask(String taskId, String virtueName, int xpReward) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    if (_isMock) {
      final idx = _mockTasks.indexWhere((t) => t.id == taskId);
      if (idx >= 0) _mockTasks[idx].status = 'completed';
      await addXpToVirtue(virtueName, xpReward);
      return;
    }
    try {
      await _client
          .from('wish_virtue_tasks')
          .update({'status': 'completed', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', taskId)
          .eq('user_id', userId);
      await addXpToVirtue(virtueName, xpReward);
    } catch (e) {
      debugPrint('WishRepository: completeVirtueTask error: $e');
    }
  }

  // ─── 8. Virtue Chat ───────────────────────────────────────────────────────

  Future<List<VirtueChatMessage>> getVirtueChatMessages(String virtueName) async {
    if (_isMock) {
      return _mockVirtueChat.where((m) => m.virtueName == virtueName).toList();
    }
    try {
      final data = await _client
          .from('wish_virtue_chat')
          .select()
          .eq('virtue_name', virtueName)
          .order('created_at', ascending: true)
          .limit(60);
      return data.map((j) => VirtueChatMessage.fromJson(j)).toList();
    } catch (e) {
      debugPrint('WishRepository: getVirtueChatMessages error: $e');
      return [];
    }
  }

  Future<void> sendVirtueChat(String virtueName, String message) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || message.trim().isEmpty) return;

    String senderName = 'Anonymous';
    try {
      final profile =
          await _client.from('profiles').select('name').eq('id', userId).maybeSingle();
      if (profile != null && profile['name'] != null) {
        senderName = profile['name'] as String;
      }
    } catch (_) {}

    final msg = VirtueChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      virtueName: virtueName,
      senderName: senderName,
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    if (_isMock) {
      _mockVirtueChat.add(msg);
      return;
    }

    try {
      await _client.from('wish_virtue_chat').insert({
        'user_id': userId,
        'virtue_name': virtueName,
        'sender_name': senderName,
        'message': message.trim(),
      });
    } catch (e) {
      debugPrint('WishRepository: sendVirtueChat error: $e');
      _mockVirtueChat.add(msg);
    }
  }

  dynamic subscribeToVirtueChat(
      String virtueName, Function(VirtueChatMessage) onNewMessage) {
    if (_isMock) {
      return Stream.periodic(const Duration(seconds: 30)).listen((_) {});
    }
    return _client
        .channel('virtue_chat:$virtueName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wish_virtue_chat',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'virtue_name',
            value: virtueName,
          ),
          callback: (payload) {
            onNewMessage(VirtueChatMessage.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  // ─── 9. Virtue Materials ─────────────────────────────────────────────────

  Future<List<VirtueMaterial>> getVirtueMaterials(String virtueName) async {
    if (_isMock) {
      return _mockMaterials.where((m) => m.virtueName == virtueName).toList();
    }
    try {
      final data = await _client
          .from('wish_virtue_materials')
          .select()
          .eq('virtue_name', virtueName)
          .order('created_at', ascending: false)
          .limit(40);
      return data.map((j) => VirtueMaterial.fromJson(j)).toList();
    } catch (e) {
      debugPrint('WishRepository: getVirtueMaterials error: $e');
      return [];
    }
  }

  Future<void> postVirtueMaterial({
    required String virtueName,
    required String materialType,
    required String title,
    String? description,
    String? url,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    String posterName = 'Anonymous';
    try {
      final profile =
          await _client.from('profiles').select('name').eq('id', userId).maybeSingle();
      if (profile != null && profile['name'] != null) {
        posterName = profile['name'] as String;
      }
    } catch (_) {}

    final mat = VirtueMaterial(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      virtueName: virtueName,
      materialType: materialType,
      title: title,
      description: description,
      url: url,
      imageUrl: imageUrl,
      posterName: posterName,
      upvotes: 0,
      createdAt: DateTime.now(),
    );

    if (_isMock) {
      _mockMaterials.insert(0, mat);
      return;
    }

    try {
      await _client.from('wish_virtue_materials').insert({
        'user_id': userId,
        'virtue_name': virtueName,
        'material_type': materialType,
        'title': title,
        'description': description,
        'url': url,
        'image_url': imageUrl,
        'poster_name': posterName,
      });
    } catch (e) {
      debugPrint('WishRepository: postVirtueMaterial error: $e');
      _mockMaterials.insert(0, mat);
    }
  }

  // ─── 10. Post Wish as Help Request ────────────────────────────────────────

  Future<void> postWishAsHelpRequest({
    required String wishStatement,
    required double characterScore,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final title = 'Help fulfill my wish: $wishStatement';
    final description =
        'I am on a self development path in Goodwill Circle. My wish is to attain "$wishStatement". '
        'My current character level stats have given this request a weight boost of +${characterScore.toInt()} priority. '
        'I would appreciate guidance, resources, or mentorship to accomplish this goal!';

    await _client.from('help_requests').insert({
      'creator_id': userId,
      'title': title,
      'description': description,
      'category': 'Skill Development',
      'goodwill_reward': 50 + (characterScore ~/ 3).toInt(), // Boost reward slightly with higher level
      'status': 'open',
      'tags': ['wish', 'self-development'],
      'difficulty': characterScore > 40 ? 'Hard' : characterScore > 25 ? 'Medium' : 'Easy',
    });
  }

  // --- Static Seeding fallbacks (for Mock Mode) ---

  static const List<Novel> _staticNovels = [
    Novel(
      id: '44444444-4444-4444-4444-444444444444',
      title: 'The Way of the Mountain',
      description: 'Balance your physical life force by climbing ancient temple peaks and training with a legendary monk.',
      category: 'Physical',
    ),
    Novel(
      id: '55555555-5555-5555-5555-555555555555',
      title: 'The Shifting Archives',
      description: 'Solve puzzles and decipher ancient stellar maps in a shifting library designed to test intellectual focus.',
      category: 'Mental',
    ),
    Novel(
      id: '66666666-6666-6666-6666-666666666666',
      title: 'The Echoing Village',
      description: 'Resolve local conflicts, help families in need, and rebuild trust in a community struggling after a crisis.',
      category: 'Ethical/Emotional',
    ),
  ];

  static const List<NovelScene> _staticScenes = [
    // Mountain
    NovelScene(id: 'mountain-1', novelId: '44444444-4444-4444-4444-444444444444', title: 'The Temple Gates', content: 'You stand before the base of the Mount of Flow. The steps are steep, slicked with morning dew. An elderly monk stands nearby, sweeping the steps.', isEnding: false),
    NovelScene(id: 'mountain-2', novelId: '44444444-4444-4444-4444-444444444444', title: 'The Waterfall Dojo', content: 'After a taxing climb, you reach the middle tier dojo. A freezing waterfall crashes nearby. The monk instructs you to take position. This will test your endurance.', isEnding: false),
    NovelScene(id: 'mountain-3', novelId: '44444444-4444-4444-4444-444444444444', title: 'The Summit Trial', content: 'You reach the misty peaks. The wind howls. The elder monk turns to face you in a mock turn-based sparring contest. How will you respond to his sudden stance?', isEnding: false),
    NovelScene(id: 'mountain-end-1', novelId: '44444444-4444-4444-4444-444444444444', title: 'Ending: Master of Flow', content: 'Using sheer physical strength, you match the elder monk strike for strike. He nods in respect. You have conquered the Mount of Flow, gaining great power and discipline!', isEnding: true),
    NovelScene(id: 'mountain-end-2', novelId: '44444444-4444-4444-4444-444444444444', title: 'Ending: Master of Shadows', content: 'Dodging his strikes with sharp mental awareness, you strike when he is off balance. The elder smiles. You have mastered agility and reflex!', isEnding: true),
    NovelScene(id: 'mountain-end-3', novelId: '44444444-4444-4444-4444-444444444444', title: 'Ending: Master of Peace', content: 'You do not fight back, simply deflecting with perfect harmony. The monk bows. True strength is non-violence. You have unlocked spiritual harmony!', isEnding: true),
    
    // Shifting Archives
    NovelScene(id: 'archive-1', novelId: '55555555-5555-5555-5555-555555555555', title: 'The Gate of Riddles', content: 'You stand before massive bronze doors. They are carved with mathematical sequences. A plaque reads: "Only the focused mind may unlock the keys."', isEnding: false),
    NovelScene(id: 'archive-2', novelId: '55555555-5555-5555-5555-555555555555', title: 'The Observatory', content: 'The doors slide open, revealing an enormous telescope pointed at a ceiling projection of stars. Piles of maps lie scattered.', isEnding: false),
    NovelScene(id: 'archive-3', novelId: '55555555-5555-5555-5555-555555555555', title: 'The Final Crypt', content: 'You reach the central sanctum. A shifting stone wheel blocks your path. You must solve the puzzle before the chamber locks down.', isEnding: false),
    NovelScene(id: 'archive-end-1', novelId: '55555555-5555-5555-5555-555555555555', title: 'Ending: Sage of Light', content: 'Through supreme logical deduction, you align the stone segments instantly. The chamber glows with knowledge. You have unlocked cosmic wisdom!', isEnding: true),
    NovelScene(id: 'archive-end-2', novelId: '55555555-5555-5555-5555-555555555555', title: 'Ending: Creator of Order', content: 'You manually turn the heavy gears, forcing the lock in a display of physical power. The door opens. You master practical engineering!', isEnding: true),
    NovelScene(id: 'archive-end-3', novelId: '55555555-5555-5555-5555-555555555555', title: 'Ending: Seer of Hearts', content: 'You close your eyes and feel the patterns of the creators, using empathy to align the crystals. The doors open softly. You master intuition!', isEnding: true),

    // Echoing Village
    NovelScene(id: 'village-1', novelId: '66666666-6666-6666-6666-666666666666', title: 'Arriving in Oakhaven', content: 'The village of Oakhaven is quiet. An elderly farmer is struggling to haul dry hay into a barn before the rain starts.', isEnding: false),
    NovelScene(id: 'village-2', novelId: '66666666-6666-6666-6666-666666666666', title: 'The Town Dispute', content: 'In the marketplace, a baker and a woodworker are shouting over property lines. The villagers are gathering, tension rising.', isEnding: false),
    NovelScene(id: 'village-3', novelId: '66666666-6666-6666-6666-666666666666', title: 'The Sudden Fire', content: 'A fire breaks out in the dry storage barn. Panic erupts. The village does not have a formal brigade. You must lead the response.', isEnding: false),
    NovelScene(id: 'village-end-1', novelId: '66666666-6666-6666-6666-666666666666', title: 'Ending: Hero of Valour', content: 'You rush into the burning building to save the farmer\'s records. You emerge safely, hailed as a champion of physical courage!', isEnding: true),
    NovelScene(id: 'village-end-2', novelId: '66666666-6666-6666-6666-666666666666', title: 'Ending: Organizer of Grace', content: 'You coordinate a bucket brigade quickly, planning the path to the well. The fire is quenched with zero injuries. You are praised as a leader!', isEnding: true),
    NovelScene(id: 'village-end-3', novelId: '66666666-6666-6666-6666-666666666666', title: 'Ending: Heart of Oakhaven', content: 'You calm the screaming children and direct families safely. Reassuring everyone, you lead a communal healing. You have earned everlasting trust!', isEnding: true),
  ];

  static const List<NovelChoice> _staticChoices = [
    // Mountain Choices
    NovelChoice(id: 'm-c1', sceneId: 'mountain-1', choiceText: 'Climb the steep steps vigorously (+2 Physical)', targetSceneId: 'mountain-2', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 2, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'm-c2', sceneId: 'mountain-1', choiceText: 'Help the old monk sweep first (+2 Ethical/Emotional)', targetSceneId: 'mountain-2', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 0, rewardMental: 0, rewardEthical: 2),
    NovelChoice(id: 'm-c3', sceneId: 'mountain-2', choiceText: 'Stand directly under the freezing waterfall (+3 Physical)', targetSceneId: 'mountain-3', requiredPhysical: 10, requiredMental: 0, requiredEthical: 0, rewardPhysical: 3, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'm-c4', sceneId: 'mountain-2', choiceText: 'Breathe deeply and reflect on the dojo (+2 Mental)', targetSceneId: 'mountain-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 0, rewardMental: 2, rewardEthical: 0),
    NovelChoice(id: 'm-c5', sceneId: 'mountain-3', choiceText: 'Deliver a powerful, direct strike (Requires Physical >= 13)', targetSceneId: 'mountain-end-1', requiredPhysical: 13, requiredMental: 0, requiredEthical: 0, rewardPhysical: 3, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'm-c6', sceneId: 'mountain-3', choiceText: 'Outmaneuver with strategy (Requires Mental >= 12)', targetSceneId: 'mountain-end-2', requiredPhysical: 0, requiredMental: 12, requiredEthical: 0, rewardPhysical: 0, rewardMental: 3, rewardEthical: 0),
    NovelChoice(id: 'm-c7', sceneId: 'mountain-3', choiceText: 'Redirect force with empathy (Requires Ethical/Emotional >= 11)', targetSceneId: 'mountain-end-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 11, rewardPhysical: 0, rewardMental: 0, rewardEthical: 3),

    // Archive Choices
    NovelChoice(id: 'a-c1', sceneId: 'archive-1', choiceText: 'Analyze the mathematical puzzle carefully (+2 Mental)', targetSceneId: 'archive-2', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 0, rewardMental: 2, rewardEthical: 0),
    NovelChoice(id: 'a-c2', sceneId: 'archive-1', choiceText: 'Force open the rusty gate (+1 Physical)', targetSceneId: 'archive-2', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 1, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'a-c3', sceneId: 'archive-2', choiceText: 'Decipher the stellar star charts (+2 Mental)', targetSceneId: 'archive-3', requiredPhysical: 0, requiredMental: 10, requiredEthical: 0, rewardPhysical: 0, rewardMental: 2, rewardEthical: 0),
    NovelChoice(id: 'a-c4', sceneId: 'archive-2', choiceText: 'Tidy up the messy scrolls (+2 Ethical/Emotional)', targetSceneId: 'archive-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 0, rewardMental: 0, rewardEthical: 2),
    NovelChoice(id: 'a-c5', sceneId: 'archive-3', choiceText: 'Solve the mechanism logically (Requires Mental >= 13)', targetSceneId: 'archive-end-1', requiredPhysical: 0, requiredMental: 13, requiredEthical: 0, rewardPhysical: 0, rewardMental: 3, rewardEthical: 0),
    NovelChoice(id: 'a-c6', sceneId: 'archive-3', choiceText: 'Push the shifting wheel with power (Requires Physical >= 11)', targetSceneId: 'archive-end-2', requiredPhysical: 11, requiredMental: 0, requiredEthical: 0, rewardPhysical: 2, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'a-c7', sceneId: 'archive-3', choiceText: 'Feel the mechanism intuitively (Requires Ethical/Emotional >= 12)', targetSceneId: 'archive-end-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 12, rewardPhysical: 0, rewardMental: 0, rewardEthical: 3),

    // Village Choices
    NovelChoice(id: 'v-c1', sceneId: 'village-1', choiceText: 'Haul the hay with strength (+2 Physical)', targetSceneId: 'village-2', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 2, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'v-c2', sceneId: 'village-1', choiceText: 'Greet the farmer and offer words of comfort (+2 Ethical/Emotional)', targetSceneId: 'village-2', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 0, rewardMental: 0, rewardEthical: 2),
    NovelChoice(id: 'v-c3', sceneId: 'village-2', choiceText: 'Mediate the dispute with empathy (+2 Ethical/Emotional)', targetSceneId: 'village-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 10, rewardPhysical: 0, rewardMental: 0, rewardEthical: 2),
    NovelChoice(id: 'v-c4', sceneId: 'village-2', choiceText: 'Examine the property maps carefully (+2 Mental)', targetSceneId: 'village-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 0, rewardPhysical: 0, rewardMental: 2, rewardEthical: 0),
    NovelChoice(id: 'v-c5', sceneId: 'village-3', choiceText: 'Rush into the barn to save trapped animals (Requires Physical >= 12)', targetSceneId: 'village-end-1', requiredPhysical: 12, requiredMental: 0, requiredEthical: 0, rewardPhysical: 3, rewardMental: 0, rewardEthical: 0),
    NovelChoice(id: 'v-c6', sceneId: 'village-3', choiceText: 'Organize a quick bucket brigade (Requires Mental >= 12)', targetSceneId: 'village-end-2', requiredPhysical: 0, requiredMental: 12, requiredEthical: 0, rewardPhysical: 0, rewardMental: 3, rewardEthical: 0),
    NovelChoice(id: 'v-c7', sceneId: 'village-3', choiceText: 'Calm the panicked townspeople (Requires Ethical/Emotional >= 13)', targetSceneId: 'village-end-3', requiredPhysical: 0, requiredMental: 0, requiredEthical: 13, rewardPhysical: 0, rewardMental: 0, rewardEthical: 3),
  ];
}
