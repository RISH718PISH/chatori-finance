// Models for the Salary and Advances modules (Supabase-backed).

class Staff {
  final String id;
  final String name;
  final String? role;
  final int monthlySalaryPaise;
  final bool active;

  const Staff({
    required this.id,
    required this.name,
    this.role,
    this.monthlySalaryPaise = 0,
    this.active = true,
  });

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
        id: j['id'] as String,
        name: j['name'] as String,
        role: j['role'] as String?,
        monthlySalaryPaise: (j['monthly_salary_paise'] as num?)?.toInt() ?? 0,
        active: (j['active_status'] as bool?) ?? true,
      );
}

class SalaryRecord {
  final String id;
  final String? staffId;
  final int amountPaidPaise;
  final String month; // YYYY-MM
  final DateTime paymentDate;
  final String paymentMode;

  const SalaryRecord({
    required this.id,
    required this.staffId,
    required this.amountPaidPaise,
    required this.month,
    required this.paymentDate,
    required this.paymentMode,
  });

  factory SalaryRecord.fromJson(Map<String, dynamic> j) => SalaryRecord(
        id: j['id'] as String,
        staffId: j['staff_id'] as String?,
        amountPaidPaise: (j['amount_paid_paise'] as num).toInt(),
        month: j['month'] as String,
        paymentDate: DateTime.parse(j['payment_date'] as String),
        paymentMode: j['payment_mode'] as String,
      );
}

class Advance {
  final String id;
  final String personName;
  final String personType; // staff | vendor | helper | other
  final int amountPaise;
  final int recoveredPaise;
  final String status; // open | partial | closed
  final DateTime date;
  final String? reason;
  final String? linkedStaffId;

  const Advance({
    required this.id,
    required this.personName,
    required this.personType,
    required this.amountPaise,
    required this.recoveredPaise,
    required this.status,
    required this.date,
    this.reason,
    this.linkedStaffId,
  });

  int get outstandingPaise => (amountPaise - recoveredPaise).clamp(0, amountPaise);

  factory Advance.fromJson(Map<String, dynamic> j) => Advance(
        id: j['id'] as String,
        personName: j['person_name'] as String,
        personType: j['person_type'] as String,
        amountPaise: (j['amount_paise'] as num).toInt(),
        recoveredPaise: (j['recovered_amount_paise'] as num?)?.toInt() ?? 0,
        status: (j['status'] as String?) ?? 'open',
        date: DateTime.parse(j['date'] as String),
        reason: j['reason'] as String?,
        linkedStaffId: j['linked_staff_id'] as String?,
      );
}
