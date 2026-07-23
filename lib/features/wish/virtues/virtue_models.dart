/// A single message in a virtue chat room.
class VirtueChatMessage {
  final String id;
  final String virtueName;
  final String senderName;
  final String message;
  final DateTime createdAt;

  const VirtueChatMessage({
    required this.id,
    required this.virtueName,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory VirtueChatMessage.fromJson(Map<String, dynamic> json) {
    return VirtueChatMessage(
      id: json['id'] as String,
      virtueName: json['virtue_name'] as String,
      senderName: json['sender_name'] as String? ?? 'Anonymous',
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A piece of content shared on a virtue materials board.
class VirtueMaterial {
  final String id;
  final String virtueName;
  final String materialType; // 'meme', 'book', 'song', 'video', 'article'
  final String title;
  final String? description;
  final String? url;
  final String? imageUrl;
  final String posterName;
  final int upvotes;
  final DateTime createdAt;

  const VirtueMaterial({
    required this.id,
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

  factory VirtueMaterial.fromJson(Map<String, dynamic> json) {
    return VirtueMaterial(
      id: json['id'] as String,
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
}
