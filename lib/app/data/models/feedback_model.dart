class FeedbackModel {
  final String? id;
  final String content;
  final String? contactInfo;
  final String type;
  final DateTime? createdAt;
  final String? userId;

  FeedbackModel({
    this.id,
    required this.content,
    this.contactInfo,
    this.type = 'general',
    this.createdAt,
    this.userId,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      content: json['content'],
      contactInfo: json['contact_info'],
      type: json['type'] ?? 'general',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'content': content,
      if (contactInfo != null) 'contact_info': contactInfo,
      'type': type,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }
}
