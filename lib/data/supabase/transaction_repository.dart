import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/txn.dart';

/// Supabase-backed transaction data access (online-first).
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

  /// Most recent transactions for a business, newest first.
  Future<List<Txn>> recent(String businessId, {int limit = 10}) async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return rows.map(Txn.fromJson).toList();
  }

  /// All transactions on a given calendar day.
  Future<List<Txn>> forDay(String businessId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .gte('occurred_at', start.toUtc().toIso8601String())
        .lt('occurred_at', end.toUtc().toIso8601String())
        .order('occurred_at', ascending: false);
    return rows.map(Txn.fromJson).toList();
  }
}
