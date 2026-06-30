import 'package:drift/drift.dart';

/// All money is stored as integer **paise** (₹1 = 100 paise) to avoid
/// floating-point rounding errors. Format to ₹ only at the UI edge.

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get category => text()();
  TextColumn get subcategory => text().nullable()();
  IntColumn get amountPaise => integer()();
  // PRD field "dateTime"; renamed to avoid colliding with drift's dateTime()
  // column-builder method.
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get paymentMode => text()(); // cash | upi | paytm | bank | other
  TextColumn get partyName => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  // 'manual' | 'screenshot' | 'rules'
  TextColumn get tag => text().nullable()();
  // catering | cloud_kitchen | event | other
  TextColumn get attachmentPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Staff extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text().nullable()();
  IntColumn get monthlySalaryPaise => integer().withDefault(const Constant(0))();
  DateTimeColumn get joinedDate => dateTime().nullable()();
  BoolColumn get activeStatus => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SalaryRecords extends Table {
  TextColumn get id => text()();
  TextColumn get staffId => text().references(Staff, #id)();
  IntColumn get amountPaidPaise => integer()();
  TextColumn get month => text()(); // 'YYYY-MM'
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMode => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get advanceAdjustedPaise =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AdvanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get personName => text()();
  TextColumn get personType => text()(); // staff | vendor | helper | other
  IntColumn get amountPaise => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get reason => text().nullable()();
  IntColumn get recoveredAmountPaise =>
      integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('open'))();
  // open | partial | closed
  TextColumn get linkedStaffId => text().nullable().references(Staff, #id)();
  TextColumn get linkedSalaryRecordId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ScreenshotImports extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  TextColumn get extractedText => text().nullable()();
  IntColumn get extractedAmountPaise => integer().nullable()();
  DateTimeColumn get extractedDate => dateTime().nullable()();
  TextColumn get extractedType => text().nullable()(); // income | expense
  RealColumn get confidenceScore => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // draft | confirmed | discarded
  TextColumn get createdTransactionId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // 'income' | 'expense'
  TextColumn get icon => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
