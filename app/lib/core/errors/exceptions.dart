abstract class AppException implements Exception {
  final String message;
  final int? code;
  final StackTrace? stackTrace;

  const AppException({required this.message, this.code, this.stackTrace});

  @override
  String toString() => 'AppException: $message';
}

class ConnectionException extends AppException {
  const ConnectionException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class ServerException extends AppException {
  const ServerException({required super.message, super.code, super.stackTrace});
}

class CacheException extends AppException {
  const CacheException({required super.message, super.code, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class MediaException extends AppException {
  const MediaException({required super.message, super.code, super.stackTrace});
}
