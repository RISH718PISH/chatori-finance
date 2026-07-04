import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/txn.dart';

/// Supabase-backed transaction data access with real-time streaming.
class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  Future<void> add({
    required String businessId,
    required String type,
    required String category,
    required int amountPaise,
    required String paymentMode,
    DateTime? occurredAt,
    String? partyName,
    String? notes,
    String? tag,
    String source = 'manual',
    String? eventId,
    String? attachmentPath,
    int? cashPaise,
    int? upiPaise,
  }) async {
    await _client.from('transactions').insert({
      'business_id': businessId,
      'type': type,
      'category': category,
      'amount_paise': amountPaise,
      'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      'payment_mode': paymentMode,
      'party_name': partyName,
      'notes': notes,
      'tag': tag,
      'source': source,
      'event_id': eventId,
      'attachment_path': attachmentPath,
      'cash_paise': cashPaise,
      'upi_paise': upiPaise,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> update({
    required String id,
    required String type,
    required String category,
    required int amountPaise,
    required String paymentMode,
    required DateTime occurredAt,
    String? partyName,
    String? notes,
    String? tag,
    String? eventId,
    int? cashPaise,
    int? upiPaise,
  }) async {
    await _client.from('transactions').update({
      'type': type,
      'category': category,
      'amount_paise': amountPaise,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'payment_mode': paymentMode,
      'party_name': partyName,
      'notes': notes,
      'tag': tag,
      'event_id': eventId,
      // When editing to a non-split mode we clear the split columns, else set
      // them explicitly. This keeps the invariant tight.
      'cash_paise': cashPaise,
      'upi_paise': upiPaise,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  /// Duplicate detection: any transactions matching amount + party on the same
  /// calendar day (excluding [excludeId]).
  Future<List<Txn>> findDuplicates({
    required String businessId,
    required int amountPaise,
    required String? partyName,
    required DateTime day,
    String? excludeId,
  }) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    var q = _client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .eq('amount_paise', amountPaise)
        .gte('occurred_at', start.toUtc().toIso8601String())
        .lt('occurred_at', end.toUtc().toIso8601String());
    if (partyName != null && partyName.isNotEmpty) {
      q = q.eq('party_name', partyName);
    }
    if (excludeId != null) q = q.neq('id', excludeId);
    final rows = await q;
    return rows.map(Txn.fromJson).toList();
  }

  // Note: `fetchForMonth` was removed. Report screens now derive month/prev
  // slices from businessTxnsProvider so refreshing one place invalidates
  // Reports too. See `monthTxnsProvider` in reports_providers.dart.

  /// Recent transactions for a business (newest first). Cached one-shot fetch;
  /// refreshed after mutations and on pull-to-refresh.
  Future<List<Txn>> recent(String businessId, {int limit = 500}) async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return rows.map(Txn.fromJson).toList();
  }
}
