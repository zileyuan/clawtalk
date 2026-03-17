import 'failures.dart';
import 'exceptions.dart';

Failure exceptionToFailure(AppException exception) {
  return switch (exception) {
    ConnectionException() => ConnectionFailure(
      message: exception.message,
      code: exception.code,
    ),
    NetworkException() => NetworkFailure(
      message: exception.message,
      code: exception.code,
    ),
    ServerException() => ServerFailure(
      message: exception.message,
      code: exception.code,
    ),
    CacheException() => CacheFailure(
      message: exception.message,
      code: exception.code,
    ),
    ValidationException() => ValidationFailure(
      message: exception.message,
      code: exception.code,
    ),
    PermissionException() => PermissionFailure(
      message: exception.message,
      code: exception.code,
    ),
    MediaException() => MediaFailure(
      message: exception.message,
      code: exception.code,
    ),
    AppException() => Failure(message: exception.message, code: exception.code),
  };
}
