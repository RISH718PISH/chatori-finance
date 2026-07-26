import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design.dart';
import '../transaction/transaction_providers.dart';

/// What a Head Chef sees.
///
/// Placeholder until the Inventory module lands — this becomes
/// `InventoryScreen`. It exists now rather than later because a chef
/// account is testable today, and landing them on a blank or finance
/// screen would make the role look broken.
///
/// Note what is absent: no money, no reports, no Sections grid, and no
/// route to any of them. That is cosmetic — the real guarantee is that a
/// chef's SELECT on `transactions` returns zero rows.
class ChefHomeScreen extends ConsumerWidget {
  const ChefHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(membershipProvider).asData?.value?.displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Stock'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (name != null && name.isNotEmpty) ...[
            Text('Hello, $name',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Stock tracking is on its way',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Soon you will record what the kitchen uses each day and '
                    'see what is running low, right here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const LabelUpper('What you can do'),
          const SizedBox(height: 8),
          const _Row(Icons.checklist_outlined, 'Record daily usage',
              'Enter what was used from the store'),
          const _Row(Icons.warning_amber_outlined, 'See what is low',
              'Know what to reorder before it runs out'),
          const _Row(Icons.history, 'Check stock history',
              'What came in and what went out'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      enabled: false,
    );
  }
}
