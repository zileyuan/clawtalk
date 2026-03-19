import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

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
  factory DeviceIdentity.generate() {
    final keyPair = ed.generateKey();
    return DeviceIdentity._(
      deviceId: const Uuid().v4(),
      privateKeyBytes: keyPair.privateKey.bytes,
      publicKeyBytes: keyPair.publicKey.bytes,
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

  /// Get public key as hex string
  String get publicKeyHex => hex.encode(_publicKeyBytes);

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
    return newIdentity;
  }

  /// Load existing device identity
  Future<DeviceIdentity?> load() async {
    try {
      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      final privateKeyHex = await _secureStorage.read(key: _privateKeyKey);
      final publicKeyHex = await _secureStorage.read(key: _publicKeyKey);

      if (deviceId == null || privateKeyHex == null || publicKeyHex == null) {
        return null;
      }

      return DeviceIdentity.fromHex(
        deviceId: deviceId,
        privateKeyHex: privateKeyHex,
        publicKeyHex: publicKeyHex,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save device identity
  Future<void> save(DeviceIdentity identity) async {
    await _secureStorage.write(key: _deviceIdKey, value: identity.deviceId);
    await _secureStorage.write(
      key: _privateKeyKey,
      value: identity.privateKeyHex,
    );
    await _secureStorage.write(
      key: _publicKeyKey,
      value: identity.publicKeyHex,
    );
  }

  /// Sign a message with device private key
  Uint8List sign(DeviceIdentity identity, Uint8List message) {
    return ed.sign(identity._privateKey, message);
  }

  /// Build device signature payload for connect request
  DeviceSignaturePayload buildSignaturePayload({
    required DeviceIdentity identity,
    required String nonce,
  }) {
    final signedAt = DateTime.now().millisecondsSinceEpoch;

    // Build the message to sign: nonce + signedAt
    final message = _buildSignMessage(nonce: nonce, signedAt: signedAt);

    final signature = sign(identity, message);
    final signatureHex = hex.encode(signature);

    return DeviceSignaturePayload(
      deviceId: identity.deviceId,
      publicKey: identity.publicKeyHex,
      signature: signatureHex,
      signedAt: signedAt,
      nonce: nonce,
    );
  }

  /// Build the message to sign
  Uint8List _buildSignMessage({required String nonce, required int signedAt}) {
    // Message format: nonce:signedAt (matching OpenClaw format)
    final message = '$nonce:$signedAt';
    return utf8.encode(message) as Uint8List;
  }

  /// Clear stored device identity
  Future<void> clear() async {
    await _secureStorage.delete(key: _deviceIdKey);
    await _secureStorage.delete(key: _privateKeyKey);
    await _secureStorage.delete(key: _publicKeyKey);
  }
}
