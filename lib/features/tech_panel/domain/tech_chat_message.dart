class TechChatMessage {
  const TechChatMessage({
    required this.id,
    required this.senderName,
    required this.senderId,
    required this.message,
    required this.isUrgent,
    required this.createdAt,
  });

  final int id;
  final String senderName;
  final int senderId;
  final String message;
  final bool isUrgent;
  final DateTime createdAt;

  factory TechChatMessage.fromJson(Map<String, dynamic> json) {
    return TechChatMessage(
      id: json['id'] as int,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      senderId: json['sender_id'] as int,
      message: json['message'] as String? ?? '',
      isUrgent: json['is_urgent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
