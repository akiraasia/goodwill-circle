class Profile {
  final String id;
  final String? name;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.name,
    this.photoUrl,
    this.bio,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (bio != null) 'bio': bio,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({String? name, String? photoUrl, String? bio}) {
    return Profile(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
    );
  }
}
