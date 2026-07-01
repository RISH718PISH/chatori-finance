import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/models/books.dart';
import '../books/books_providers.dart';
import '../transaction/transaction_providers.dart';
import '../widgets/amount_field.dart';
import '../widgets/date_field.dart';

class SalaryScreen extends ConsumerWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider);
    final salary =
        ref.watch(salaryProvider).asData?.value ?? const <SalaryRecord>[];
    final advances =
        ref.watch(advancesProvider).asData?.value ?? const <Advance>[];
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
          return RefreshIndicator(
            onRefresh: () async {
              refreshBooks(ref);
              await ref.read(staffProvider.future);
            },
            child: ListView(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (final s in staff)
                Builder(builder: (_) {
                  final paid = paidForStaffInMonth(salary, s.id, month);
                  final adjusted = adjustedForStaffInMonth(salary, s.id, month);
                  final outstanding =
                      advanceOutstandingForStaff(advances, s.id);
                  final openAdvances = advances
                      .where((a) =>
                          a.linkedStaffId == s.id && a.status != 'closed')
                      .toList();
                  final allAdvances = advances
                      .where((a) => a.linkedStaffId == s.id)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  return _StaffCard(
                    staff: s,
                    paid: paid,
                    outstanding: outstanding,
                    netToPay: _netToPay(s.monthlySalaryPaise, paid, adjusted,
                        outstanding),
                    advanceHistory: allAdvances,
                    onPay: () => _paySalary(
                        context, ref, s, paid, adjusted, outstanding,
                        openAdvances),
                    onGiveAdvance: () => _giveAdvance(context, ref, s),
                    onRecover: () =>
                        _recoverAdvance(context, ref, s, openAdvances),
                    onEdit: () => _editStaff(context, ref, s),
                    onDelete: () => _deleteStaff(context, ref, s),
                  );
                }),
            ],
          ),
          );
        },
      ),
    );
  }

  static int _remainingSalary(int monthly, int paid, int adjusted) =>
      (monthly - paid - adjusted).clamp(0, monthly);

  static int _netToPay(int monthly, int paid, int adjusted, int outstanding) {
    final remaining = _remainingSalary(monthly, paid, adjusted);
    return (remaining - outstanding).clamp(0, remaining);
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
    ref.invalidate(staffProvider);
  }

  Future<void> _editStaff(BuildContext context, WidgetRef ref, Staff s) async {
    final nameCtl = TextEditingController(text: s.name);
    final roleCtl = TextEditingController(text: s.role ?? '');
    var salaryPaise = s.monthlySalaryPaise;
    var active = s.active;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: roleCtl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Role')),
                const SizedBox(height: 12),
                AmountField(
                  label: 'Monthly salary',
                  initialPaise: s.monthlySalaryPaise,
                  onChanged: (p) => salaryPaise = p,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
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
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || nameCtl.text.trim().isEmpty) return;
    await ref.read(booksRepoProvider).updateStaff(
          id: s.id,
          name: nameCtl.text.trim(),
          role: roleCtl.text.trim().isEmpty ? null : roleCtl.text.trim(),
          monthlySalaryPaise: salaryPaise,
          active: active,
        );
    ref.invalidate(staffProvider);
    messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${nameCtl.text.trim()} updated')));
  }

  Future<void> _deleteStaff(BuildContext context, WidgetRef ref, Staff s) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${s.name}?'),
        content: const Text(
            'Their salary and advance history stays in your books; only the '
            'staff record is removed. This can\'t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(booksRepoProvider).deleteStaff(s.id);
      ref.invalidate(staffProvider);
      messenger.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${s.name} removed')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not remove: $e')));
    }
  }

  Future<void> _paySalary(BuildContext context, WidgetRef ref, Staff s, int paid,
      int adjusted, int outstanding, List<Advance> openAdvances) async {
    final monthly = s.monthlySalaryPaise;
    final remaining = _remainingSalary(monthly, paid, adjusted);
    final net = _netToPay(monthly, paid, adjusted, outstanding);
    // How much advance can actually be deducted this month.
    final deductable = outstanding.clamp(0, remaining);

    var deductAdvance = deductable > 0;
    var cashPaise = deductAdvance ? net : remaining;
    var payDate = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Pay ${s.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly ${Money.format(monthly)}'),
                Text('Already paid this month: ${Money.format(paid)}'),
                if (deductable > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: deductAdvance,
                      title: Text('Deduct advance (${Money.format(deductable)})'),
                      onChanged: (v) => setState(() {
                        deductAdvance = v ?? false;
                        cashPaise = deductAdvance ? net : remaining;
                      }),
                    ),
                  ),
                const SizedBox(height: 8),
                AmountField(
                  key: ValueKey(deductAdvance),
                  label: 'Pay in cash now',
                  initialPaise: deductAdvance ? net : remaining,
                  onChanged: (p) => cashPaise = p,
                ),
                const SizedBox(height: 12),
                DateField(
                    label: 'Payment date',
                    initial: payDate,
                    onChanged: (d) => payDate = d),
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
    if (ok != true) return;
    final adjustNow = deductAdvance ? deductable : 0;
    if (cashPaise <= 0 && adjustNow <= 0) return;

    final biz = await ref.read(businessIdProvider.future);
    if (biz == null) return;
    final repo = ref.read(booksRepoProvider);

    await repo.paySalary(
      businessId: biz,
      staffId: s.id,
      amountPaise: cashPaise,
      advanceAdjustedPaise: adjustNow,
      month: currentMonthKey(),
      paymentMode: 'Cash',
      paymentDate: payDate,
    );

    // Settle the deducted advance against the staff's open advances (oldest first).
    if (adjustNow > 0) {
      var remainingAdj = adjustNow;
      final sorted = [...openAdvances]..sort((a, b) => a.date.compareTo(b.date));
      for (final a in sorted) {
        if (remainingAdj <= 0) break;
        final take =
            remainingAdj < a.outstandingPaise ? remainingAdj : a.outstandingPaise;
        await repo.recoverAdvance(
          id: a.id,
          totalAmountPaise: a.amountPaise,
          newRecoveredPaise: a.recoveredPaise + take,
        );
        remainingAdj -= take;
      }
    }

    ref.invalidate(salaryProvider);
    ref.invalidate(advancesProvider);

    final msg = adjustNow > 0
        ? 'Paid ${Money.format(cashPaise)} + ${Money.format(adjustNow)} advance adjusted ✓'
        : 'Paid ${Money.format(cashPaise)} to ${s.name} ✓';
    messenger.showSnackBar(SnackBar(
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  Future<void> _giveAdvance(BuildContext context, WidgetRef ref, Staff s) async {
    final reasonCtl = TextEditingController();
    var amountPaise = 0;
    var date = DateTime.now();
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
              DateField(
                  label: 'Date given', initial: date, onChanged: (d) => date = d),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtl,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
          date: date,
        );
    ref.invalidate(advancesProvider);
    messenger.showSnackBar(SnackBar(
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      content: Text('Advance ${Money.format(amountPaise)} to ${s.name} ✓',
          style: const TextStyle(color: Colors.white)),
    ));
  }

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
    final sorted = [...openAdvances]..sort((a, b) => a.date.compareTo(b.date));
    for (final a in sorted) {
      if (remaining <= 0) break;
      final take =
          remaining < a.outstandingPaise ? remaining : a.outstandingPaise;
      await repo.recoverAdvance(
        id: a.id,
        totalAmountPaise: a.amountPaise,
        newRecoveredPaise: a.recoveredPaise + take,
      );
      remaining -= take;
    }
    ref.invalidate(advancesProvider);
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.staff,
    required this.paid,
    required this.outstanding,
    required this.netToPay,
    required this.advanceHistory,
    required this.onPay,
    required this.onGiveAdvance,
    required this.onRecover,
    required this.onEdit,
    required this.onDelete,
  });

  final Staff staff;
  final int paid;
  final int outstanding;
  final int netToPay;
  final List<Advance> advanceHistory;
  final VoidCallback onPay;
  final VoidCallback onGiveAdvance;
  final VoidCallback onRecover;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                      Text(
                          '${staff.role ?? 'Staff'} · ${Money.format(staff.monthlySalaryPaise, decimals: false)}/mo',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(context, 'Paid (month)',
                    Money.format(paid, decimals: false), Colors.green),
                _stat(context, 'Advance',
                    Money.format(outstanding, decimals: false),
                    outstanding > 0 ? Colors.red : Colors.green),
                _stat(context, 'To pay',
                    Money.format(netToPay, decimals: false),
                    netToPay > 0 ? Colors.orange : Colors.green),
              ],
            ),
            if (advanceHistory.isNotEmpty) ...[
              const SizedBox(height: 4),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.event_note, size: 20),
                  title: Text(
                      'Advance history (${advanceHistory.length})',
                      style: Theme.of(context).textTheme.bodyMedium),
                  children: [
                    for (final a in advanceHistory.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              a.status == 'closed'
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: a.status == 'closed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('d MMM yyyy').format(a.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              Money.format(a.amountPaise, decimals: false),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (a.status != 'closed' && a.recoveredPaise > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  '(−${Money.format(a.recoveredPaise, decimals: false)})',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (outstanding > 0)
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
