// Catering event/party model backed by the Supabase `events` table.

class Event {
  final String id;
  final String name;
  final String? customerName;
  final DateTime eventDate;
  final int? guestCount;
  final int quotedAmountPaise;
  final String status; // upcoming | done | settled
  final String? notes;

  const Event({
    required this.id,
    required this.name,
    this.customerName,
    required this.eventDate,
    this.guestCount,
    this.quotedAmountPaise = 0,
    this.status = 'upcoming',
    this.notes,
  });

  bool get isSettled => status == 'settled';

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        id: j['id'] as String,
        name: j['name'] as String,
        customerName: j['customer_name'] as String?,
        eventDate: DateTime.parse(j['event_date'] as String),
        guestCount: (j['guest_count'] as num?)?.toInt(),
        quotedAmountPaise: (j['quoted_amount_paise'] as num?)?.toInt() ?? 0,
        status: (j['status'] as String?) ?? 'upcoming',
        notes: j['notes'] as String?,
      );
}

/// Status progression used by the detail screen's status chip.
const kEventStatuses = ['upcoming', 'done', 'settled'];

String nextEventStatus(String current) {
  final i = kEventStatuses.indexOf(current);
  return kEventStatuses[(i + 1) % kEventStatuses.length];
}
