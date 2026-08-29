/// Typed error surfaced to the UI. Wrap every network/sensor call in try/catch
/// and map to an [AppException].
class AppException implements Exception {
  const AppException(this.code, this.message, {this.cause});

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException($code): $message';
}

class SensorException extends AppException {
  const SensorException(String message, {super.cause})
      : super('sensor_error', message);
}

class NetworkException extends AppException {
  const NetworkException(String message, {super.cause})
      : super('network_error', message);
}

class AuthException extends AppException {
  const AuthException(String message, {super.cause})
      : super('auth_error', message);
}
