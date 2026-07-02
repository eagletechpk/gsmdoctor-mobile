import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/support_ticket.dart';

class SupportRepository {
  SupportRepository(this._dio);
  final Dio _dio;

  Future<({List<SupportTicket> tickets, int lastPage, int total})> list({
    int page = 1,
    String status = '',
  }) async {
    try {
      final r = await _dio.get('/support', queryParameters: {
        'page': page,
        'per_page': 20,
        if (status.isNotEmpty) 'status': status,
      });
      final data = r.data['data'] as Map<String, dynamic>;
      final meta = r.data['meta'] as Map<String, dynamic>;
      return (
        tickets: (data['tickets'] as List)
            .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<TicketDetail> show(int id) async {
    try {
      final r = await _dio.get('/support/$id');
      final data = r.data['data'] as Map<String, dynamic>;
      return TicketDetail(
        ticket: SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>),
        replies: (data['replies'] as List)
            .map((e) => TicketReply.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<SupportTicket> store({
    required String subject,
    required String message,
    String priority = 'medium',
  }) async {
    try {
      final r = await _dio.post('/support', data: {
        'subject': subject,
        'message': message,
        'priority': priority,
      });
      return SupportTicket.fromJson(
          (r.data['data'] as Map<String, dynamic>)['ticket'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<({TicketReply reply, String ticketStatus})> reply(
      int id, String message, {String? status}) async {
    try {
      final r = await _dio.post('/support/$id/reply', data: {
        'message': message,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      final data = r.data['data'] as Map<String, dynamic>;
      return (
        reply: TicketReply.fromJson(data['reply'] as Map<String, dynamic>),
        ticketStatus: data['ticket_status'] as String? ?? 'open',
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await _dio.post('/support/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
