import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/books.dart';

/// Supabase-backed data access for staff, salary payments, and advances.
class BooksRepository {
  BooksRepository(this._client);

  final SupabaseClient _client;

  // ── Staff ──────────────────────────────────────────────────────────
  Future<List<Staff>> fetchStaff(String businessId) async {
    final rows = await _client
        .from('staff')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return rows.map(Staff.fromJson).toList();
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

  Future<void> updateStaff({
    required String id,
    required String name,
    String? role,
    required int monthlySalaryPaise,
    bool? active,
  }) async {
    await _client.from('staff').update({
      'name': name,
      'role': role,
      'monthly_salary_paise': monthlySalaryPaise,
      'active_status': ?active,
    }).eq('id', id);
  }

  Future<void> deleteStaff(String id) async {
    await _client.from('staff').delete().eq('id', id);
  }

  // ── Salary payments ────────────────────────────────────────────────
  Future<List<SalaryRecord>> fetchSalary(String businessId) async {
    final rows = await _client
        .from('salary_records')
        .select()
        .eq('business_id', businessId);
    return rows.map(SalaryRecord.fromJson).toList();
  }

  Future<void> paySalary({
    required String businessId,
    required String staffId,
    required int amountPaise,
    required String month, // YYYY-MM
    required String paymentMode,
    int advanceAdjustedPaise = 0,
    DateTime? paymentDate,
  }) async {
    await _client.from('salary_records').insert({
      'business_id': businessId,
      'staff_id': staffId,
      'amount_paid_paise': amountPaise,
      'advance_adjusted_paise': advanceAdjustedPaise,
      'month': month,
      'payment_date':
          (paymentDate ?? DateTime.now()).toIso8601String().substring(0, 10),
      'payment_mode': paymentMode,
    });
  }

  /// Removes a salary payment (undo). Note: any advance deduction that was
  /// part of the payment is NOT automatically re-opened on the advance.
  Future<void> deleteSalaryRecord(String id) async {
    await _client.from('salary_records').delete().eq('id', id);
  }

  // ── Advances ───────────────────────────────────────────────────────
  Future<List<Advance>> fetchAdvances(String businessId) async {
    final rows = await _client
        .from('advance_records')
        .select()
        .eq('business_id', businessId)
        .order('date', ascending: false);
    return rows.map(Advance.fromJson).toList();
  }

  Future<void> addAdvance({
    required String businessId,
    required String personName,
    required String personType,
    required int amountPaise,
    String? reason,
    DateTime? date,
    String? linkedStaffId,
  }) async {
    await _client.from('advance_records').insert({
      'business_id': businessId,
      'person_name': personName,
      'person_type': personType,
      'amount_paise': amountPaise,
      'reason': reason,
      'date': (date ?? DateTime.now()).toIso8601String().substring(0, 10),
      'status': 'open',
      'linked_staff_id': linkedStaffId,
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
