import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class MessageTemplate {
  final int id;
  final String type;
  final String name;
  final String? subject;
  final String body;

  const MessageTemplate({
    required this.id,
    required this.type,
    required this.name,
    this.subject,
    required this.body,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> j) => MessageTemplate(
        id: int.parse(j['id'].toString()),
        type: j['type'] as String,
        name: j['name'] as String,
        subject: j['subject'] as String?,
        body: j['body'] as String,
      );
}

class NotifyTemplatesData {
  final List<MessageTemplate> templates;
  final String phone;
  final String email;
  final String name;

  const NotifyTemplatesData({
    required this.templates,
    required this.phone,
    required this.email,
    required this.name,
  });

  List<MessageTemplate> byType(String type) =>
      templates.where((t) => t.type == type).toList();
}

class NotifyRepository {
  final Dio _dio;
  const NotifyRepository(this._dio);

  Future<NotifyTemplatesData> fetchTemplates({
    required String event,
    int? jobId,
    int? dueId,
    int? crmId,
  }) async {
    final params = <String, dynamic>{'event': event};
    if (jobId != null) params['job_id'] = jobId;
    if (dueId != null) params['due_id'] = dueId;
    if (crmId != null) params['crm_id'] = crmId;

    final res = await _dio.get('/message-templates', queryParameters: params);
    final d = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return NotifyTemplatesData(
      templates: (d['templates'] as List)
          .map((e) => MessageTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      name: d['name'] as String? ?? '',
    );
  }

  Future<void> logNotification({
    required String type,
    required String message,
    required String toPhone,
    String? toName,
    String? reference,
    int? jobId,
    String? subject,
  }) async {
    try {
      await _dio.post('/notify-log', data: {
        'type': type,
        'message': message,
        'to_phone': toPhone,
        if (toName != null) 'to_name': toName,
        if (reference != null) 'reference': reference,
        if (jobId != null) 'job_id': jobId,
        if (subject != null) 'subject': subject,
      });
    } catch (_) {
      // log is best-effort; don't block the UX
    }
  }
}
