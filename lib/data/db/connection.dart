import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens the encrypted SQLite database. The native library is the
/// SQLite3MultipleCiphers build (selected via the `hooks` section in
/// pubspec.yaml), so `PRAGMA key` encrypts the whole `.db` file (AES). The
/// file is unreadable without [passphrase].
LazyDatabase openEncryptedConnection(String passphrase) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'chatori_finance.db'));

    // Keep temp files inside app-private storage.
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase(
      file,
      setup: (db) {
        // Unlock / initialise encryption before any other access.
        db.execute("PRAGMA key = '$passphrase';");
        // Touch the schema to verify the key is correct.
        db.select('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}
