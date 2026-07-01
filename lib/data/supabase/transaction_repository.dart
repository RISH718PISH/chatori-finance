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
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> delete(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  /// All transactions in a given month (for reports).
  Future<List<Txn>> fetchForMonth(String businessId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await _client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .gte('occurred_at', start.toUtc().toIso8601String())
        .lt('occurred_at', end.toUtc().toIso8601String())
        .order('occurred_at', ascending: false);
    return rows.map(Txn.fromJson).toList();
  }

  /// Live stream of a business's transactions (newest first). Updates in
  /// real time when anyone in the business adds/edits/deletes an entry.
  Stream<List<Txn>> watchForBusiness(String businessId, {int limit = 500}) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('occurred_at')
        .limit(limit)
        .map((rows) {
          final list = rows.map(Txn.fromJson).toList();
          list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          return list;
        });
  }
}
