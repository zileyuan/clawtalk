import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base64URL encode (no padding, URL-safe)
String _base64UrlEncode(List<int> bytes) {
  return base64Encode(
    bytes,
  ).replaceAll('+', '-').replaceAll('/', '_').replaceAll(RegExp(r'=+$'), '');
}

/// Device identity for Gateway authentication
class DeviceIdentity {
  final String deviceId;
  final List<int> _privateKeyBytes;
  final List<int> _publicKeyBytes;

  const DeviceIdentity._({
    required this.deviceId,
    required List<int> privateKeyBytes,
    required List<int> publicKeyBytes,
  }) : _privateKeyBytes = privateKeyBytes,
       _publicKeyBytes = publicKeyBytes;

  /// Generate a new device identity
  /// Device ID is derived from public key SHA256 fingerprint (OpenClaw format)
  factory DeviceIdentity.generate() {
    final keyPair = ed.generateKey();
    final publicKeyBytes = keyPair.publicKey.bytes;

    // Device ID = SHA256(publicKey) hex string (OpenClaw Gateway requirement)
    final deviceId = sha256.convert(publicKeyBytes).toString();

    return DeviceIdentity._(
      deviceId: deviceId,
      privateKeyBytes: keyPair.privateKey.bytes,
      publicKeyBytes: publicKeyBytes,
    );
  }

  /// Create from stored hex strings
  factory DeviceIdentity.fromHex({
    required String deviceId,
    required String privateKeyHex,
    required String publicKeyHex,
  }) {
    return DeviceIdentity._(
      deviceId: deviceId,
      privateKeyBytes: hex.decode(privateKeyHex),
      publicKeyBytes: hex.decode(publicKeyHex),
    );
  }

  /// Get public key as hex string (for storage)
  String get publicKeyHex => hex.encode(_publicKeyBytes);

  /// Get public key as base64url (for OpenClaw Gateway protocol)
  String get publicKeyBase64Url => _base64UrlEncode(_publicKeyBytes);

  /// Get private key as hex string (for storage)
  String get privateKeyHex => hex.encode(_privateKeyBytes);

  /// Get private key for signing
  ed.PrivateKey get _privateKey => ed.PrivateKey(_privateKeyBytes);

  /// Get public key
  ed.PublicKey get _publicKey => ed.PublicKey(_publicKeyBytes);
}

/// Device signature payload for connect request
class DeviceSignaturePayload {
  final String deviceId;
  final String publicKey;
  final String signature;
  final int signedAt;
  final String nonce;

  const DeviceSignaturePayload({
    required this.deviceId,
    required this.publicKey,
    required this.signature,
    required this.signedAt,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'id': deviceId,
    'publicKey': publicKey,
    'signature': signature,
    'signedAt': signedAt,
    'nonce': nonce,
  };
}

/// Service for managing device identity and signatures
class DeviceIdentityService {
  static const _deviceIdKey = 'gateway_device_id';
  static const _privateKeyKey = 'gateway_private_key';
  static const _publicKeyKey = 'gateway_public_key';

  final FlutterSecureStorage _secureStorage;

  DeviceIdentityService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Load or create device identity
  Future<DeviceIdentity> loadOrCreate() async {
    final existing = await load();
    if (existing != null) {
      return existing;
    }
    final newIdentity = DeviceIdentity.generate();
    await save(newIdentity);
    // If save failed, still return the identity (will be regenerated next time)
    return newIdentity;
  }

  /// Load existing device identity
  Future<DeviceIdentity?> load() async {
    // Try secure storage first
    try {
      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      final privateKeyHex = await _secureStorage.read(key: _privateKeyKey);
      final publicKeyHex = await _secureStorage.read(key: _publicKeyKey);

      if (deviceId != null && privateKeyHex != null && publicKeyHex != null) {
        return DeviceIdentity.fromHex(
          deviceId: deviceId,
          privateKeyHex: privateKeyHex,
          publicKeyHex: publicKeyHex,
        );
      }
    } catch (e) {
      // Secure storage failed, try preferences fallback
    }

    // Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString(_deviceIdKey);
      final privateKeyHex = prefs.getString(_privateKeyKey);
      final publicKeyHex = prefs.getString(_publicKeyKey);

      if (deviceId != null && privateKeyHex != null && publicKeyHex != null) {
        return DeviceIdentity.fromHex(
          deviceId: deviceId,
          privateKeyHex: privateKeyHex,
          publicKeyHex: publicKeyHex,
        );
      }
    } catch (e) {
      // Preferences also failed
    }

    return null;
  }

  /// Save device identity
  Future<void> save(DeviceIdentity identity) async {
    // Try secure storage first
    try {
      await _secureStorage.write(key: _deviceIdKey, value: identity.deviceId);
      await _secureStorage.write(
        key: _privateKeyKey,
        value: identity.privateKeyHex,
      );
      await _secureStorage.write(
        key: _publicKeyKey,
        value: identity.publicKeyHex,
      );
      return; // Success
    } catch (e) {
      // Secure storage failed, try preferences fallback
    }

    // Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceIdKey, identity.deviceId);
      await prefs.setString(_privateKeyKey, identity.privateKeyHex);
      await prefs.setString(_publicKeyKey, identity.publicKeyHex);
    } catch (e) {
      // Both storage methods failed - identity won't persist
    }
  }

  /// Sign a message with device private key
  Uint8List sign(DeviceIdentity identity, Uint8List message) {
    return ed.sign(identity._privateKey, message);
  }

  /// Build device signature payload for connect request
  DeviceSignaturePayload buildSignaturePayload({
    required DeviceIdentity identity,
    required String nonce,
    String clientId = 'cli',
    String clientMode = 'ui',
    String role = 'operator',
    List<String> scopes = const ['operator.read', 'operator.write'],
    String? token,
  }) {
    final signedAt = DateTime.now().millisecondsSinceEpoch;

    // Build the message to sign using OpenClaw v2 format:
    // v2|{deviceId}|{clientId}|{clientMode}|{role}|{scopes}|{signedAtMs}|{token}|{nonce}
    final scopesStr = scopes.join(',');
    final tokenStr = token ?? '';
    final payload =
        'v2|${identity.deviceId}|$clientId|$clientMode|$role|$scopesStr|$signedAt|$tokenStr|$nonce';

    final message = utf8.encode(payload) as Uint8List;
    final signature = sign(identity, message);
    // Signature should be base64url encoded for OpenClaw
    final signatureBase64Url = _base64UrlEncode(signature);

    return DeviceSignaturePayload(
      deviceId: identity.deviceId,
      publicKey: identity.publicKeyBase64Url, // Use base64url for OpenClaw
      signature: signatureBase64Url,
      signedAt: signedAt,
      nonce: nonce,
    );
  }

  /// Clear stored device identity
  Future<void> clear() async {
    try {
      await _secureStorage.delete(key: _deviceIdKey);
      await _secureStorage.delete(key: _privateKeyKey);
      await _secureStorage.delete(key: _publicKeyKey);
    } catch (e) {
      // Ignore errors
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      await prefs.remove(_privateKeyKey);
      await prefs.remove(_publicKeyKey);
    } catch (e) {
      // Ignore errors
    }
  }
}
