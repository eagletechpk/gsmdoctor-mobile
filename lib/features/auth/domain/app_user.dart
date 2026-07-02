/// Mirrors the `user` payload returned by Api\V1\AuthController (login/me)
/// on the Laravel side, including the precomputed permission map so the app
/// never re-implements User::hasPermission() logic on the client.
class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isAdmin,
    required this.isTechnician,
    required this.defaultLanding,
    required this.permissions,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool isAdmin;
  final bool isTechnician;
  final String defaultLanding;
  final Map<String, bool> permissions;

  bool can(String permissionKey) => permissions[permissionKey] ?? false;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
      isTechnician: json['is_technician'] as bool? ?? false,
      defaultLanding: json['default_landing'] as String? ?? 'dashboard',
      permissions: (json['permissions'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as bool)),
    );
  }
}
