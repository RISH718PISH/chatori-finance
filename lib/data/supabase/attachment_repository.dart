import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Stores bill photos. Primary store is the private Supabase Storage bucket
/// `attachments` (path `<business_id>/<uuid>.jpg`, RLS-guarded so only
/// business members can access). If the upload fails (bucket missing,
/// offline), the image is copied into the app documents dir instead and the
/// path is prefixed `local:` — that fallback does NOT sync across devices.
class AttachmentRepository {
  AttachmentRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _bucket = 'attachments';

  /// Returns the stored attachment path (`<biz>/<uuid>.jpg` or `local:<abs>`).
  Future<String?> store({
    required String businessId,
    required String localImagePath,
  }) async {
    final file = File(localImagePath);
    if (!await file.exists()) return null;
    final name = '${_uuid.v4()}${p.extension(localImagePath).isEmpty ? '.jpg' : p.extension(localImagePath)}';
    final remotePath = '$businessId/$name';
    try {
      await _client.storage.from(_bucket).upload(remotePath, file);
      return remotePath;
    } catch (_) {
      // Fallback: keep a private local copy (device-only).
      try {
        final dir = await getApplicationDocumentsDirectory();
        final localDir = Directory(p.join(dir.path, 'attachments'));
        await localDir.create(recursive: true);
        final copied = await file.copy(p.join(localDir.path, name));
        return 'local:${copied.path}';
      } catch (_) {
        return null;
      }
    }
  }

  bool isLocal(String path) => path.startsWith('local:');

  String localFilePath(String path) => path.substring('local:'.length);

  /// Signed URL for a remote attachment (valid 1 hour). Null for local paths
  /// or when the URL can't be created.
  Future<String?> signedUrl(String path) async {
    if (isLocal(path)) return null;
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }
}
