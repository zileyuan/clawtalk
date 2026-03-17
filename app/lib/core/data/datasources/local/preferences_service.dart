import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../errors/exceptions.dart';

/// Type-safe wrapper for shared_preferences.
///
/// Provides persistent storage for non-sensitive app settings and preferences.
/// Uses platform-specific storage:
/// - iOS: NSUserDefaults
/// - Android: SharedPreferences
/// - macOS: NSUserDefaults
/// - Linux: FileSystem (JSON file in XDG_DATA_HOME)
/// - Windows: Registry
class PreferencesService {
  final SharedPreferences _preferences;

  PreferencesService({required SharedPreferences preferences})
    : _preferences = preferences;

  /// Get SharedPreferences instance.
  static Future<PreferencesService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesService(preferences: preferences);
  }

  /// Read a string value from preferences.
  String? readString(String key) {
    try {
      return _preferences.getString(key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read string from preferences: $e',
        code: 1,
      );
    }
  }

  /// Write a string value to preferences.
  Future<bool> writeString(String key, String value) async {
    try {
      return await _preferences.setString(key, value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write string to preferences: $e',
        code: 2,
      );
    }
  }

  /// Read an integer value from preferences.
  int? readInt(String key) {
    try {
      return _preferences.getInt(key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read int from preferences: $e',
        code: 3,
      );
    }
  }

  /// Write an integer value to preferences.
  Future<bool> writeInt(String key, int value) async {
    try {
      return await _preferences.setInt(key, value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write int to preferences: $e',
        code: 4,
      );
    }
  }

  /// Read a boolean value from preferences.
  bool? readBool(String key) {
    try {
      return _preferences.getBool(key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read bool from preferences: $e',
        code: 5,
      );
    }
  }

  /// Write a boolean value to preferences.
  Future<bool> writeBool(String key, bool value) async {
    try {
      return await _preferences.setBool(key, value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write bool to preferences: $e',
        code: 6,
      );
    }
  }

  /// Read a double value from preferences.
  double? readDouble(String key) {
    try {
      return _preferences.getDouble(key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read double from preferences: $e',
        code: 7,
      );
    }
  }

  /// Write a double value to preferences.
  Future<bool> writeDouble(String key, double value) async {
    try {
      return await _preferences.setDouble(key, value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write double to preferences: $e',
        code: 8,
      );
    }
  }

  /// Read a list of strings from preferences.
  List<String>? readStringList(String key) {
    try {
      return _preferences.getStringList(key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read string list from preferences: $e',
        code: 9,
      );
    }
  }

  /// Write a list of strings to preferences.
  Future<bool> writeStringList(String key, List<String> value) async {
    try {
      return await _preferences.setStringList(key, value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write string list to preferences: $e',
        code: 10,
      );
    }
  }

  /// Read a JSON object from preferences.
  Map<String, dynamic>? readJson(String key) {
    try {
      final jsonString = _preferences.getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read JSON from preferences: $e',
        code: 11,
      );
    }
  }

  /// Write a JSON object to preferences.
  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await _preferences.setString(key, jsonString);
    } catch (e) {
      throw CacheException(
        message: 'Failed to write JSON to preferences: $e',
        code: 12,
      );
    }
  }

  /// Read a DateTime value from preferences.
  DateTime? readDateTime(String key) {
    try {
      final value = _preferences.getString(key);
      if (value == null) return null;
      return DateTime.parse(value);
    } catch (e) {
      throw CacheException(
        message: 'Failed to read DateTime from preferences: $e',
        code: 13,
      );
    }
  }

  /// Write a DateTime value to preferences.
  Future<bool> writeDateTime(String key, DateTime value) async {
    try {
      return await _preferences.setString(key, value.toIso8601String());
    } catch (e) {
      throw CacheException(
        message: 'Failed to write DateTime to preferences: $e',
        code: 14,
      );
    }
  }

  /// Check if a key exists in preferences.
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }

  /// Remove a key from preferences.
  Future<bool> remove(String key) async {
    try {
      return await _preferences.remove(key);
    } catch (e) {
      throw CacheException(
        message: 'Failed to remove key from preferences: $e',
        code: 15,
      );
    }
  }

  /// Clear all preferences.
  Future<bool> clear() async {
    try {
      return await _preferences.clear();
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear preferences: $e',
        code: 16,
      );
    }
  }

  /// Get all keys in preferences.
  Set<String> get keys => _preferences.getKeys();

  /// Reload preferences from disk.
  Future<void> reload() async {
    try {
      await _preferences.reload();
    } catch (e) {
      throw CacheException(
        message: 'Failed to reload preferences: $e',
        code: 17,
      );
    }
  }
}
