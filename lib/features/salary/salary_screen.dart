import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/money.dart';
import '../../data/models/books.dart';
import '../books/books_providers.dart';
import '../transaction/transaction_providers.dart';
import '../widgets/amount_field.dart';

class SalaryScreen extends ConsumerWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider);
    final salary = ref.watch(salaryProvider).asData?.value ?? const <SalaryRecord>[];
    final advances = ref.watch(advancesProvider).asData?.value ?? const <Advance>[];
    final month = currentMonthKey();

    return Scaffold(
      appBar: AppBar(title: const Text('Salaries')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStaff(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add staff'),
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (staff) {
          if (staff.isEmpty) {
            return const _Empty(
                icon: Icons.badge_outlined,
                text: 'No staff yet.\nTap "Add staff" to begin.');
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final s in staff)
                _StaffCard(
                  staff: s,
                  paidThisMonth: paidForStaffInMonth(salary, s.id, month),
                  advanceOutstanding: advanceOutstandingForStaff(advances, s.id),
                  onPay: () => _paySalary(
                      context, ref, s, paidForStaffInMonth(salary, s.id, month)),
                  onGiveAdvance: () => _giveAdvance(context, ref, s),
                  onRecover: () => _recoverAdvance(
                      context,
                      ref,
                      s,
                      advances
                          .where((a) =>
                              a.linkedStaffId == s.id && a.status != 'closed')
                          .toList()),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addStaff(BuildContext context, WidgetRef ref) async {
    final nameCtl = TextEditingController();
    final roleCtl = TextEditingController();
    var salaryPaise = 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: roleCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Role (e.g. Cook)'),
              ),
              const SizedBox(height: 12),
              AmountField(
                  label: 'Monthly salary', onChanged: (p) => salaryPaise = p),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || nameCtl.text.trim().isEmpty) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(booksRepoProvider).addStaff(
          businessId: biz,
          name: nameCtl.text.trim(),
          role: roleCtl.text.trim().isEmpty ? null : roleCtl.text.trim(),
          monthlySalaryPaise: salaryPaise,
        );
  }

  Future<void> _paySalary(
      BuildContext context, WidgetRef ref, Staff s, int paid) async {
    final pending = (s.monthlySalaryPaise - paid).clamp(0, s.monthlySalaryPaise);
    var amountPaise = pending;
    var mode = 'Cash';
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Pay ${s.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pending this month: ${Money.format(pending)}'),
                const SizedBox(height: 12),
                AmountField(
                  label: 'Amount to pay',
                  initialPaise: pending,
                  onChanged: (p) => amountPaise = p,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in kPaymentModes)
                      ChoiceChip(
                        label: Text(m),
                        selected: mode == m,
                        onSelected: (_) => setState(() => mode = m),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Pay')),
          ],
        ),
      ),
    );
    if (ok != true || amountPaise <= 0) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(booksRepoProvider).paySalary(
          businessId: biz,
          staffId: s.id,
          amountPaise: amountPaise,
          month: currentMonthKey(),
          paymentMode: mode,
        );
    messenger.showSnackBar(SnackBar(
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      content: Text('Paid ${Money.format(amountPaise)} to ${s.name} ✓',
          style: const TextStyle(color: Colors.white)),
    ));
  }

  Future<void> _giveAdvance(BuildContext context, WidgetRef ref, Staff s) async {
    final reasonCtl = TextEditingController();
    var amountPaise = 0;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Give advance to ${s.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountField(
                  label: 'Advance amount', onChanged: (p) => amountPaise = p),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtl,
                decoration:
                    const InputDecoration(labelText: 'Reason (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Give')),
        ],
      ),
    );
    if (ok != true || amountPaise <= 0) return;
    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    await ref.read(booksRepoProvider).addAdvance(
          businessId: biz,
          personName: s.name,
          personType: 'staff',
          amountPaise: amountPaise,
          reason: reasonCtl.text.trim().isEmpty ? null : reasonCtl.text.trim(),
          linkedStaffId: s.id,
        );
    messenger.showSnackBar(SnackBar(
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      content: Text('Advance ${Money.format(amountPaise)} to ${s.name} ✓',
          style: const TextStyle(color: Colors.white)),
    ));
  }

  /// Recovers an amount against the staff's open advances, oldest first.
  Future<void> _recoverAdvance(BuildContext context, WidgetRef ref, Staff s,
      List<Advance> openAdvances) async {
    final total = openAdvances.fold<int>(0, (sum, a) => sum + a.outstandingPaise);
    var recoverPaise = total;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Recover advance from ${s.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Outstanding advance: ${Money.format(total)}'),
            const SizedBox(height: 12),
            AmountField(
              label: 'Amount to recover / adjust',
              initialPaise: total,
              onChanged: (p) => recoverPaise = p,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Recover')),
        ],
      ),
    );
    if (ok != true || recoverPaise <= 0) return;
    final repo = ref.read(booksRepoProvider);
    var remaining = recoverPaise;
    // Oldest first
    final sorted = [...openAdvances]..sort((a, b) => a.date.compareTo(b.date));
    for (final a in sorted) {
      if (remaining <= 0) break;
      final take = remaining < a.outstandingPaise ? remaining : a.outstandingPaise;
      await repo.recoverAdvance(
        id: a.id,
        totalAmountPaise: a.amountPaise,
        newRecoveredPaise: a.recoveredPaise + take,
      );
      remaining -= take;
    }
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.staff,
    required this.paidThisMonth,
    required this.advanceOutstanding,
    required this.onPay,
    required this.onGiveAdvance,
    required this.onRecover,
  });

  final Staff staff;
  final int paidThisMonth;
  final int advanceOutstanding;
  final VoidCallback onPay;
  final VoidCallback onGiveAdvance;
  final VoidCallback onRecover;

  @override
  Widget build(BuildContext context) {
    final pending = (staff.monthlySalaryPaise - paidThisMonth)
        .clamp(0, staff.monthlySalaryPaise);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    child: Text(staff.name.isNotEmpty ? staff.name[0] : '?')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (staff.role != null)
                        Text(staff.role!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(Money.format(staff.monthlySalaryPaise, decimals: false),
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(context, 'Paid (month)',
                    Money.format(paidThisMonth, decimals: false), Colors.green),
                _stat(context, 'Pending',
                    Money.format(pending, decimals: false),
                    pending > 0 ? Colors.orange : Colors.green),
                _stat(context, 'Advance',
                    Money.format(advanceOutstanding, decimals: false),
                    advanceOutstanding > 0 ? Colors.red : Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (advanceOutstanding > 0)
                  OutlinedButton.icon(
                    onPressed: onRecover,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Recover'),
                  ),
                OutlinedButton.icon(
                  onPressed: onGiveAdvance,
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      size: 18),
                  label: const Text('Give advance'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: onPay,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Pay salary'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      );
}
