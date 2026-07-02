class StaffMember {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? speciality;
  final double? commission;
  final int jobsCount;
  final String? lastLogin;
  final String? createdAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.speciality,
    this.commission,
    required this.jobsCount,
    this.lastLogin,
    this.createdAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: int.parse(json['id'].toString()),
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        status: json['status'] as String,
        speciality: json['speciality'] as String?,
        commission: json['commission'] != null
            ? double.tryParse(json['commission'].toString())
            : null,
        jobsCount: int.tryParse(json['jobs_count']?.toString() ?? '0') ?? 0,
        lastLogin: json['last_login'] as String?,
        createdAt: json['created_at'] as String?,
      );

  String get roleLabel => role[0].toUpperCase() + role.substring(1);
  String get statusLabel => status[0].toUpperCase() + status.substring(1);
}

class PermissionGroup {
  final String group;
  final List<PermissionDef> perms;
  const PermissionGroup({required this.group, required this.perms});
}

class PermissionDef {
  final int id;
  final String key;
  final String label;
  final String group;
  const PermissionDef(
      {required this.id, required this.key, required this.label, required this.group});
  factory PermissionDef.fromJson(Map<String, dynamic> json) => PermissionDef(
        id: int.parse(json['id'].toString()),
        key: json['key'] as String,
        label: json['label'] as String,
        group: json['group'] as String,
      );
}

class StaffPageData {
  final List<StaffMember> staff;
  final List<PermissionGroup> permissionGroups;
  const StaffPageData({required this.staff, required this.permissionGroups});
}

class StaffDetail {
  final StaffMember member;
  final Map<String, bool> permissions;
  const StaffDetail({required this.member, required this.permissions});
}
