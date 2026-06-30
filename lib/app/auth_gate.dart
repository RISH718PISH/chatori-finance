import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/transaction/transaction_providers.dart';

/// Shows the sign-in screen when no user is authenticated, otherwise the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild on any auth change (sign in / out / token refresh).
    ref.watch(authChangeProvider);
    final user = ref.watch(authRepoProvider).currentUser;
    if (user == null) return const SignInScreen();
    return child;
  }
}
