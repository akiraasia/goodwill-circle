class Confession {
  final String id;
  final String content;
  final String? imageUrl;
  final int supportCount;
  final bool isSupported;
  final DateTime createdAt;

  Confession({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.supportCount,
    this.isSupported = false,
    required this.createdAt,
  });

  factory Confession.fromJson(Map<String, dynamic> json) {
    return Confession(
      id: json['id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      supportCount: json['support_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Confession copyWith({int? supportCount, bool? isSupported}) {
    return Confession(
      id: id,
      content: content,
      imageUrl: imageUrl,
      supportCount: supportCount ?? this.supportCount,
      isSupported: isSupported ?? this.isSupported,
      createdAt: createdAt,
    );
  }
}
