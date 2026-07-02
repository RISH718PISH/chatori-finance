import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event.dart';
import '../../data/models/txn.dart';
import '../../data/supabase/events_repository.dart';
import '../transaction/transaction_providers.dart';

final eventsRepoProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(ref.watch(supabaseClientProvider)),
);

/// All events for the current business (cached; refreshed after mutations).
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final biz = await ref.watch(businessIdProvider.future);
  if (biz == null) return const [];
  return ref.watch(eventsRepoProvider).fetchAll(biz);
});

/// Transactions linked to a specific event (derived from the business fetch).
final eventTxnsProvider =
    Provider.family<List<Txn>, String>((ref, eventId) {
  final all = ref.watch(businessTxnsProvider).asData?.value ?? const <Txn>[];
  return all.where((t) => t.eventId == eventId).toList();
});

/// P&L summary for one event, derived from its linked transactions.
class EventPnl {
  final int incomePaise;
  final int expensePaise;
  final Map<String, int> expenseByCategory;

  const EventPnl({
    required this.incomePaise,
    required this.expensePaise,
    required this.expenseByCategory,
  });

  int get netPaise => incomePaise - expensePaise;
  double get marginPct =>
      incomePaise == 0 ? 0 : (netPaise / incomePaise) * 100;

  factory EventPnl.fromTxns(Iterable<Txn> txns) {
    var income = 0;
    var expense = 0;
    final byCat = <String, int>{};
    for (final t in txns) {
      if (t.isIncome) {
        income += t.amountPaise;
      } else {
        expense += t.amountPaise;
        byCat.update(t.category, (v) => v + t.amountPaise,
            ifAbsent: () => t.amountPaise);
      }
    }
    return EventPnl(
      incomePaise: income,
      expensePaise: expense,
      expenseByCategory: byCat,
    );
  }
}

final eventPnlProvider = Provider.family<EventPnl, String>((ref, eventId) {
  return EventPnl.fromTxns(ref.watch(eventTxnsProvider(eventId)));
});

void refreshEvents(WidgetRef ref) {
  ref.invalidate(eventsProvider);
}
