import 'package:flutter_test/flutter_test.dart';

import 'package:clawtalk/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    group('formatFileSize', () {
      test('should format bytes', () {
        expect(Formatters.formatFileSize(500), '500 B');
      });

      test('should format kilobytes', () {
        expect(Formatters.formatFileSize(1024), '1.0 KB');
        expect(Formatters.formatFileSize(1536), '1.5 KB');
      });

      test('should format megabytes', () {
        expect(Formatters.formatFileSize(1024 * 1024), '1.0 MB');
        expect(Formatters.formatFileSize(2.5 * 1024 * 1024), '2.5 MB');
      });

      test('should format gigabytes', () {
        expect(Formatters.formatFileSize(1024 * 1024 * 1024), '1.0 GB');
      });
    });

    group('formatDuration', () {
      test('should format zero duration', () {
        expect(Formatters.formatDuration(Duration.zero), '00:00');
      });

      test('should format seconds', () {
        expect(Formatters.formatDuration(const Duration(seconds: 30)), '00:30');
      });

      test('should format minutes and seconds', () {
        expect(
          Formatters.formatDuration(const Duration(minutes: 2, seconds: 15)),
          '02:15',
        );
      });

      test('should format hours', () {
        expect(
          Formatters.formatDuration(const Duration(hours: 1, minutes: 30)),
          '90:00',
        );
      });
    });

    group('truncateText', () {
      test('should not truncate short text', () {
        expect(Formatters.truncateText('Hello', 10), 'Hello');
      });

      test('should truncate long text', () {
        expect(Formatters.truncateText('Hello World', 5), 'Hello...');
      });
    });

    group('maskToken', () {
      test('should return empty for null token', () {
        expect(Formatters.maskToken(null), '');
      });

      test('should return empty for empty token', () {
        expect(Formatters.maskToken(''), '');
      });

      test('should mask short token', () {
        expect(Formatters.maskToken('abc'), '****');
      });

      test('should mask long token', () {
        expect(Formatters.maskToken('abcdefghij'), 'abcd...ghij');
      });
    });
  });
}
