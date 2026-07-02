import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event.dart';

/// Supabase-backed data access for catering events.
class EventsRepository {
  EventsRepository(this._client);

  final SupabaseClient _client;

  Future<List<Event>> fetchAll(String businessId) async {
    final rows = await _client
        .from('events')
        .select()
        .eq('business_id', businessId)
        .order('event_date', ascending: false);
    return rows.map(Event.fromJson).toList();
  }

  Future<Event?> fetchById(String id) async {
    final rows = await _client.from('events').select().eq('id', id).limit(1);
    if (rows.isEmpty) return null;
    return Event.fromJson(rows.first);
  }

  Future<void> create({
    required String businessId,
    required String name,
    String? customerName,
    required DateTime eventDate,
    int? guestCount,
    int quotedAmountPaise = 0,
    String? notes,
  }) async {
    await _client.from('events').insert({
      'business_id': businessId,
      'name': name,
      'customer_name': customerName,
      'event_date': eventDate.toIso8601String().substring(0, 10),
      'guest_count': guestCount,
      'quoted_amount_paise': quotedAmountPaise,
      'notes': notes,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from('events').update({'status': status}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('events').delete().eq('id', id);
  }
}
