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

/// Where an event should appear on the list screen, derived from the
/// stored [status] AND the event date compared to *today* (local time).
///
/// Rules:
/// - settled → always Past
/// - done → always Past (event happened; financials may still be open)
/// - upcoming + date is today → Due today
/// - upcoming + date is future → Upcoming
/// - upcoming + date already passed → **Past** (auto-moved out of Upcoming so
///   an event dated yesterday doesn't sit in Upcoming forever)
enum EventSection { dueToday, upcoming, past }

EventSection eventSectionOf(Event e, {DateTime? now}) {
  if (e.status == 'settled' || e.status == 'done') return EventSection.past;
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final d = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
  if (d.isAtSameMomentAs(today)) return EventSection.dueToday;
  if (d.isBefore(today)) return EventSection.past;
  return EventSection.upcoming;
}

/// Sort events for display within their section:
/// - Due today: ascending by time (earliest first — you're likely working now)
/// - Upcoming: ascending by date (nearest first)
/// - Past: descending by date (most recent first)
int compareEventsForSection(Event a, Event b, EventSection section) {
  final byDateAsc = a.eventDate.compareTo(b.eventDate);
  final byDateDesc = -byDateAsc;
  switch (section) {
    case EventSection.dueToday:
    case EventSection.upcoming:
      if (byDateAsc != 0) return byDateAsc;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    case EventSection.past:
      if (byDateDesc != 0) return byDateDesc;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
