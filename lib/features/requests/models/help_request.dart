class HelpRequest {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String category;
  final String status;
  final int goodwillReward;
  final int volunteersCount;
  final String? imageUrl;
  final String? artAssetPath;
  final DateTime createdAt;
  final bool isCommunityRequest;
  final bool allowJoinNeed;
  final List<String> tags;
  final String? difficulty;
  final String? estimatedPeopleWhoMayBenefit;
  final int helperCount;
  final int goodwillImpactScore;
  final int tagCreditBonus;
  final List<RequestContactOption> contactOptions;
  final RequestContactOption? joinedContactOption;
  final String? communityJoinRole;

  // We might want to join the creator's name/photo
  final String? creatorName;
  final String? creatorPhoto;
  final String? creatorPhone;
  final String? creatorVerificationStatus;
  final String? contactName;
  final String? contactPhoto;
  final String? contactPhone;
  final String? myVolunteerStatus;
  final String? completionMessage;

  HelpRequest({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.goodwillReward,
    required this.volunteersCount,
    this.imageUrl,
    this.artAssetPath,
    required this.createdAt,
    this.isCommunityRequest = false,
    this.allowJoinNeed = false,
    this.tags = const [],
    this.difficulty,
    this.estimatedPeopleWhoMayBenefit,
    this.helperCount = 0,
    this.goodwillImpactScore = 0,
    this.tagCreditBonus = 0,
    this.contactOptions = const [],
    this.joinedContactOption,
    this.communityJoinRole,
    this.creatorName,
    this.creatorPhoto,
    this.creatorPhone,
    this.creatorVerificationStatus,
    this.contactName,
    this.contactPhoto,
    this.contactPhone,
    this.myVolunteerStatus,
    this.completionMessage,
  });

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      goodwillReward: json['goodwill_reward'] as int? ?? 0,
      volunteersCount: json['volunteers_count'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      artAssetPath: json['art_asset_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isCommunityRequest: json['community_request'] as bool? ?? false,
      allowJoinNeed: json['allow_join_need'] as bool? ?? false,
      tags: _stringList(json['tags']),
      difficulty: json['difficulty'] as String?,
      estimatedPeopleWhoMayBenefit:
          json['estimated_people_who_may_benefit'] as String?,
      helperCount: json['helper_count'] as int? ?? 0,
      goodwillImpactScore: json['goodwill_impact_score'] as int? ?? 0,
      tagCreditBonus: json['tag_credit_bonus'] as int? ?? 0,
      contactOptions: _contactOptions(json['contact_options']),
      joinedContactOption: _singleContactOption(json['joined_contact_option']),
      communityJoinRole: json['community_join_role'] as String?,
      creatorName: json['profiles'] != null
          ? json['profiles']['name'] as String?
          : null,
      creatorPhoto: json['profiles'] != null
          ? json['profiles']['photo_url'] as String?
          : null,
      creatorPhone: json['profiles'] != null
          ? json['profiles']['phone'] as String?
          : null,
      creatorVerificationStatus: json['profiles'] != null
          ? json['profiles']['verification_status'] as String?
          : null,
    );
  }

  factory HelpRequest.fromCommunityStarterJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final joinCount = json['join_count'] as int? ?? 0;
    final helperCount = json['helper_count'] as int? ?? 0;

    return HelpRequest(
      id: json['id'] as String? ?? 'starter:${_slug(title)}',
      creatorId: 'community-starter',
      title: title,
      description:
          json['short_description'] as String? ??
          json['full_description'] as String? ??
          '',
      category: json['category'] as String,
      status: json['status'] as String? ?? 'open',
      goodwillReward: json['tag_credit_bonus'] as int? ?? 0,
      volunteersCount: joinCount,
      artAssetPath: json['art_asset_path'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isCommunityRequest: json['community_request'] as bool? ?? true,
      allowJoinNeed: json['allow_join_need'] as bool? ?? true,
      tags: _stringList(json['tags']),
      difficulty: json['difficulty'] as String?,
      estimatedPeopleWhoMayBenefit:
          json['estimated_people_who_may_benefit'] as String?,
      helperCount: helperCount,
      goodwillImpactScore: json['goodwill_impact_score'] as int? ?? 0,
      tagCreditBonus: json['tag_credit_bonus'] as int? ?? 0,
      contactOptions: _contactOptions(json['contact_options']),
      joinedContactOption: _singleContactOption(json['joined_contact_option']),
      communityJoinRole: json['community_join_role'] as String?,
      creatorName: 'Goodwill Circle',
    );
  }

  HelpRequest copyWith({
    String? creatorName,
    String? creatorPhoto,
    String? creatorPhone,
    String? creatorVerificationStatus,
    String? contactName,
    String? contactPhoto,
    String? contactPhone,
    String? myVolunteerStatus,
    String? completionMessage,
    RequestContactOption? joinedContactOption,
    String? communityJoinRole,
  }) {
    return HelpRequest(
      id: id,
      creatorId: creatorId,
      title: title,
      description: description,
      category: category,
      status: status,
      goodwillReward: goodwillReward,
      volunteersCount: volunteersCount,
      imageUrl: imageUrl,
      artAssetPath: artAssetPath,
      createdAt: createdAt,
      isCommunityRequest: isCommunityRequest,
      allowJoinNeed: allowJoinNeed,
      tags: tags,
      difficulty: difficulty,
      estimatedPeopleWhoMayBenefit: estimatedPeopleWhoMayBenefit,
      helperCount: helperCount,
      goodwillImpactScore: goodwillImpactScore,
      tagCreditBonus: tagCreditBonus,
      contactOptions: contactOptions,
      joinedContactOption: joinedContactOption ?? this.joinedContactOption,
      communityJoinRole: communityJoinRole ?? this.communityJoinRole,
      creatorName: creatorName ?? this.creatorName,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
      creatorPhone: creatorPhone ?? this.creatorPhone,
      creatorVerificationStatus:
          creatorVerificationStatus ?? this.creatorVerificationStatus,
      contactName: contactName ?? this.contactName,
      contactPhoto: contactPhoto ?? this.contactPhoto,
      contactPhone: contactPhone ?? this.contactPhone,
      myVolunteerStatus: myVolunteerStatus ?? this.myVolunteerStatus,
      completionMessage: completionMessage ?? this.completionMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'goodwill_reward': goodwillReward,
      'volunteers_count': volunteersCount,
      'image_url': imageUrl,
      'art_asset_path': artAssetPath,
      'created_at': createdAt.toIso8601String(),
      'community_request': isCommunityRequest,
      'allow_join_need': allowJoinNeed,
      'tags': tags,
      'difficulty': difficulty,
      'estimated_people_who_may_benefit': estimatedPeopleWhoMayBenefit,
      'helper_count': helperCount,
      'goodwill_impact_score': goodwillImpactScore,
      'tag_credit_bonus': tagCreditBonus,
      'contact_options': contactOptions.map((option) => option.toJson()).toList(),
      'joined_contact_option': joinedContactOption?.toJson(),
      'community_join_role': communityJoinRole,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static List<RequestContactOption> _contactOptions(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(RequestContactOption.fromJson)
          .toList();
    }
    return const [];
  }

  static RequestContactOption? _singleContactOption(dynamic value) {
    if (value is Map<String, dynamic>) {
      return RequestContactOption.fromJson(value);
    }
    return null;
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class RequestContactOption {
  final String label;
  final String type;
  final String value;
  final String? note;

  const RequestContactOption({
    required this.label,
    required this.type,
    required this.value,
    this.note,
  });

  factory RequestContactOption.fromJson(Map<String, dynamic> json) {
    return RequestContactOption(
      label: json['label'] as String? ?? 'Community contact',
      type: json['type'] as String? ?? 'group',
      value: json['value'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'type': type,
      'value': value,
      if (note != null) 'note': note,
    };
  }
}
