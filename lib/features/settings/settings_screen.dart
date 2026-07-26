import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_lock.dart';
import '../../core/design.dart';
import '../../core/permissions.dart';
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

  Future<void> _editDisplayName() async {
    // Prefill with whatever the current display name is; falls back to the
    // email prefix (what handle_new_user seeded).
    final auth = ref.read(authRepoProvider);
    final current = await auth.displayName() ?? '';
    if (!mounted) return;
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My display name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'e.g. Rishabh',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await auth.updateMyDisplayName(newName);
      // Refresh the members map so every "added by …" tile updates in place.
      ref.invalidate(businessMembersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Display name set to $newName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepoProvider).signOut();
    // Belt and braces: _sessionUserProvider also clears these on any auth
    // event, which covers the sessions Supabase ends on its own.
    ref.invalidate(membershipProvider);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authRepoProvider).currentUser?.email ?? 'Unknown';
    final role = ref.watch(myRoleProvider);
    final isOwner = role == Role.owner;

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
                  trailing: Chip(
                    label: Text(role.label),
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('My display name'),
                  subtitle: const Text(
                      'Shown as "added by …" on every entry you save'),
                  onTap: _editDisplayName,
                ),
                // Members is owner-only. The RPCs reject a chef anyway, so
                // hiding it avoids offering an action that can only fail.
                if (isOwner)
                  ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Members'),
                    subtitle:
                        const Text('Add people and set what they can see'),
                    onTap: () => context.push('/members'),
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
                if (isOwner) ...[
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.category_outlined),
                    title: Text('Manage categories'),
                    subtitle: Text('Coming soon'),
                    enabled: false,
                  ),
                  const ListTile(
                    leading: Icon(Icons.backup_outlined),
                    title: Text('Backup & export (CSV)'),
                    subtitle: Text('Coming soon'),
                    enabled: false,
                  ),
                ],
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
