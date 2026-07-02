class TechNotification {
  const TechNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.jobId,
    this.jobNumber,
    this.deviceModel,
    this.sentByName,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final int? jobId;
  final String? jobNumber;
  final String? deviceModel;
  final String? sentByName;

  factory TechNotification.fromJson(Map<String, dynamic> json) {
    return TechNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'reminder',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      jobId: json['job_id'] as int?,
      jobNumber: json['job_number'] as String?,
      deviceModel: json['device_model'] as String?,
      sentByName: json['sent_by_name'] as String?,
    );
  }
}
