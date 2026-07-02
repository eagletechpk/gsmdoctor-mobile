class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.message,
    required this.priority,
    required this.status,
    required this.userId,
    required this.createdAt,
    this.userName,
    this.updatedAt,
  });

  final int id;
  final String ticketNumber;
  final String subject;
  final String message;
  final String priority;
  final String status;
  final int userId;
  final DateTime createdAt;
  final String? userName;
  final DateTime? updatedAt;

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: j['id'] as int,
        ticketNumber: j['ticket_number'] as String? ?? '',
        subject: j['subject'] as String? ?? '',
        message: j['message'] as String? ?? '',
        priority: j['priority'] as String? ?? 'medium',
        status: j['status'] as String? ?? 'open',
        userId: j['user_id'] as int? ?? 0,
        userName: j['user_name'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at'] as String) : null,
      );
}

class TicketReply {
  const TicketReply({
    required this.id,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
    this.userName,
  });

  final int id;
  final String message;
  final bool isAdmin;
  final DateTime createdAt;
  final String? userName;

  factory TicketReply.fromJson(Map<String, dynamic> j) => TicketReply(
        id: j['id'] as int,
        message: j['message'] as String? ?? '',
        isAdmin: j['is_admin'] == true || j['is_admin'] == 1,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        userName: j['user_name'] as String?,
      );
}

class TicketDetail {
  const TicketDetail({required this.ticket, required this.replies});
  final SupportTicket ticket;
  final List<TicketReply> replies;
}
