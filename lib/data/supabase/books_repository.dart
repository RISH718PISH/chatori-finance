import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/books.dart';

/// Supabase-backed data access for staff, salary payments, and advances.
class BooksRepository {
  BooksRepository(this._client);

  final SupabaseClient _client;

  // ── Staff ──────────────────────────────────────────────────────────
  Stream<List<Staff>> watchStaff(String businessId) {
    return _client
        .from('staff')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('name')
        .map((rows) => rows.map(Staff.fromJson).toList());
  }

  Future<void> addStaff({
    required String businessId,
    required String name,
    String? role,
    int monthlySalaryPaise = 0,
  }) async {
    await _client.from('staff').insert({
      'business_id': businessId,
      'name': name,
      'role': role,
      'monthly_salary_paise': monthlySalaryPaise,
    });
  }

  // ── Salary payments ────────────────────────────────────────────────
  Stream<List<SalaryRecord>> watchSalary(String businessId) {
    return _client
        .from('salary_records')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('payment_date')
        .map((rows) => rows.map(SalaryRecord.fromJson).toList());
  }

  Future<void> paySalary({
    required String businessId,
    required String staffId,
    required int amountPaise,
    required String month, // YYYY-MM
    required String paymentMode,
    DateTime? paymentDate,
  }) async {
    await _client.from('salary_records').insert({
      'business_id': businessId,
      'staff_id': staffId,
      'amount_paid_paise': amountPaise,
      'month': month,
      'payment_date':
          (paymentDate ?? DateTime.now()).toIso8601String().substring(0, 10),
      'payment_mode': paymentMode,
    });
  }

  // ── Advances ───────────────────────────────────────────────────────
  Stream<List<Advance>> watchAdvances(String businessId) {
    return _client
        .from('advance_records')
        .stream(primaryKey: ['id'])
        .eq('business_id', businessId)
        .order('date')
        .map((rows) {
          final list = rows.map(Advance.fromJson).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> addAdvance({
    required String businessId,
    required String personName,
    required String personType,
    required int amountPaise,
    String? reason,
    DateTime? date,
  }) async {
    await _client.from('advance_records').insert({
      'business_id': businessId,
      'person_name': personName,
      'person_type': personType,
      'amount_paise': amountPaise,
      'reason': reason,
      'date': (date ?? DateTime.now()).toIso8601String().substring(0, 10),
      'status': 'open',
    });
  }

  /// Records a recovery against an advance and updates its status.
  Future<void> recoverAdvance({
    required String id,
    required int totalAmountPaise,
    required int newRecoveredPaise,
  }) async {
    final capped = newRecoveredPaise.clamp(0, totalAmountPaise);
    final status = capped <= 0
        ? 'open'
        : (capped >= totalAmountPaise ? 'closed' : 'partial');
    await _client.from('advance_records').update({
      'recovered_amount_paise': capped,
      'status': status,
    }).eq('id', id);
  }
}
