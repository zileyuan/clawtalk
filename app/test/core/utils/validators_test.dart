import 'package:flutter_test/flutter_test.dart';

import 'package:clawtalk/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('required', () {
      test('should return error for null value', () {
        final result = Validators.required(null);
        expect(result, isNotNull);
      });

      test('should return error for empty string', () {
        final result = Validators.required('');
        expect(result, isNotNull);
      });

      test('should return error for whitespace-only string', () {
        final result = Validators.required('   ');
        expect(result, isNotNull);
      });

      test('should return null for valid string', () {
        final result = Validators.required('valid');
        expect(result, isNull);
      });
    });

    group('host', () {
      test('should return error for empty host', () {
        final result = Validators.host('');
        expect(result, isNotNull);
      });

      test('should return error for host with protocol', () {
        final result = Validators.host('http://localhost');
        expect(result, contains('protocol'));
      });

      test('should return error for host with path', () {
        final result = Validators.host('localhost/path');
        expect(result, contains('path'));
      });

      test('should return null for valid host', () {
        final result = Validators.host('localhost');
        expect(result, isNull);
      });

      test('should return null for IP address', () {
        final result = Validators.host('192.168.1.1');
        expect(result, isNull);
      });
    });

    group('port', () {
      test('should return error for empty port', () {
        final result = Validators.port('');
        expect(result, isNotNull);
      });

      test('should return error for non-numeric port', () {
        final result = Validators.port('abc');
        expect(result, contains('number'));
      });

      test('should return error for port below range', () {
        final result = Validators.port('0');
        expect(result, contains('between'));
      });

      test('should return error for port above range', () {
        final result = Validators.port('70000');
        expect(result, contains('between'));
      });

      test('should return null for valid port', () {
        final result = Validators.port('18789');
        expect(result, isNull);
      });
    });

    group('connectionName', () {
      test('should return error for short name', () {
        final result = Validators.connectionName('a');
        expect(result, contains('2 characters'));
      });

      test('should return error for long name', () {
        final result = Validators.connectionName('a' * 51);
        expect(result, contains('50 characters'));
      });

      test('should return null for valid name', () {
        final result = Validators.connectionName('My Connection');
        expect(result, isNull);
      });
    });
  });
}
