class AIMemory {
  final String id;
  final String userId;
  final String memoryType;
  final String content;
  final double confidenceScore;
  final DateTime createdAt;

  AIMemory({
    required this.id,
    required this.userId,
    required this.memoryType,
    required this.content,
    this.confidenceScore = 1.0,
    required this.createdAt,
  });

  factory AIMemory.fromMap(Map<String, dynamic> map) {
    return AIMemory(
      id: map['id'],
      userId: map['user_id'],
      memoryType: map['memory_type'],
      content: map['content'],
      confidenceScore: (map['confidence_score'] ?? 1.0).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'memory_type': memoryType,
      'content': content,
      'confidence_score': confidenceScore,
    };
  }
}
