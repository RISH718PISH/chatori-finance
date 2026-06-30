import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_lock.dart';
import 'app/auth_gate.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // The project uses the legacy anon (JWT) key, which is correct here.
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: ChatoriApp()));
}

class ChatoriApp extends StatelessWidget {
  const ChatoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chatori Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
      builder: (context, child) => AppLockGate(
        child: AuthGate(child: child ?? const SizedBox()),
      ),
    );
  }
}
