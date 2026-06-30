import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Persists whether the app lock is enabled. Defaults to **off**; the user can
/// turn it on in Settings (M8). Stored in the OS keystore.
class AppLockStore {
  AppLockStore._();

  static const _storage = FlutterSecureStorage();
  static const _flag = 'chatori_app_lock_enabled';

  static Future<bool> isEnabled() async =>
      (await _storage.read(key: _flag)) == 'true';

  static Future<void> setEnabled(bool value) =>
      _storage.write(key: _flag, value: value ? 'true' : 'false');
}

/// Wraps the app and requires biometric / device-credential auth on cold start
/// when the lock is enabled. When disabled (the default), it passes straight
/// through.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    setState(() => _checking = true);
    final enabled = await AppLockStore.isEnabled();
    if (!enabled) {
      setState(() {
        _unlocked = true;
        _checking = false;
      });
      return;
    }

    bool ok = false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // No biometrics/PIN configured on device — don't lock the user out.
        ok = true;
      } else {
        ok = await _auth.authenticate(
          localizedReason: 'Unlock Chatori Finance',
          persistAcrossBackgrounding: true,
        );
      }
    } catch (_) {
      ok = false;
    }

    setState(() {
      _unlocked = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Chatori Finance is locked'),
            const SizedBox(height: 24),
            if (_checking)
              const CircularProgressIndicator()
            else
              FilledButton(
                onPressed: _evaluate,
                child: const Text('Unlock'),
              ),
          ],
        ),
      ),
    );
  }
}
