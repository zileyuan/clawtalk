import 'dart:io' show Platform;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../errors/exceptions.dart';

/// Type-safe wrapper for flutter_secure_storage.
///
/// Provides secure storage for sensitive data like tokens and passwords.
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: Keystore with AES encryption
/// - macOS: Keychain
/// - Linux: libsecret
/// - Windows: Credential Manager
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
            mOptions: MacOsOptions(
              // Use default keychain access for sandboxed apps
              synchronizable: false,
            ),
          );

  /// Read a string value from secure storage.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read from secure storage: $e',
        code: 1,
      );
    }
  }

  /// Write a string value to secure storage.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write to secure storage: $e',
        code: 2,
      );
    }
  }

  /// Delete a value from secure storage.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to delete from secure storage: $e',
        code: 3,
      );
    }
  }

  /// Check if a key exists in secure storage.
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to check key existence in secure storage: $e',
        code: 4,
      );
    }
  }

  /// Read all key-value pairs from secure storage.
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw CacheException(
        message: 'Failed to read all from secure storage: $e',
        code: 5,
      );
    }
  }

  /// Delete all key-value pairs from secure storage.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw CacheException(
        message: 'Failed to delete all from secure storage: $e',
        code: 6,
      );
    }
  }

  // Type-safe convenience methods

  /// Read an integer value from secure storage.
  Future<int?> readInt(String key) async {
    final value = await read(key);
    if (value == null) return null;
    final intValue = int.tryParse(value);
    if (intValue == null) {
      throw const CacheException(
        message: 'Failed to parse integer from secure storage',
        code: 7,
      );
    }
    return intValue;
  }

  /// Write an integer value to secure storage.
  Future<void> writeInt(String key, int value) async {
    await write(key, value.toString());
  }

  /// Read a boolean value from secure storage.
  Future<bool?> readBool(String key) async {
    final value = await read(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Write a boolean value to secure storage.
  Future<void> writeBool(String key, bool value) async {
    await write(key, value.toString());
  }

  /// Read a double value from secure storage.
  Future<double?> readDouble(String key) async {
    final value = await read(key);
    if (value == null) return null;
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      throw const CacheException(
        message: 'Failed to parse double from secure storage',
        code: 8,
      );
    }
    return doubleValue;
  }

  /// Write a double value to secure storage.
  Future<void> writeDouble(String key, double value) async {
    await write(key, value.toString());
  }

  /// Read a DateTime value from secure storage.
  Future<DateTime?> readDateTime(String key) async {
    final value = await read(key);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw const CacheException(
        message: 'Failed to parse DateTime from secure storage',
        code: 9,
      );
    }
  }

  /// Write a DateTime value to secure storage.
  Future<void> writeDateTime(String key, DateTime value) async {
    await write(key, value.toIso8601String());
  }
}
