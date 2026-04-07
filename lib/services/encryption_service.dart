// lib/services/encryption_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/errors/failures.dart';

/// Handles all AES encryption/decryption and password hashing.
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static enc.Encrypter? _encrypter;
  static enc.IV? _iv;

  /// Initialise the encrypter with the key from secure storage or .env.
  static Future<void> initialize() async {
    String? keyStr = await _storage.read(key: 'aes_key');
    keyStr ??= dotenv.env['ENCRYPTION_KEY'];

    if (keyStr == null || keyStr.length < 32) {
      throw const EncryptionFailure('Encryption key is missing or invalid.');
    }

    // Derive a 32-byte key from the string
    final keyBytes = utf8.encode(keyStr).sublist(0, 32);
    final key = enc.Key(Uint8List.fromList(keyBytes));

    // Deterministic IV derived from key for simplicity (production: use random per-entry IV)
    final ivBytes = md5.convert(keyBytes).bytes;
    _iv = enc.IV(Uint8List.fromList(ivBytes));

    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    // Persist for future sessions
    await _storage.write(key: 'aes_key', value: keyStr);
  }

  /// Encrypt a plaintext string → base64 cipher text.
  static String encrypt(String plaintext) {
    if (_encrypter == null || _iv == null) {
      throw const EncryptionFailure('Encrypter not initialized.');
    }
    final encrypted = _encrypter!.encrypt(plaintext, iv: _iv!);
    return encrypted.base64;
  }

  /// Decrypt a base64 cipher text → plaintext.
  static String decrypt(String ciphertext) {
    if (_encrypter == null || _iv == null) {
      throw const EncryptionFailure('Encrypter not initialized.');
    }
    final encrypted = enc.Encrypted.fromBase64(ciphertext);
    return _encrypter!.decrypt(encrypted, iv: _iv!);
  }

  /// Hash a password using SHA-256 with a salt.
  /// In production replace with a proper bcrypt library.
  static String hashPassword(String password) {
    final salt = 'linkvault_salt_2024';
    final bytes = utf8.encode(salt + password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a plain password against a stored hash.
  static bool verifyPassword(String plain, String hash) {
    return hashPassword(plain) == hash;
  }

  /// Store the vault password hash in secure storage.
  static Future<void> saveVaultPasswordHash(String hash) async {
    await _storage.write(key: 'vault_password_hash', value: hash);
  }

  /// Retrieve the stored vault password hash.
  static Future<String?> getVaultPasswordHash() async {
    return _storage.read(key: 'vault_password_hash');
  }

  /// Check if a vault master password has been set.
  static Future<bool> hasVaultPassword() async {
    final hash = await getVaultPasswordHash();
    return hash != null && hash.isNotEmpty;
  }

  /// Clear all secure data (e.g. logout).
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
