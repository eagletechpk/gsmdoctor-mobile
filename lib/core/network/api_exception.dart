/// Typed wrapper around the backend's {success:false, message, errors}
/// envelope (see app/Http/Responses/ApiResponds.php on the Laravel side),
/// so UI code can catch one exception type instead of inspecting raw Dio
/// responses everywhere.
class ApiException implements Exception {
  ApiException(this.message, {this.errors, this.statusCode});

  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  @override
  String toString() => message;
}
