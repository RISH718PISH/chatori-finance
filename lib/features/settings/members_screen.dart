import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/permissions.dart';
import '../../data/supabase/auth_repository.dart';
import '../transaction/transaction_providers.dart';

/// Owner-only. Add people, change roles, remove members.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(businessMemberListProvider);
    final myUid = ref.watch(authRepoProvider).currentUser?.id;
    final myRole = ref.watch(myRoleProvider);

    if (myRole != Role.owner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: const Center(child: Text('Only an owner can manage members.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMember(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add member'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(businessMemberListProvider);
            try {
              await ref.read(businessMemberListProvider.future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (final m in members)
                _MemberTile(
                  member: m,
                  isMe: m.userId == myUid,
                  onChangeRole: (r) => _changeRole(context, ref, m, r),
                  onRemove: () => _remove(context, ref, m),
                ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabelUpper('What the roles mean'),
                      const SizedBox(height: 10),
                      for (final r in kAssignableRoles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                  r == Role.owner
                                      ? Icons.shield_outlined
                                      : Icons.restaurant_outlined,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(r.label,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text(r.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final emailCtl = TextEditingController();
    var role = Role.chef;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a member',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const LabelUpper('Role'),
              const SizedBox(height: 8),
              for (final r in kAssignableRoles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(role == r
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
                  title: Text(r.label),
                  subtitle: Text(r.description),
                  onTap: () => setSheet(() => role = r),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );

    final email = emailCtl.text.trim();
    if (ok != true || email.isEmpty) return;

    try {
      final result = await ref
          .read(authRepoProvider)
          .addOrInviteMember(email: email, role: role);
      ref.invalidate(businessMemberListProvider);
      ref.invalidate(businessMembersProvider);
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSemantics.income,
        content: Text(
          switch (result) {
            'added' => '$email added as ${role.label} ✓',
            'updated' => '$email is now ${role.label} ✓',
            // They have no account yet, so this is a pending invite. Say so
            // plainly — otherwise the owner expects them in the list.
            _ => '$email has no account yet. They will join as '
                '${role.label} when they sign up.',
          },
          style: const TextStyle(color: Colors.white),
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not add: ${_clean(e)}')));
    }
  }

  Future<void> _changeRole(
      BuildContext context, WidgetRef ref, BusinessMember m, Role r) async {
    final messenger = ScaffoldMessenger.of(context);
    final who = m.displayName?.isNotEmpty == true ? m.displayName! : 'member';
    try {
      await ref
          .read(authRepoProvider)
          .setMemberRole(targetUserId: m.userId, role: r);
      ref.invalidate(businessMemberListProvider);
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$who is now ${r.label}. '
            'They will see the change next time they open the app.'),
      ));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not change role: ${_clean(e)}')));
    }
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, BusinessMember m) async {
    final who = m.displayName?.isNotEmpty == true ? m.displayName! : 'member';
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $who?'),
        content: const Text(
            'They lose access immediately. Entries they already added stay '
            'in your books.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppSemantics.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepoProvider).removeMember(m.userId);
      ref.invalidate(businessMemberListProvider);
      ref.invalidate(businessMembersProvider);
      messenger.showSnackBar(SnackBar(content: Text('$who removed')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not remove: ${_clean(e)}')));
    }
  }

  /// Postgres raises our guard rails as exceptions; show the message, not
  /// the wrapper noise around it.
  String _clean(Object e) {
    final s = e.toString();
    final m = RegExp(r'message: ([^,}]+)').firstMatch(s);
    return m?.group(1)?.trim() ?? s;
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.onChangeRole,
    required this.onRemove,
  });

  final BusinessMember member;
  final bool isMe;
  final ValueChanged<Role> onChangeRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = member.displayName?.isNotEmpty == true
        ? member.displayName!
        : 'Unnamed member';
    final isOwner = member.role == Role.owner;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isOwner ? AppSemantics.income : Colors.blue)
              .withValues(alpha: 0.15),
          child: Icon(
            isOwner ? Icons.shield_outlined : Icons.restaurant_outlined,
            color: isOwner ? AppSemantics.income : Colors.blue,
          ),
        ),
        title: Text(isMe ? '$name (you)' : name),
        subtitle: Text(member.role.label),
        trailing: isMe
            // Self-demotion is blocked in the RPC too; hiding the menu
            // avoids offering an action that can only fail.
            ? const Icon(Icons.lock_outline, size: 18)
            : PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'remove') return onRemove();
                  onChangeRole(v == 'owner' ? Role.owner : Role.chef);
                },
                itemBuilder: (_) => [
                  for (final r in kAssignableRoles)
                    if (r != member.role)
                      PopupMenuItem(
                        value: r.dbValue,
                        child: Text('Make ${r.label}'),
                      ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from books'),
                  ),
                ],
              ),
      ),
    );
  }
}
