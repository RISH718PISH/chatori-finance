import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and persists the 256-bit SQLCipher passphrase in the OS keystore
/// (Android Keystore via flutter_secure_storage). The key is created once on
/// first launch, never hardcoded, and never leaves the device.
class DbKeyStore {
  DbKeyStore._();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'chatori_db_passphrase_v1';

  static Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) return existing;

    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    // base64Url alphabet has no single quotes, so it is safe to embed in the
    // `PRAGMA key = '...'` statement.
    final key = base64Url.encode(bytes);
    await _storage.write(key: _keyName, value: key);
    return key;
  }
}
