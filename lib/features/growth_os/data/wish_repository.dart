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

class Habit {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String virtueName; // 'Discipline', 'Wisdom', 'Compassion', 'Courage', 'Integrity'
  final String frequency; // 'Daily', 'Weekly'
  final int streakDays;
  final bool completedToday;
  final int xpReward;
  final String category; // 'Mind', 'Body', 'Community', 'Character'

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.virtueName,
    this.frequency = 'Daily',
    this.streakDays = 0,
    this.completedToday = false,
    this.xpReward = 15,
    this.category = 'Character',
  });

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        virtueName: json['virtue_name'] as String? ?? 'Discipline',
        frequency: json['frequency'] as String? ?? 'Daily',
        streakDays: json['streak_days'] as int? ?? 0,
        completedToday: json['completed_today'] as bool? ?? false,
        xpReward: json['xp_reward'] as int? ?? 15,
        category: json['category'] as String? ?? 'Character',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'virtue_name': virtueName,
        'frequency': frequency,
        'streak_days': streakDays,
        'completed_today': completedToday,
        'xp_reward': xpReward,
        'category': category,
      };

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? virtueName,
    String? frequency,
    int? streakDays,
    bool? completedToday,
    int? xpReward,
    String? category,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      virtueName: virtueName ?? this.virtueName,
      frequency: frequency ?? this.frequency,
      streakDays: streakDays ?? this.streakDays,
      completedToday: completedToday ?? this.completedToday,
      xpReward: xpReward ?? this.xpReward,
      category: category ?? this.category,
    );
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

  // --- 3. Habit Tracker & Daily Actions ---

  final List<Habit> _mockHabits = [
    Habit(
      id: 'habit-1',
      userId: 'current',
      title: 'Deep Focused Work (30 Mins)',
      description: 'Focus without distraction on your core goals and skill building.',
      virtueName: 'Discipline',
      frequency: 'Daily',
      streakDays: 4,
      completedToday: false,
      xpReward: 20,
      category: 'Mind',
    ),
    Habit(
      id: 'habit-2',
      userId: 'current',
      title: 'Reflect & Read Wisdom Material',
      description: 'Read or listen to inspiring ideas for 15 minutes.',
      virtueName: 'Wisdom',
      frequency: 'Daily',
      streakDays: 7,
      completedToday: true,
      xpReward: 15,
      category: 'Mind',
    ),
    Habit(
      id: 'habit-3',
      userId: 'current',
      title: 'Goodwill Action: Support Someone',
      description: 'Offer assistance, encourage a member, or volunteer in the circle.',
      virtueName: 'Compassion',
      frequency: 'Daily',
      streakDays: 3,
      completedToday: false,
      xpReward: 25,
      category: 'Community',
    ),
    Habit(
      id: 'habit-4',
      userId: 'current',
      title: 'Face Discomfort / Bold Step',
      description: 'Do one thing today that stretches your courage boundary.',
      virtueName: 'Courage',
      frequency: 'Daily',
      streakDays: 2,
      completedToday: false,
      xpReward: 20,
      category: 'Character',
    ),
    Habit(
      id: 'habit-5',
      userId: 'current',
      title: 'Honest Self-Evaluation',
      description: 'Keep promises to yourself and track true progress.',
      virtueName: 'Integrity',
      frequency: 'Daily',
      streakDays: 5,
      completedToday: true,
      xpReward: 15,
      category: 'Character',
    ),
  ];

  Future<List<Habit>> getUserHabits() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _mockHabits;

    if (_isMock) return _mockHabits;

    try {
      final data = await _client
          .from('wish_habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      if (data.isEmpty) return _mockHabits;
      return data.map((json) => Habit.fromJson(json)).toList();
    } catch (e) {
      debugPrint('WishRepository: getUserHabits error: $e');
      return _mockHabits;
    }
  }

  Future<void> toggleHabit(String habitId) async {
    final idx = _mockHabits.indexWhere((h) => h.id == habitId);
    if (idx >= 0) {
      final old = _mockHabits[idx];
      final newCompleted = !old.completedToday;
      final newStreak = newCompleted ? old.streakDays + 1 : (old.streakDays > 0 ? old.streakDays - 1 : 0);
      
      _mockHabits[idx] = old.copyWith(
        completedToday: newCompleted,
        streakDays: newStreak,
      );

      if (newCompleted) {
        await addXpToVirtue(old.virtueName, old.xpReward);
      }
      return;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final habitData = await _client
          .from('wish_habits')
          .select()
          .eq('id', habitId)
          .single();
      final bool wasCompleted = habitData['completed_today'] as bool? ?? false;
      final int currentStreak = habitData['streak_days'] as int? ?? 0;
      final String virtue = habitData['virtue_name'] as String? ?? 'Discipline';
      final int reward = habitData['xp_reward'] as int? ?? 15;

      final newCompleted = !wasCompleted;
      final newStreak = newCompleted ? currentStreak + 1 : (currentStreak > 0 ? currentStreak - 1 : 0);

      await _client.from('wish_habits').update({
        'completed_today': newCompleted,
        'streak_days': newStreak,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', habitId);

      if (newCompleted) {
        await addXpToVirtue(virtue, reward);
      }
    } catch (e) {
      debugPrint('WishRepository: toggleHabit error: $e');
    }
  }

  Future<void> addCustomHabit({
    required String title,
    required String description,
    required String virtueName,
    String frequency = 'Daily',
    int xpReward = 20,
    String category = 'Character',
  }) async {
    final userId = _client.auth.currentUser?.id ?? 'current';
    final newHabit = Habit(
      id: 'habit-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      description: description,
      virtueName: virtueName,
      frequency: frequency,
      streakDays: 1,
      completedToday: false,
      xpReward: xpReward,
      category: category,
    );

    if (_isMock) {
      _mockHabits.add(newHabit);
      return;
    }

    try {
      await _client.from('wish_habits').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'virtue_name': virtueName,
        'frequency': frequency,
        'streak_days': 0,
        'completed_today': false,
        'xp_reward': xpReward,
        'category': category,
      });
    } catch (e) {
      debugPrint('WishRepository: addCustomHabit error: $e');
      _mockHabits.add(newHabit);
    }
  }
