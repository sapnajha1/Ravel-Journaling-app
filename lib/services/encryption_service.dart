import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Prefix for encrypted content to distinguish from legacy plaintext.
const String _encPrefix = 'enc:v1:';

/// AES-256-GCM algorithm.
final AesGcm _algorithm = AesGcm.with256bits();

/// Client-side encryption for journal content. Uses a per-user key stored in
/// Supabase `user_encryption_keys` table. Protects against casual access and
/// external breaches; key is in Supabase so admins with full access can decrypt.
class EncryptionService {
  EncryptionService(this._client);

  final SupabaseClient _client;

  /// In-memory cache of the encryption key per userId to avoid repeated fetches.
  final Map<String, String> _keyCache = {};

  /// Fetches the user's encryption key from Supabase, or creates one if none exists.
  /// Returns base64-encoded 256-bit key.
  Future<String> getOrCreateKey(String userId) async {
    final cached = _keyCache[userId];
    if (cached != null) return cached;

    try {
      final response = await _client
          .from('user_encryption_keys')
          .select('key')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['key'] != null) {
        final key = response['key']! as String;
        _keyCache[userId] = key;
        return key;
      }

      // Create new key
      final secretKey = await _algorithm.newSecretKey();
      final keyBytes = await secretKey.extractBytes();
      final keyBase64 = base64Encode(keyBytes);

      await _client.from('user_encryption_keys').insert({
        'user_id': userId,
        'key': keyBase64,
      });

      _keyCache[userId] = keyBase64;
      return keyBase64;
    } catch (e, st) {
      debugPrint('[EncryptionService] getOrCreateKey failed: $e');
      debugPrint('[EncryptionService] Stack: $st');
      rethrow;
    }
  }

  /// Encrypts [plaintext] with the user's key. Returns `enc:v1:` + base64(blob).
  Future<String> encrypt(String plaintext, String keyBase64) async {
    if (plaintext.isEmpty) return '';

    final keyBytes = base64Decode(keyBase64);
    if (keyBytes.length != 32) {
      throw ArgumentError('Key must be 32 bytes (256 bits)');
    }

    final secretKey = SecretKey(keyBytes);
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );

    final blob = secretBox.concatenation();
    return _encPrefix + base64Encode(blob);
  }

  /// Decrypts [ciphertext] if it has the `enc:v1:` prefix; otherwise returns as-is (legacy).
  Future<String> decrypt(String ciphertext, String keyBase64) async {
    if (ciphertext.isEmpty) return '';

    if (!ciphertext.startsWith(_encPrefix)) {
      return ciphertext; // Legacy plaintext
    }

    final keyBytes = base64Decode(keyBase64);
    if (keyBytes.length != 32) {
      throw ArgumentError('Key must be 32 bytes (256 bits)');
    }

    final blob = base64Decode(ciphertext.substring(_encPrefix.length));
    final secretBox = SecretBox.fromConcatenation(
      blob,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
      copy: false,
    );

    final secretKey = SecretKey(keyBytes);
    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decrypted);
  }

  /// Clears the in-memory key cache (e.g. on sign out).
  void clearCache() {
    _keyCache.clear();
  }
}
