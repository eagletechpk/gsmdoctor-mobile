import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/staff_member.dart';

class StaffRepository {
  final Dio _dio;
  StaffRepository(this._dio);

  Future<StaffPageData> getAll() async {
    try {
      final res = await _dio.get('/staff');
      final data = res.data['data'] as Map<String, dynamic>;

      final staff = (data['staff'] as List)
          .map((m) => StaffMember.fromJson(m as Map<String, dynamic>))
          .toList();

      final rawPerms = data['permissions'] as Map<String, dynamic>? ?? {};
      final groups = rawPerms.entries.map((entry) {
        final perms = (entry.value as List)
            .map((p) => PermissionDef.fromJson(p as Map<String, dynamic>))
            .toList();
        return PermissionGroup(group: entry.key, perms: perms);
      }).toList();

      return StaffPageData(staff: staff, permissionGroups: groups);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<StaffDetail> getOne(int id) async {
    try {
      final res = await _dio.get('/staff/$id');
      final data = res.data['data'] as Map<String, dynamic>;
      final member =
          StaffMember.fromJson(data['staff_member'] as Map<String, dynamic>);
      final perms = Map<String, bool>.from(
          (data['permissions'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v == true)));
      return StaffDetail(member: member, permissions: perms);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? speciality,
    double? commission,
  }) async {
    try {
      await _dio.post('/staff', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
        if (speciality != null) 'speciality': speciality,
        if (commission != null) 'commission': commission,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> update(
    int id, {
    required String name,
    required String email,
    required String role,
    required String status,
    String? phone,
    String? password,
  }) async {
    try {
      await _dio.post('/staff/$id', data: {
        'name': name,
        'email': email,
        'role': role,
        'status': status,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (password != null && password.isNotEmpty) 'password': password,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updatePermissions(int id, Map<String, bool> perms) async {
    try {
      await _dio.post('/staff/$id/permissions', data: {'permissions': perms});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await _dio.post('/staff/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/staff/$id');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
