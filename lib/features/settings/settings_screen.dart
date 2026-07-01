import 'package:flutter/material.dart';
import '../../core/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_lock.dart';
import '../transaction/transaction_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lockEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppLockStore.isEnabled().then((v) {
      if (mounted) {
        setState(() {
          _lockEnabled = v;
          _loading = false;
        });
      }
    });
  }

  Future<void> _invite() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite to your business'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Their email',
            hintText: 'e.g. ankita@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(authRepoProvider).inviteMember(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$email invited. They\'ll join when they sign up.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not invite: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepoProvider).signOut();
    ref.invalidate(businessIdProvider);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authRepoProvider).currentUser?.email ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('Signed in as'),
                  subtitle: Text(email),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_add_alt),
                  title: const Text('Invite member'),
                  subtitle: const Text('Add Ankita / another owner to these books'),
                  onTap: _invite,
                ),
                SwitchListTile(
                  title: const Text('App lock'),
                  subtitle:
                      const Text('Require fingerprint / PIN to open the app'),
                  secondary: const Icon(Icons.lock_outline),
                  value: _lockEnabled,
                  onChanged: (v) async {
                    await AppLockStore.setEnabled(v);
                    setState(() => _lockEnabled = v);
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Manage categories'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.group_outlined),
                  title: Text('Manage staff'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
                const ListTile(
                  leading: Icon(Icons.backup_outlined),
                  title: Text('Backup & export (CSV)'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppSemantics.expense),
                  title: const Text('Sign out',
                      style: TextStyle(color: AppSemantics.expense)),
                  onTap: _signOut,
                ),
                const AboutListTile(
                  icon: Icon(Icons.info_outline),
                  applicationName: 'Chatori Finance',
                  applicationVersion: 'Cloud sync · 0.2.0',
                ),
              ],
            ),
    );
  }
}
