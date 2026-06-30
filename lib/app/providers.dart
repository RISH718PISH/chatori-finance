import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';

/// The single app-wide database instance. Overridden in `main()` with the
/// concrete encrypted database once the passphrase has been loaded.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);
