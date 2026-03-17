import 'package:flutter_test/flutter_test.dart';

import 'package:clawtalk/core/errors/failures.dart';
import 'package:clawtalk/core/errors/exceptions.dart';
import 'package:clawtalk/core/errors/error_handler.dart';

void main() {
  group('Failures', () {
    test('ConnectionFailure should contain message and code', () {
      const failure = ConnectionFailure(message: 'Test error', code: 100);

      expect(failure.message, 'Test error');
      expect(failure.code, 100);
    });

    test('Failure toString should include message', () {
      const failure = ConnectionFailure(message: 'Test error');

      expect(failure.toString(), contains('Test error'));
    });
  });

  group('Exceptions', () {
    test('ConnectionException should contain message', () {
      const exception = ConnectionException(message: 'Test exception');

      expect(exception.message, 'Test exception');
    });

    test('AppException toString should include message', () {
      const exception = AppException(message: 'Test');

      expect(exception.toString(), contains('Test'));
    });
  });

  group('ErrorHandler', () {
    test(
      'exceptionToFailure should map ConnectionException to ConnectionFailure',
      () {
        const exception = ConnectionException(message: 'Test', code: 100);
        final failure = exceptionToFailure(exception);

        expect(failure, isA<ConnectionFailure>());
        expect(failure.message, 'Test');
        expect(failure.code, 100);
      },
    );

    test(
      'exceptionToFailure should map NetworkException to NetworkFailure',
      () {
        const exception = NetworkException(message: 'Network error');
        final failure = exceptionToFailure(exception);

        expect(failure, isA<NetworkFailure>());
      },
    );

    test(
      'exceptionToFailure should map ValidationException to ValidationFailure',
      () {
        const exception = ValidationException(message: 'Invalid input');
        final failure = exceptionToFailure(exception);

        expect(failure, isA<ValidationFailure>());
      },
    );
  });
}
