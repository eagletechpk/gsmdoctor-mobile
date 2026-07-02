import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/tech_chat_message.dart';
import '../domain/tech_notification.dart';

class TechPanelData {
  const TechPanelData({required this.technicianName, required this.notifications, required this.unreadCount});

  final String? technicianName;
  final List<TechNotification> notifications;
  final int unreadCount;
}

/// Thin wrapper over Api\V1\TechPanelController. Job-message threads
/// (per-job + general chat) are deferred out of this Phase 1 screen — the
/// notification queue (the higher-frequency workflow per the plan) ships
/// first; chat threads can reuse this repository's pattern in a later pass.
class TechPanelRepository {
  TechPanelRepository(this._dio);

  final Dio _dio;

  Future<TechPanelData> index() async {
    try {
      final response = await _dio.get('/tech-panel');
      final data = response.data['data'] as Map<String, dynamic>;
      final tech = data['technician'] as Map<String, dynamic>?;
      return TechPanelData(
        technicianName: tech?['name'] as String?,
        notifications: (data['notifications'] as List)
            .map((e) => TechNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
        unreadCount: data['unread_count'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.post('/tech-panel/notifications/$id/read');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/tech-panel/notifications/read-all');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> snooze(int id, int minutes) async {
    try {
      await _dio.post('/tech-panel/notifications/$id/snooze', data: {'minutes': minutes});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchTechnicians() async {
    try {
      final response = await _dio.get('/repair-jobs/form-data');
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['technicians'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<TechChatMessage>> fetchGeneralMessages({int lastId = 0, int? technicianId}) async {
    try {
      final response = await _dio.get('/tech-panel/messages', queryParameters: {
        'last_id': lastId,
        'technician_id': technicianId,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['messages'] as List)
          .map((e) => TechChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<TechChatMessage> sendGeneralMessage(String message, {int? technicianId}) async {
    try {
      final response = await _dio.post('/tech-panel/messages', data: {
        'message': message,
        'technician_id': technicianId,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return TechChatMessage.fromJson(data['message_obj'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
