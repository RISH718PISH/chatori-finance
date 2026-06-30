// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subcategoryMeta = const VerificationMeta(
    'subcategory',
  );
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
    'subcategory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentModeMeta = const VerificationMeta(
    'paymentMode',
  );
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
    'payment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    category,
    subcategory,
    amountPaise,
    occurredAt,
    paymentMode,
    partyName,
    notes,
    source,
    tag,
    attachmentPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subcategory')) {
      context.handle(
        _subcategoryMeta,
        subcategory.isAcceptableOrUnknown(
          data['subcategory']!,
          _subcategoryMeta,
        ),
      );
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
        _paymentModeMeta,
        paymentMode.isAcceptableOrUnknown(
          data['payment_mode']!,
          _paymentModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentModeMeta);
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subcategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory'],
      ),
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      paymentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_mode'],
      )!,
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String type;
  final String category;
  final String? subcategory;
  final int amountPaise;
  final DateTime occurredAt;
  final String paymentMode;
  final String? partyName;
  final String? notes;
  final String source;
  final String? tag;
  final String? attachmentPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction({
    required this.id,
    required this.type,
    required this.category,
    this.subcategory,
    required this.amountPaise,
    required this.occurredAt,
    required this.paymentMode,
    this.partyName,
    this.notes,
    required this.source,
    this.tag,
    this.attachmentPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(subcategory);
    }
    map['amount_paise'] = Variable<int>(amountPaise);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['payment_mode'] = Variable<String>(paymentMode);
    if (!nullToAbsent || partyName != null) {
      map['party_name'] = Variable<String>(partyName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      category: Value(category),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      amountPaise: Value(amountPaise),
      occurredAt: Value(occurredAt),
      paymentMode: Value(paymentMode),
      partyName: partyName == null && nullToAbsent
          ? const Value.absent()
          : Value(partyName),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<String?>(json['subcategory']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      partyName: serializer.fromJson<String?>(json['partyName']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      tag: serializer.fromJson<String?>(json['tag']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<String?>(subcategory),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'partyName': serializer.toJson<String?>(partyName),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'tag': serializer.toJson<String?>(tag),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith({
    String? id,
    String? type,
    String? category,
    Value<String?> subcategory = const Value.absent(),
    int? amountPaise,
    DateTime? occurredAt,
    String? paymentMode,
    Value<String?> partyName = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? source,
    Value<String?> tag = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    type: type ?? this.type,
    category: category ?? this.category,
    subcategory: subcategory.present ? subcategory.value : this.subcategory,
    amountPaise: amountPaise ?? this.amountPaise,
    occurredAt: occurredAt ?? this.occurredAt,
    paymentMode: paymentMode ?? this.paymentMode,
    partyName: partyName.present ? partyName.value : this.partyName,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
    tag: tag.present ? tag.value : this.tag,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      paymentMode: data.paymentMode.present
          ? data.paymentMode.value
          : this.paymentMode,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      tag: data.tag.present ? data.tag.value : this.tag,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('partyName: $partyName, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('tag: $tag, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    category,
    subcategory,
    amountPaise,
    occurredAt,
    paymentMode,
    partyName,
    notes,
    source,
    tag,
    attachmentPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.type == this.type &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.amountPaise == this.amountPaise &&
          other.occurredAt == this.occurredAt &&
          other.paymentMode == this.paymentMode &&
          other.partyName == this.partyName &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.tag == this.tag &&
          other.attachmentPath == this.attachmentPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> category;
  final Value<String?> subcategory;
  final Value<int> amountPaise;
  final Value<DateTime> occurredAt;
  final Value<String> paymentMode;
  final Value<String?> partyName;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String?> tag;
  final Value<String?> attachmentPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.partyName = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.tag = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String type,
    required String category,
    this.subcategory = const Value.absent(),
    required int amountPaise,
    required DateTime occurredAt,
    required String paymentMode,
    this.partyName = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.tag = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       category = Value(category),
       amountPaise = Value(amountPaise),
       occurredAt = Value(occurredAt),
       paymentMode = Value(paymentMode);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<int>? amountPaise,
    Expression<DateTime>? occurredAt,
    Expression<String>? paymentMode,
    Expression<String>? partyName,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? tag,
    Expression<String>? attachmentPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (partyName != null) 'party_name': partyName,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (tag != null) 'tag': tag,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? category,
    Value<String?>? subcategory,
    Value<int>? amountPaise,
    Value<DateTime>? occurredAt,
    Value<String>? paymentMode,
    Value<String?>? partyName,
    Value<String?>? notes,
    Value<String>? source,
    Value<String?>? tag,
    Value<String?>? attachmentPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      amountPaise: amountPaise ?? this.amountPaise,
      occurredAt: occurredAt ?? this.occurredAt,
      paymentMode: paymentMode ?? this.paymentMode,
      partyName: partyName ?? this.partyName,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      tag: tag ?? this.tag,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('partyName: $partyName, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('tag: $tag, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffTable extends Staff with TableInfo<$StaffTable, StaffData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlySalaryPaiseMeta =
      const VerificationMeta('monthlySalaryPaise');
  @override
  late final GeneratedColumn<int> monthlySalaryPaise = GeneratedColumn<int>(
    'monthly_salary_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _joinedDateMeta = const VerificationMeta(
    'joinedDate',
  );
  @override
  late final GeneratedColumn<DateTime> joinedDate = GeneratedColumn<DateTime>(
    'joined_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeStatusMeta = const VerificationMeta(
    'activeStatus',
  );
  @override
  late final GeneratedColumn<bool> activeStatus = GeneratedColumn<bool>(
    'active_status',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active_status" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    monthlySalaryPaise,
    joinedDate,
    activeStatus,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('monthly_salary_paise')) {
      context.handle(
        _monthlySalaryPaiseMeta,
        monthlySalaryPaise.isAcceptableOrUnknown(
          data['monthly_salary_paise']!,
          _monthlySalaryPaiseMeta,
        ),
      );
    }
    if (data.containsKey('joined_date')) {
      context.handle(
        _joinedDateMeta,
        joinedDate.isAcceptableOrUnknown(data['joined_date']!, _joinedDateMeta),
      );
    }
    if (data.containsKey('active_status')) {
      context.handle(
        _activeStatusMeta,
        activeStatus.isAcceptableOrUnknown(
          data['active_status']!,
          _activeStatusMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaffData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      monthlySalaryPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_salary_paise'],
      )!,
      joinedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_date'],
      ),
      activeStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active_status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StaffTable createAlias(String alias) {
    return $StaffTable(attachedDatabase, alias);
  }
}

class StaffData extends DataClass implements Insertable<StaffData> {
  final String id;
  final String name;
  final String? role;
  final int monthlySalaryPaise;
  final DateTime? joinedDate;
  final bool activeStatus;
  final String? notes;
  final DateTime createdAt;
  const StaffData({
    required this.id,
    required this.name,
    this.role,
    required this.monthlySalaryPaise,
    this.joinedDate,
    required this.activeStatus,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    map['monthly_salary_paise'] = Variable<int>(monthlySalaryPaise);
    if (!nullToAbsent || joinedDate != null) {
      map['joined_date'] = Variable<DateTime>(joinedDate);
    }
    map['active_status'] = Variable<bool>(activeStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StaffCompanion toCompanion(bool nullToAbsent) {
    return StaffCompanion(
      id: Value(id),
      name: Value(name),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      monthlySalaryPaise: Value(monthlySalaryPaise),
      joinedDate: joinedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedDate),
      activeStatus: Value(activeStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory StaffData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String?>(json['role']),
      monthlySalaryPaise: serializer.fromJson<int>(json['monthlySalaryPaise']),
      joinedDate: serializer.fromJson<DateTime?>(json['joinedDate']),
      activeStatus: serializer.fromJson<bool>(json['activeStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String?>(role),
      'monthlySalaryPaise': serializer.toJson<int>(monthlySalaryPaise),
      'joinedDate': serializer.toJson<DateTime?>(joinedDate),
      'activeStatus': serializer.toJson<bool>(activeStatus),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StaffData copyWith({
    String? id,
    String? name,
    Value<String?> role = const Value.absent(),
    int? monthlySalaryPaise,
    Value<DateTime?> joinedDate = const Value.absent(),
    bool? activeStatus,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => StaffData(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role.present ? role.value : this.role,
    monthlySalaryPaise: monthlySalaryPaise ?? this.monthlySalaryPaise,
    joinedDate: joinedDate.present ? joinedDate.value : this.joinedDate,
    activeStatus: activeStatus ?? this.activeStatus,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  StaffData copyWithCompanion(StaffCompanion data) {
    return StaffData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      monthlySalaryPaise: data.monthlySalaryPaise.present
          ? data.monthlySalaryPaise.value
          : this.monthlySalaryPaise,
      joinedDate: data.joinedDate.present
          ? data.joinedDate.value
          : this.joinedDate,
      activeStatus: data.activeStatus.present
          ? data.activeStatus.value
          : this.activeStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('monthlySalaryPaise: $monthlySalaryPaise, ')
          ..write('joinedDate: $joinedDate, ')
          ..write('activeStatus: $activeStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    role,
    monthlySalaryPaise,
    joinedDate,
    activeStatus,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffData &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.monthlySalaryPaise == this.monthlySalaryPaise &&
          other.joinedDate == this.joinedDate &&
          other.activeStatus == this.activeStatus &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class StaffCompanion extends UpdateCompanion<StaffData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> role;
  final Value<int> monthlySalaryPaise;
  final Value<DateTime?> joinedDate;
  final Value<bool> activeStatus;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StaffCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.monthlySalaryPaise = const Value.absent(),
    this.joinedDate = const Value.absent(),
    this.activeStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffCompanion.insert({
    required String id,
    required String name,
    this.role = const Value.absent(),
    this.monthlySalaryPaise = const Value.absent(),
    this.joinedDate = const Value.absent(),
    this.activeStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<StaffData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<int>? monthlySalaryPaise,
    Expression<DateTime>? joinedDate,
    Expression<bool>? activeStatus,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (monthlySalaryPaise != null)
        'monthly_salary_paise': monthlySalaryPaise,
      if (joinedDate != null) 'joined_date': joinedDate,
      if (activeStatus != null) 'active_status': activeStatus,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? role,
    Value<int>? monthlySalaryPaise,
    Value<DateTime?>? joinedDate,
    Value<bool>? activeStatus,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StaffCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      monthlySalaryPaise: monthlySalaryPaise ?? this.monthlySalaryPaise,
      joinedDate: joinedDate ?? this.joinedDate,
      activeStatus: activeStatus ?? this.activeStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (monthlySalaryPaise.present) {
      map['monthly_salary_paise'] = Variable<int>(monthlySalaryPaise.value);
    }
    if (joinedDate.present) {
      map['joined_date'] = Variable<DateTime>(joinedDate.value);
    }
    if (activeStatus.present) {
      map['active_status'] = Variable<bool>(activeStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('monthlySalaryPaise: $monthlySalaryPaise, ')
          ..write('joinedDate: $joinedDate, ')
          ..write('activeStatus: $activeStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalaryRecordsTable extends SalaryRecords
    with TableInfo<$SalaryRecordsTable, SalaryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalaryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES staff (id)',
    ),
  );
  static const VerificationMeta _amountPaidPaiseMeta = const VerificationMeta(
    'amountPaidPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaidPaise = GeneratedColumn<int>(
    'amount_paid_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentModeMeta = const VerificationMeta(
    'paymentMode',
  );
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
    'payment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _advanceAdjustedPaiseMeta =
      const VerificationMeta('advanceAdjustedPaise');
  @override
  late final GeneratedColumn<int> advanceAdjustedPaise = GeneratedColumn<int>(
    'advance_adjusted_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    staffId,
    amountPaidPaise,
    month,
    paymentDate,
    paymentMode,
    notes,
    advanceAdjustedPaise,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'salary_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalaryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    } else if (isInserting) {
      context.missing(_staffIdMeta);
    }
    if (data.containsKey('amount_paid_paise')) {
      context.handle(
        _amountPaidPaiseMeta,
        amountPaidPaise.isAcceptableOrUnknown(
          data['amount_paid_paise']!,
          _amountPaidPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaidPaiseMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
        _paymentModeMeta,
        paymentMode.isAcceptableOrUnknown(
          data['payment_mode']!,
          _paymentModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentModeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('advance_adjusted_paise')) {
      context.handle(
        _advanceAdjustedPaiseMeta,
        advanceAdjustedPaise.isAcceptableOrUnknown(
          data['advance_adjusted_paise']!,
          _advanceAdjustedPaiseMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalaryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalaryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      )!,
      amountPaidPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paid_paise'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}payment_date'],
      )!,
      paymentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_mode'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      advanceAdjustedPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_adjusted_paise'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SalaryRecordsTable createAlias(String alias) {
    return $SalaryRecordsTable(attachedDatabase, alias);
  }
}

class SalaryRecord extends DataClass implements Insertable<SalaryRecord> {
  final String id;
  final String staffId;
  final int amountPaidPaise;
  final String month;
  final DateTime paymentDate;
  final String paymentMode;
  final String? notes;
  final int advanceAdjustedPaise;
  final DateTime createdAt;
  const SalaryRecord({
    required this.id,
    required this.staffId,
    required this.amountPaidPaise,
    required this.month,
    required this.paymentDate,
    required this.paymentMode,
    this.notes,
    required this.advanceAdjustedPaise,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['staff_id'] = Variable<String>(staffId);
    map['amount_paid_paise'] = Variable<int>(amountPaidPaise);
    map['month'] = Variable<String>(month);
    map['payment_date'] = Variable<DateTime>(paymentDate);
    map['payment_mode'] = Variable<String>(paymentMode);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['advance_adjusted_paise'] = Variable<int>(advanceAdjustedPaise);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SalaryRecordsCompanion toCompanion(bool nullToAbsent) {
    return SalaryRecordsCompanion(
      id: Value(id),
      staffId: Value(staffId),
      amountPaidPaise: Value(amountPaidPaise),
      month: Value(month),
      paymentDate: Value(paymentDate),
      paymentMode: Value(paymentMode),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      advanceAdjustedPaise: Value(advanceAdjustedPaise),
      createdAt: Value(createdAt),
    );
  }

  factory SalaryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalaryRecord(
      id: serializer.fromJson<String>(json['id']),
      staffId: serializer.fromJson<String>(json['staffId']),
      amountPaidPaise: serializer.fromJson<int>(json['amountPaidPaise']),
      month: serializer.fromJson<String>(json['month']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      notes: serializer.fromJson<String?>(json['notes']),
      advanceAdjustedPaise: serializer.fromJson<int>(
        json['advanceAdjustedPaise'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'staffId': serializer.toJson<String>(staffId),
      'amountPaidPaise': serializer.toJson<int>(amountPaidPaise),
      'month': serializer.toJson<String>(month),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'notes': serializer.toJson<String?>(notes),
      'advanceAdjustedPaise': serializer.toJson<int>(advanceAdjustedPaise),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SalaryRecord copyWith({
    String? id,
    String? staffId,
    int? amountPaidPaise,
    String? month,
    DateTime? paymentDate,
    String? paymentMode,
    Value<String?> notes = const Value.absent(),
    int? advanceAdjustedPaise,
    DateTime? createdAt,
  }) => SalaryRecord(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    amountPaidPaise: amountPaidPaise ?? this.amountPaidPaise,
    month: month ?? this.month,
    paymentDate: paymentDate ?? this.paymentDate,
    paymentMode: paymentMode ?? this.paymentMode,
    notes: notes.present ? notes.value : this.notes,
    advanceAdjustedPaise: advanceAdjustedPaise ?? this.advanceAdjustedPaise,
    createdAt: createdAt ?? this.createdAt,
  );
  SalaryRecord copyWithCompanion(SalaryRecordsCompanion data) {
    return SalaryRecord(
      id: data.id.present ? data.id.value : this.id,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      amountPaidPaise: data.amountPaidPaise.present
          ? data.amountPaidPaise.value
          : this.amountPaidPaise,
      month: data.month.present ? data.month.value : this.month,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      paymentMode: data.paymentMode.present
          ? data.paymentMode.value
          : this.paymentMode,
      notes: data.notes.present ? data.notes.value : this.notes,
      advanceAdjustedPaise: data.advanceAdjustedPaise.present
          ? data.advanceAdjustedPaise.value
          : this.advanceAdjustedPaise,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalaryRecord(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('amountPaidPaise: $amountPaidPaise, ')
          ..write('month: $month, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('notes: $notes, ')
          ..write('advanceAdjustedPaise: $advanceAdjustedPaise, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    staffId,
    amountPaidPaise,
    month,
    paymentDate,
    paymentMode,
    notes,
    advanceAdjustedPaise,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalaryRecord &&
          other.id == this.id &&
          other.staffId == this.staffId &&
          other.amountPaidPaise == this.amountPaidPaise &&
          other.month == this.month &&
          other.paymentDate == this.paymentDate &&
          other.paymentMode == this.paymentMode &&
          other.notes == this.notes &&
          other.advanceAdjustedPaise == this.advanceAdjustedPaise &&
          other.createdAt == this.createdAt);
}

class SalaryRecordsCompanion extends UpdateCompanion<SalaryRecord> {
  final Value<String> id;
  final Value<String> staffId;
  final Value<int> amountPaidPaise;
  final Value<String> month;
  final Value<DateTime> paymentDate;
  final Value<String> paymentMode;
  final Value<String?> notes;
  final Value<int> advanceAdjustedPaise;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SalaryRecordsCompanion({
    this.id = const Value.absent(),
    this.staffId = const Value.absent(),
    this.amountPaidPaise = const Value.absent(),
    this.month = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.notes = const Value.absent(),
    this.advanceAdjustedPaise = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalaryRecordsCompanion.insert({
    required String id,
    required String staffId,
    required int amountPaidPaise,
    required String month,
    required DateTime paymentDate,
    required String paymentMode,
    this.notes = const Value.absent(),
    this.advanceAdjustedPaise = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       staffId = Value(staffId),
       amountPaidPaise = Value(amountPaidPaise),
       month = Value(month),
       paymentDate = Value(paymentDate),
       paymentMode = Value(paymentMode);
  static Insertable<SalaryRecord> custom({
    Expression<String>? id,
    Expression<String>? staffId,
    Expression<int>? amountPaidPaise,
    Expression<String>? month,
    Expression<DateTime>? paymentDate,
    Expression<String>? paymentMode,
    Expression<String>? notes,
    Expression<int>? advanceAdjustedPaise,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (staffId != null) 'staff_id': staffId,
      if (amountPaidPaise != null) 'amount_paid_paise': amountPaidPaise,
      if (month != null) 'month': month,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (notes != null) 'notes': notes,
      if (advanceAdjustedPaise != null)
        'advance_adjusted_paise': advanceAdjustedPaise,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalaryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? staffId,
    Value<int>? amountPaidPaise,
    Value<String>? month,
    Value<DateTime>? paymentDate,
    Value<String>? paymentMode,
    Value<String?>? notes,
    Value<int>? advanceAdjustedPaise,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SalaryRecordsCompanion(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      amountPaidPaise: amountPaidPaise ?? this.amountPaidPaise,
      month: month ?? this.month,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      advanceAdjustedPaise: advanceAdjustedPaise ?? this.advanceAdjustedPaise,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (amountPaidPaise.present) {
      map['amount_paid_paise'] = Variable<int>(amountPaidPaise.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (advanceAdjustedPaise.present) {
      map['advance_adjusted_paise'] = Variable<int>(advanceAdjustedPaise.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalaryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('staffId: $staffId, ')
          ..write('amountPaidPaise: $amountPaidPaise, ')
          ..write('month: $month, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('notes: $notes, ')
          ..write('advanceAdjustedPaise: $advanceAdjustedPaise, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvanceRecordsTable extends AdvanceRecords
    with TableInfo<$AdvanceRecordsTable, AdvanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personTypeMeta = const VerificationMeta(
    'personType',
  );
  @override
  late final GeneratedColumn<String> personType = GeneratedColumn<String>(
    'person_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveredAmountPaiseMeta =
      const VerificationMeta('recoveredAmountPaise');
  @override
  late final GeneratedColumn<int> recoveredAmountPaise = GeneratedColumn<int>(
    'recovered_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _linkedStaffIdMeta = const VerificationMeta(
    'linkedStaffId',
  );
  @override
  late final GeneratedColumn<String> linkedStaffId = GeneratedColumn<String>(
    'linked_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES staff (id)',
    ),
  );
  static const VerificationMeta _linkedSalaryRecordIdMeta =
      const VerificationMeta('linkedSalaryRecordId');
  @override
  late final GeneratedColumn<String> linkedSalaryRecordId =
      GeneratedColumn<String>(
        'linked_salary_record_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personName,
    personType,
    amountPaise,
    date,
    reason,
    recoveredAmountPaise,
    status,
    linkedStaffId,
    linkedSalaryRecordId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('person_type')) {
      context.handle(
        _personTypeMeta,
        personType.isAcceptableOrUnknown(data['person_type']!, _personTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_personTypeMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('recovered_amount_paise')) {
      context.handle(
        _recoveredAmountPaiseMeta,
        recoveredAmountPaise.isAcceptableOrUnknown(
          data['recovered_amount_paise']!,
          _recoveredAmountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('linked_staff_id')) {
      context.handle(
        _linkedStaffIdMeta,
        linkedStaffId.isAcceptableOrUnknown(
          data['linked_staff_id']!,
          _linkedStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_salary_record_id')) {
      context.handle(
        _linkedSalaryRecordIdMeta,
        linkedSalaryRecordId.isAcceptableOrUnknown(
          data['linked_salary_record_id']!,
          _linkedSalaryRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdvanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      )!,
      personType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_type'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      recoveredAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recovered_amount_paise'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      linkedStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_staff_id'],
      ),
      linkedSalaryRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_salary_record_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AdvanceRecordsTable createAlias(String alias) {
    return $AdvanceRecordsTable(attachedDatabase, alias);
  }
}

class AdvanceRecord extends DataClass implements Insertable<AdvanceRecord> {
  final String id;
  final String personName;
  final String personType;
  final int amountPaise;
  final DateTime date;
  final String? reason;
  final int recoveredAmountPaise;
  final String status;
  final String? linkedStaffId;
  final String? linkedSalaryRecordId;
  final DateTime createdAt;
  const AdvanceRecord({
    required this.id,
    required this.personName,
    required this.personType,
    required this.amountPaise,
    required this.date,
    this.reason,
    required this.recoveredAmountPaise,
    required this.status,
    this.linkedStaffId,
    this.linkedSalaryRecordId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_name'] = Variable<String>(personName);
    map['person_type'] = Variable<String>(personType);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['recovered_amount_paise'] = Variable<int>(recoveredAmountPaise);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || linkedStaffId != null) {
      map['linked_staff_id'] = Variable<String>(linkedStaffId);
    }
    if (!nullToAbsent || linkedSalaryRecordId != null) {
      map['linked_salary_record_id'] = Variable<String>(linkedSalaryRecordId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AdvanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AdvanceRecordsCompanion(
      id: Value(id),
      personName: Value(personName),
      personType: Value(personType),
      amountPaise: Value(amountPaise),
      date: Value(date),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      recoveredAmountPaise: Value(recoveredAmountPaise),
      status: Value(status),
      linkedStaffId: linkedStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedStaffId),
      linkedSalaryRecordId: linkedSalaryRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedSalaryRecordId),
      createdAt: Value(createdAt),
    );
  }

  factory AdvanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvanceRecord(
      id: serializer.fromJson<String>(json['id']),
      personName: serializer.fromJson<String>(json['personName']),
      personType: serializer.fromJson<String>(json['personType']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      date: serializer.fromJson<DateTime>(json['date']),
      reason: serializer.fromJson<String?>(json['reason']),
      recoveredAmountPaise: serializer.fromJson<int>(
        json['recoveredAmountPaise'],
      ),
      status: serializer.fromJson<String>(json['status']),
      linkedStaffId: serializer.fromJson<String?>(json['linkedStaffId']),
      linkedSalaryRecordId: serializer.fromJson<String?>(
        json['linkedSalaryRecordId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personName': serializer.toJson<String>(personName),
      'personType': serializer.toJson<String>(personType),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'date': serializer.toJson<DateTime>(date),
      'reason': serializer.toJson<String?>(reason),
      'recoveredAmountPaise': serializer.toJson<int>(recoveredAmountPaise),
      'status': serializer.toJson<String>(status),
      'linkedStaffId': serializer.toJson<String?>(linkedStaffId),
      'linkedSalaryRecordId': serializer.toJson<String?>(linkedSalaryRecordId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AdvanceRecord copyWith({
    String? id,
    String? personName,
    String? personType,
    int? amountPaise,
    DateTime? date,
    Value<String?> reason = const Value.absent(),
    int? recoveredAmountPaise,
    String? status,
    Value<String?> linkedStaffId = const Value.absent(),
    Value<String?> linkedSalaryRecordId = const Value.absent(),
    DateTime? createdAt,
  }) => AdvanceRecord(
    id: id ?? this.id,
    personName: personName ?? this.personName,
    personType: personType ?? this.personType,
    amountPaise: amountPaise ?? this.amountPaise,
    date: date ?? this.date,
    reason: reason.present ? reason.value : this.reason,
    recoveredAmountPaise: recoveredAmountPaise ?? this.recoveredAmountPaise,
    status: status ?? this.status,
    linkedStaffId: linkedStaffId.present
        ? linkedStaffId.value
        : this.linkedStaffId,
    linkedSalaryRecordId: linkedSalaryRecordId.present
        ? linkedSalaryRecordId.value
        : this.linkedSalaryRecordId,
    createdAt: createdAt ?? this.createdAt,
  );
  AdvanceRecord copyWithCompanion(AdvanceRecordsCompanion data) {
    return AdvanceRecord(
      id: data.id.present ? data.id.value : this.id,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      personType: data.personType.present
          ? data.personType.value
          : this.personType,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      date: data.date.present ? data.date.value : this.date,
      reason: data.reason.present ? data.reason.value : this.reason,
      recoveredAmountPaise: data.recoveredAmountPaise.present
          ? data.recoveredAmountPaise.value
          : this.recoveredAmountPaise,
      status: data.status.present ? data.status.value : this.status,
      linkedStaffId: data.linkedStaffId.present
          ? data.linkedStaffId.value
          : this.linkedStaffId,
      linkedSalaryRecordId: data.linkedSalaryRecordId.present
          ? data.linkedSalaryRecordId.value
          : this.linkedSalaryRecordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvanceRecord(')
          ..write('id: $id, ')
          ..write('personName: $personName, ')
          ..write('personType: $personType, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('date: $date, ')
          ..write('reason: $reason, ')
          ..write('recoveredAmountPaise: $recoveredAmountPaise, ')
          ..write('status: $status, ')
          ..write('linkedStaffId: $linkedStaffId, ')
          ..write('linkedSalaryRecordId: $linkedSalaryRecordId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personName,
    personType,
    amountPaise,
    date,
    reason,
    recoveredAmountPaise,
    status,
    linkedStaffId,
    linkedSalaryRecordId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvanceRecord &&
          other.id == this.id &&
          other.personName == this.personName &&
          other.personType == this.personType &&
          other.amountPaise == this.amountPaise &&
          other.date == this.date &&
          other.reason == this.reason &&
          other.recoveredAmountPaise == this.recoveredAmountPaise &&
          other.status == this.status &&
          other.linkedStaffId == this.linkedStaffId &&
          other.linkedSalaryRecordId == this.linkedSalaryRecordId &&
          other.createdAt == this.createdAt);
}

class AdvanceRecordsCompanion extends UpdateCompanion<AdvanceRecord> {
  final Value<String> id;
  final Value<String> personName;
  final Value<String> personType;
  final Value<int> amountPaise;
  final Value<DateTime> date;
  final Value<String?> reason;
  final Value<int> recoveredAmountPaise;
  final Value<String> status;
  final Value<String?> linkedStaffId;
  final Value<String?> linkedSalaryRecordId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AdvanceRecordsCompanion({
    this.id = const Value.absent(),
    this.personName = const Value.absent(),
    this.personType = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.date = const Value.absent(),
    this.reason = const Value.absent(),
    this.recoveredAmountPaise = const Value.absent(),
    this.status = const Value.absent(),
    this.linkedStaffId = const Value.absent(),
    this.linkedSalaryRecordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvanceRecordsCompanion.insert({
    required String id,
    required String personName,
    required String personType,
    required int amountPaise,
    required DateTime date,
    this.reason = const Value.absent(),
    this.recoveredAmountPaise = const Value.absent(),
    this.status = const Value.absent(),
    this.linkedStaffId = const Value.absent(),
    this.linkedSalaryRecordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personName = Value(personName),
       personType = Value(personType),
       amountPaise = Value(amountPaise),
       date = Value(date);
  static Insertable<AdvanceRecord> custom({
    Expression<String>? id,
    Expression<String>? personName,
    Expression<String>? personType,
    Expression<int>? amountPaise,
    Expression<DateTime>? date,
    Expression<String>? reason,
    Expression<int>? recoveredAmountPaise,
    Expression<String>? status,
    Expression<String>? linkedStaffId,
    Expression<String>? linkedSalaryRecordId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personName != null) 'person_name': personName,
      if (personType != null) 'person_type': personType,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (date != null) 'date': date,
      if (reason != null) 'reason': reason,
      if (recoveredAmountPaise != null)
        'recovered_amount_paise': recoveredAmountPaise,
      if (status != null) 'status': status,
      if (linkedStaffId != null) 'linked_staff_id': linkedStaffId,
      if (linkedSalaryRecordId != null)
        'linked_salary_record_id': linkedSalaryRecordId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvanceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? personName,
    Value<String>? personType,
    Value<int>? amountPaise,
    Value<DateTime>? date,
    Value<String?>? reason,
    Value<int>? recoveredAmountPaise,
    Value<String>? status,
    Value<String?>? linkedStaffId,
    Value<String?>? linkedSalaryRecordId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AdvanceRecordsCompanion(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      personType: personType ?? this.personType,
      amountPaise: amountPaise ?? this.amountPaise,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      recoveredAmountPaise: recoveredAmountPaise ?? this.recoveredAmountPaise,
      status: status ?? this.status,
      linkedStaffId: linkedStaffId ?? this.linkedStaffId,
      linkedSalaryRecordId: linkedSalaryRecordId ?? this.linkedSalaryRecordId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (personType.present) {
      map['person_type'] = Variable<String>(personType.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (recoveredAmountPaise.present) {
      map['recovered_amount_paise'] = Variable<int>(recoveredAmountPaise.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (linkedStaffId.present) {
      map['linked_staff_id'] = Variable<String>(linkedStaffId.value);
    }
    if (linkedSalaryRecordId.present) {
      map['linked_salary_record_id'] = Variable<String>(
        linkedSalaryRecordId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('personName: $personName, ')
          ..write('personType: $personType, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('date: $date, ')
          ..write('reason: $reason, ')
          ..write('recoveredAmountPaise: $recoveredAmountPaise, ')
          ..write('status: $status, ')
          ..write('linkedStaffId: $linkedStaffId, ')
          ..write('linkedSalaryRecordId: $linkedSalaryRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScreenshotImportsTable extends ScreenshotImports
    with TableInfo<$ScreenshotImportsTable, ScreenshotImport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScreenshotImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedAmountPaiseMeta =
      const VerificationMeta('extractedAmountPaise');
  @override
  late final GeneratedColumn<int> extractedAmountPaise = GeneratedColumn<int>(
    'extracted_amount_paise',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedDateMeta = const VerificationMeta(
    'extractedDate',
  );
  @override
  late final GeneratedColumn<DateTime> extractedDate =
      GeneratedColumn<DateTime>(
        'extracted_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _extractedTypeMeta = const VerificationMeta(
    'extractedType',
  );
  @override
  late final GeneratedColumn<String> extractedType = GeneratedColumn<String>(
    'extracted_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceScoreMeta = const VerificationMeta(
    'confidenceScore',
  );
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
    'confidence_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _createdTransactionIdMeta =
      const VerificationMeta('createdTransactionId');
  @override
  late final GeneratedColumn<String> createdTransactionId =
      GeneratedColumn<String>(
        'created_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imagePath,
    extractedText,
    extractedAmountPaise,
    extractedDate,
    extractedType,
    confidenceScore,
    status,
    createdTransactionId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'screenshot_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScreenshotImport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
    }
    if (data.containsKey('extracted_amount_paise')) {
      context.handle(
        _extractedAmountPaiseMeta,
        extractedAmountPaise.isAcceptableOrUnknown(
          data['extracted_amount_paise']!,
          _extractedAmountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('extracted_date')) {
      context.handle(
        _extractedDateMeta,
        extractedDate.isAcceptableOrUnknown(
          data['extracted_date']!,
          _extractedDateMeta,
        ),
      );
    }
    if (data.containsKey('extracted_type')) {
      context.handle(
        _extractedTypeMeta,
        extractedType.isAcceptableOrUnknown(
          data['extracted_type']!,
          _extractedTypeMeta,
        ),
      );
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
        _confidenceScoreMeta,
        confidenceScore.isAcceptableOrUnknown(
          data['confidence_score']!,
          _confidenceScoreMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_transaction_id')) {
      context.handle(
        _createdTransactionIdMeta,
        createdTransactionId.isAcceptableOrUnknown(
          data['created_transaction_id']!,
          _createdTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScreenshotImport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScreenshotImport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      ),
      extractedAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extracted_amount_paise'],
      ),
      extractedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}extracted_date'],
      ),
      extractedType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_type'],
      ),
      confidenceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence_score'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_transaction_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ScreenshotImportsTable createAlias(String alias) {
    return $ScreenshotImportsTable(attachedDatabase, alias);
  }
}

class ScreenshotImport extends DataClass
    implements Insertable<ScreenshotImport> {
  final String id;
  final String imagePath;
  final String? extractedText;
  final int? extractedAmountPaise;
  final DateTime? extractedDate;
  final String? extractedType;
  final double confidenceScore;
  final String status;
  final String? createdTransactionId;
  final DateTime createdAt;
  const ScreenshotImport({
    required this.id,
    required this.imagePath,
    this.extractedText,
    this.extractedAmountPaise,
    this.extractedDate,
    this.extractedType,
    required this.confidenceScore,
    required this.status,
    this.createdTransactionId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    if (!nullToAbsent || extractedAmountPaise != null) {
      map['extracted_amount_paise'] = Variable<int>(extractedAmountPaise);
    }
    if (!nullToAbsent || extractedDate != null) {
      map['extracted_date'] = Variable<DateTime>(extractedDate);
    }
    if (!nullToAbsent || extractedType != null) {
      map['extracted_type'] = Variable<String>(extractedType);
    }
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdTransactionId != null) {
      map['created_transaction_id'] = Variable<String>(createdTransactionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ScreenshotImportsCompanion toCompanion(bool nullToAbsent) {
    return ScreenshotImportsCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      extractedAmountPaise: extractedAmountPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedAmountPaise),
      extractedDate: extractedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedDate),
      extractedType: extractedType == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedType),
      confidenceScore: Value(confidenceScore),
      status: Value(status),
      createdTransactionId: createdTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdTransactionId),
      createdAt: Value(createdAt),
    );
  }

  factory ScreenshotImport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScreenshotImport(
      id: serializer.fromJson<String>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      extractedAmountPaise: serializer.fromJson<int?>(
        json['extractedAmountPaise'],
      ),
      extractedDate: serializer.fromJson<DateTime?>(json['extractedDate']),
      extractedType: serializer.fromJson<String?>(json['extractedType']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      status: serializer.fromJson<String>(json['status']),
      createdTransactionId: serializer.fromJson<String?>(
        json['createdTransactionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'extractedText': serializer.toJson<String?>(extractedText),
      'extractedAmountPaise': serializer.toJson<int?>(extractedAmountPaise),
      'extractedDate': serializer.toJson<DateTime?>(extractedDate),
      'extractedType': serializer.toJson<String?>(extractedType),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'status': serializer.toJson<String>(status),
      'createdTransactionId': serializer.toJson<String?>(createdTransactionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ScreenshotImport copyWith({
    String? id,
    String? imagePath,
    Value<String?> extractedText = const Value.absent(),
    Value<int?> extractedAmountPaise = const Value.absent(),
    Value<DateTime?> extractedDate = const Value.absent(),
    Value<String?> extractedType = const Value.absent(),
    double? confidenceScore,
    String? status,
    Value<String?> createdTransactionId = const Value.absent(),
    DateTime? createdAt,
  }) => ScreenshotImport(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    extractedAmountPaise: extractedAmountPaise.present
        ? extractedAmountPaise.value
        : this.extractedAmountPaise,
    extractedDate: extractedDate.present
        ? extractedDate.value
        : this.extractedDate,
    extractedType: extractedType.present
        ? extractedType.value
        : this.extractedType,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    status: status ?? this.status,
    createdTransactionId: createdTransactionId.present
        ? createdTransactionId.value
        : this.createdTransactionId,
    createdAt: createdAt ?? this.createdAt,
  );
  ScreenshotImport copyWithCompanion(ScreenshotImportsCompanion data) {
    return ScreenshotImport(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      extractedAmountPaise: data.extractedAmountPaise.present
          ? data.extractedAmountPaise.value
          : this.extractedAmountPaise,
      extractedDate: data.extractedDate.present
          ? data.extractedDate.value
          : this.extractedDate,
      extractedType: data.extractedType.present
          ? data.extractedType.value
          : this.extractedType,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      status: data.status.present ? data.status.value : this.status,
      createdTransactionId: data.createdTransactionId.present
          ? data.createdTransactionId.value
          : this.createdTransactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScreenshotImport(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('extractedText: $extractedText, ')
          ..write('extractedAmountPaise: $extractedAmountPaise, ')
          ..write('extractedDate: $extractedDate, ')
          ..write('extractedType: $extractedType, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('status: $status, ')
          ..write('createdTransactionId: $createdTransactionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imagePath,
    extractedText,
    extractedAmountPaise,
    extractedDate,
    extractedType,
    confidenceScore,
    status,
    createdTransactionId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScreenshotImport &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.extractedText == this.extractedText &&
          other.extractedAmountPaise == this.extractedAmountPaise &&
          other.extractedDate == this.extractedDate &&
          other.extractedType == this.extractedType &&
          other.confidenceScore == this.confidenceScore &&
          other.status == this.status &&
          other.createdTransactionId == this.createdTransactionId &&
          other.createdAt == this.createdAt);
}

class ScreenshotImportsCompanion extends UpdateCompanion<ScreenshotImport> {
  final Value<String> id;
  final Value<String> imagePath;
  final Value<String?> extractedText;
  final Value<int?> extractedAmountPaise;
  final Value<DateTime?> extractedDate;
  final Value<String?> extractedType;
  final Value<double> confidenceScore;
  final Value<String> status;
  final Value<String?> createdTransactionId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ScreenshotImportsCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.extractedAmountPaise = const Value.absent(),
    this.extractedDate = const Value.absent(),
    this.extractedType = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.status = const Value.absent(),
    this.createdTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScreenshotImportsCompanion.insert({
    required String id,
    required String imagePath,
    this.extractedText = const Value.absent(),
    this.extractedAmountPaise = const Value.absent(),
    this.extractedDate = const Value.absent(),
    this.extractedType = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.status = const Value.absent(),
    this.createdTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       imagePath = Value(imagePath);
  static Insertable<ScreenshotImport> custom({
    Expression<String>? id,
    Expression<String>? imagePath,
    Expression<String>? extractedText,
    Expression<int>? extractedAmountPaise,
    Expression<DateTime>? extractedDate,
    Expression<String>? extractedType,
    Expression<double>? confidenceScore,
    Expression<String>? status,
    Expression<String>? createdTransactionId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (extractedText != null) 'extracted_text': extractedText,
      if (extractedAmountPaise != null)
        'extracted_amount_paise': extractedAmountPaise,
      if (extractedDate != null) 'extracted_date': extractedDate,
      if (extractedType != null) 'extracted_type': extractedType,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (status != null) 'status': status,
      if (createdTransactionId != null)
        'created_transaction_id': createdTransactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScreenshotImportsCompanion copyWith({
    Value<String>? id,
    Value<String>? imagePath,
    Value<String?>? extractedText,
    Value<int?>? extractedAmountPaise,
    Value<DateTime?>? extractedDate,
    Value<String?>? extractedType,
    Value<double>? confidenceScore,
    Value<String>? status,
    Value<String?>? createdTransactionId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ScreenshotImportsCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      extractedAmountPaise: extractedAmountPaise ?? this.extractedAmountPaise,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedType: extractedType ?? this.extractedType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      createdTransactionId: createdTransactionId ?? this.createdTransactionId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (extractedAmountPaise.present) {
      map['extracted_amount_paise'] = Variable<int>(extractedAmountPaise.value);
    }
    if (extractedDate.present) {
      map['extracted_date'] = Variable<DateTime>(extractedDate.value);
    }
    if (extractedType.present) {
      map['extracted_type'] = Variable<String>(extractedType.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdTransactionId.present) {
      map['created_transaction_id'] = Variable<String>(
        createdTransactionId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScreenshotImportsCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('extractedText: $extractedText, ')
          ..write('extractedAmountPaise: $extractedAmountPaise, ')
          ..write('extractedDate: $extractedDate, ')
          ..write('extractedType: $extractedType, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('status: $status, ')
          ..write('createdTransactionId: $createdTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    icon,
    isDefault,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String kind;
  final String? icon;
  final bool isDefault;
  final int sortOrder;
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.icon,
    required this.isDefault,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      icon: serializer.fromJson<String?>(json['icon']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'icon': serializer.toJson<String?>(icon),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? kind,
    Value<String?> icon = const Value.absent(),
    bool? isDefault,
    int? sortOrder,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    icon: icon.present ? icon.value : this.icon,
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, icon, isDefault, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.icon == this.icon &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String?> icon;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    this.icon = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? icon,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (icon != null) 'icon': icon,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String?>? icon,
    Value<bool>? isDefault,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $StaffTable staff = $StaffTable(this);
  late final $SalaryRecordsTable salaryRecords = $SalaryRecordsTable(this);
  late final $AdvanceRecordsTable advanceRecords = $AdvanceRecordsTable(this);
  late final $ScreenshotImportsTable screenshotImports =
      $ScreenshotImportsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    staff,
    salaryRecords,
    advanceRecords,
    screenshotImports,
    categories,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String type,
      required String category,
      Value<String?> subcategory,
      required int amountPaise,
      required DateTime occurredAt,
      required String paymentMode,
      Value<String?> partyName,
      Value<String?> notes,
      Value<String> source,
      Value<String?> tag,
      Value<String?> attachmentPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> category,
      Value<String?> subcategory,
      Value<int> amountPaise,
      Value<DateTime> occurredAt,
      Value<String> paymentMode,
      Value<String?> partyName,
      Value<String?> notes,
      Value<String> source,
      Value<String?> tag,
      Value<String?> attachmentPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> subcategory = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                category: category,
                subcategory: subcategory,
                amountPaise: amountPaise,
                occurredAt: occurredAt,
                paymentMode: paymentMode,
                partyName: partyName,
                notes: notes,
                source: source,
                tag: tag,
                attachmentPath: attachmentPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String category,
                Value<String?> subcategory = const Value.absent(),
                required int amountPaise,
                required DateTime occurredAt,
                required String paymentMode,
                Value<String?> partyName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                category: category,
                subcategory: subcategory,
                amountPaise: amountPaise,
                occurredAt: occurredAt,
                paymentMode: paymentMode,
                partyName: partyName,
                notes: notes,
                source: source,
                tag: tag,
                attachmentPath: attachmentPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$StaffTableCreateCompanionBuilder =
    StaffCompanion Function({
      required String id,
      required String name,
      Value<String?> role,
      Value<int> monthlySalaryPaise,
      Value<DateTime?> joinedDate,
      Value<bool> activeStatus,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$StaffTableUpdateCompanionBuilder =
    StaffCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> role,
      Value<int> monthlySalaryPaise,
      Value<DateTime?> joinedDate,
      Value<bool> activeStatus,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$StaffTableReferences
    extends BaseReferences<_$AppDatabase, $StaffTable, StaffData> {
  $$StaffTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SalaryRecordsTable, List<SalaryRecord>>
  _salaryRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.salaryRecords,
    aliasName: 'staff__id__salary_records__staff_id',
  );

  $$SalaryRecordsTableProcessedTableManager get salaryRecordsRefs {
    final manager = $$SalaryRecordsTableTableManager(
      $_db,
      $_db.salaryRecords,
    ).filter((f) => f.staffId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_salaryRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AdvanceRecordsTable, List<AdvanceRecord>>
  _advanceRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.advanceRecords,
    aliasName: 'staff__id__advance_records__linked_staff_id',
  );

  $$AdvanceRecordsTableProcessedTableManager get advanceRecordsRefs {
    final manager = $$AdvanceRecordsTableTableManager(
      $_db,
      $_db.advanceRecords,
    ).filter((f) => f.linkedStaffId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_advanceRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StaffTableFilterComposer extends Composer<_$AppDatabase, $StaffTable> {
  $$StaffTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlySalaryPaise => $composableBuilder(
    column: $table.monthlySalaryPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedDate => $composableBuilder(
    column: $table.joinedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activeStatus => $composableBuilder(
    column: $table.activeStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> salaryRecordsRefs(
    Expression<bool> Function($$SalaryRecordsTableFilterComposer f) f,
  ) {
    final $$SalaryRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salaryRecords,
      getReferencedColumn: (t) => t.staffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalaryRecordsTableFilterComposer(
            $db: $db,
            $table: $db.salaryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> advanceRecordsRefs(
    Expression<bool> Function($$AdvanceRecordsTableFilterComposer f) f,
  ) {
    final $$AdvanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.advanceRecords,
      getReferencedColumn: (t) => t.linkedStaffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdvanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.advanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StaffTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffTable> {
  $$StaffTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlySalaryPaise => $composableBuilder(
    column: $table.monthlySalaryPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedDate => $composableBuilder(
    column: $table.joinedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activeStatus => $composableBuilder(
    column: $table.activeStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffTable> {
  $$StaffTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get monthlySalaryPaise => $composableBuilder(
    column: $table.monthlySalaryPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get joinedDate => $composableBuilder(
    column: $table.joinedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activeStatus => $composableBuilder(
    column: $table.activeStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> salaryRecordsRefs<T extends Object>(
    Expression<T> Function($$SalaryRecordsTableAnnotationComposer a) f,
  ) {
    final $$SalaryRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salaryRecords,
      getReferencedColumn: (t) => t.staffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalaryRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.salaryRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> advanceRecordsRefs<T extends Object>(
    Expression<T> Function($$AdvanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$AdvanceRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.advanceRecords,
      getReferencedColumn: (t) => t.linkedStaffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdvanceRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.advanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StaffTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffTable,
          StaffData,
          $$StaffTableFilterComposer,
          $$StaffTableOrderingComposer,
          $$StaffTableAnnotationComposer,
          $$StaffTableCreateCompanionBuilder,
          $$StaffTableUpdateCompanionBuilder,
          (StaffData, $$StaffTableReferences),
          StaffData,
          PrefetchHooks Function({
            bool salaryRecordsRefs,
            bool advanceRecordsRefs,
          })
        > {
  $$StaffTableTableManager(_$AppDatabase db, $StaffTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StaffTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StaffTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<int> monthlySalaryPaise = const Value.absent(),
                Value<DateTime?> joinedDate = const Value.absent(),
                Value<bool> activeStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffCompanion(
                id: id,
                name: name,
                role: role,
                monthlySalaryPaise: monthlySalaryPaise,
                joinedDate: joinedDate,
                activeStatus: activeStatus,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> role = const Value.absent(),
                Value<int> monthlySalaryPaise = const Value.absent(),
                Value<DateTime?> joinedDate = const Value.absent(),
                Value<bool> activeStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffCompanion.insert(
                id: id,
                name: name,
                role: role,
                monthlySalaryPaise: monthlySalaryPaise,
                joinedDate: joinedDate,
                activeStatus: activeStatus,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StaffTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({salaryRecordsRefs = false, advanceRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (salaryRecordsRefs) db.salaryRecords,
                    if (advanceRecordsRefs) db.advanceRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (salaryRecordsRefs)
                        await $_getPrefetchedData<
                          StaffData,
                          $StaffTable,
                          SalaryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$StaffTableReferences
                              ._salaryRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StaffTableReferences(
                                db,
                                table,
                                p0,
                              ).salaryRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.staffId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (advanceRecordsRefs)
                        await $_getPrefetchedData<
                          StaffData,
                          $StaffTable,
                          AdvanceRecord
                        >(
                          currentTable: table,
                          referencedTable: $$StaffTableReferences
                              ._advanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StaffTableReferences(
                                db,
                                table,
                                p0,
                              ).advanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.linkedStaffId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StaffTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffTable,
      StaffData,
      $$StaffTableFilterComposer,
      $$StaffTableOrderingComposer,
      $$StaffTableAnnotationComposer,
      $$StaffTableCreateCompanionBuilder,
      $$StaffTableUpdateCompanionBuilder,
      (StaffData, $$StaffTableReferences),
      StaffData,
      PrefetchHooks Function({bool salaryRecordsRefs, bool advanceRecordsRefs})
    >;
typedef $$SalaryRecordsTableCreateCompanionBuilder =
    SalaryRecordsCompanion Function({
      required String id,
      required String staffId,
      required int amountPaidPaise,
      required String month,
      required DateTime paymentDate,
      required String paymentMode,
      Value<String?> notes,
      Value<int> advanceAdjustedPaise,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$SalaryRecordsTableUpdateCompanionBuilder =
    SalaryRecordsCompanion Function({
      Value<String> id,
      Value<String> staffId,
      Value<int> amountPaidPaise,
      Value<String> month,
      Value<DateTime> paymentDate,
      Value<String> paymentMode,
      Value<String?> notes,
      Value<int> advanceAdjustedPaise,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SalaryRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $SalaryRecordsTable, SalaryRecord> {
  $$SalaryRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StaffTable _staffIdTable(_$AppDatabase db) =>
      db.staff.createAlias('salary_records__staff_id__staff__id');

  $$StaffTableProcessedTableManager get staffId {
    final $_column = $_itemColumn<String>('staff_id')!;

    final manager = $$StaffTableTableManager(
      $_db,
      $_db.staff,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_staffIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SalaryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SalaryRecordsTable> {
  $$SalaryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaidPaise => $composableBuilder(
    column: $table.amountPaidPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceAdjustedPaise => $composableBuilder(
    column: $table.advanceAdjustedPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StaffTableFilterComposer get staffId {
    final $$StaffTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.staffId,
      referencedTable: $db.staff,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StaffTableFilterComposer(
            $db: $db,
            $table: $db.staff,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalaryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SalaryRecordsTable> {
  $$SalaryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaidPaise => $composableBuilder(
    column: $table.amountPaidPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceAdjustedPaise => $composableBuilder(
    column: $table.advanceAdjustedPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StaffTableOrderingComposer get staffId {
    final $$StaffTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.staffId,
      referencedTable: $db.staff,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StaffTableOrderingComposer(
            $db: $db,
            $table: $db.staff,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalaryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalaryRecordsTable> {
  $$SalaryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaidPaise => $composableBuilder(
    column: $table.amountPaidPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get advanceAdjustedPaise => $composableBuilder(
    column: $table.advanceAdjustedPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StaffTableAnnotationComposer get staffId {
    final $$StaffTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.staffId,
      referencedTable: $db.staff,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StaffTableAnnotationComposer(
            $db: $db,
            $table: $db.staff,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalaryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalaryRecordsTable,
          SalaryRecord,
          $$SalaryRecordsTableFilterComposer,
          $$SalaryRecordsTableOrderingComposer,
          $$SalaryRecordsTableAnnotationComposer,
          $$SalaryRecordsTableCreateCompanionBuilder,
          $$SalaryRecordsTableUpdateCompanionBuilder,
          (SalaryRecord, $$SalaryRecordsTableReferences),
          SalaryRecord,
          PrefetchHooks Function({bool staffId})
        > {
  $$SalaryRecordsTableTableManager(_$AppDatabase db, $SalaryRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalaryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalaryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalaryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> staffId = const Value.absent(),
                Value<int> amountPaidPaise = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<DateTime> paymentDate = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> advanceAdjustedPaise = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalaryRecordsCompanion(
                id: id,
                staffId: staffId,
                amountPaidPaise: amountPaidPaise,
                month: month,
                paymentDate: paymentDate,
                paymentMode: paymentMode,
                notes: notes,
                advanceAdjustedPaise: advanceAdjustedPaise,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String staffId,
                required int amountPaidPaise,
                required String month,
                required DateTime paymentDate,
                required String paymentMode,
                Value<String?> notes = const Value.absent(),
                Value<int> advanceAdjustedPaise = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalaryRecordsCompanion.insert(
                id: id,
                staffId: staffId,
                amountPaidPaise: amountPaidPaise,
                month: month,
                paymentDate: paymentDate,
                paymentMode: paymentMode,
                notes: notes,
                advanceAdjustedPaise: advanceAdjustedPaise,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SalaryRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({staffId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (staffId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.staffId,
                                referencedTable: $$SalaryRecordsTableReferences
                                    ._staffIdTable(db),
                                referencedColumn: $$SalaryRecordsTableReferences
                                    ._staffIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SalaryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalaryRecordsTable,
      SalaryRecord,
      $$SalaryRecordsTableFilterComposer,
      $$SalaryRecordsTableOrderingComposer,
      $$SalaryRecordsTableAnnotationComposer,
      $$SalaryRecordsTableCreateCompanionBuilder,
      $$SalaryRecordsTableUpdateCompanionBuilder,
      (SalaryRecord, $$SalaryRecordsTableReferences),
      SalaryRecord,
      PrefetchHooks Function({bool staffId})
    >;
typedef $$AdvanceRecordsTableCreateCompanionBuilder =
    AdvanceRecordsCompanion Function({
      required String id,
      required String personName,
      required String personType,
      required int amountPaise,
      required DateTime date,
      Value<String?> reason,
      Value<int> recoveredAmountPaise,
      Value<String> status,
      Value<String?> linkedStaffId,
      Value<String?> linkedSalaryRecordId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AdvanceRecordsTableUpdateCompanionBuilder =
    AdvanceRecordsCompanion Function({
      Value<String> id,
      Value<String> personName,
      Value<String> personType,
      Value<int> amountPaise,
      Value<DateTime> date,
      Value<String?> reason,
      Value<int> recoveredAmountPaise,
      Value<String> status,
      Value<String?> linkedStaffId,
      Value<String?> linkedSalaryRecordId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AdvanceRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $AdvanceRecordsTable, AdvanceRecord> {
  $$AdvanceRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StaffTable _linkedStaffIdTable(_$AppDatabase db) =>
      db.staff.createAlias('advance_records__linked_staff_id__staff__id');

  $$StaffTableProcessedTableManager? get linkedStaffId {
    final $_column = $_itemColumn<String>('linked_staff_id');
    if ($_column == null) return null;
    final manager = $$StaffTableTableManager(
      $_db,
      $_db.staff,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedStaffIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AdvanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AdvanceRecordsTable> {
  $$AdvanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personType => $composableBuilder(
    column: $table.personType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recoveredAmountPaise => $composableBuilder(
    column: $table.recoveredAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedSalaryRecordId => $composableBuilder(
    column: $table.linkedSalaryRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StaffTableFilterComposer get linkedStaffId {
    final $$StaffTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedStaffId,
      referencedTable: $db.staff,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StaffTableFilterComposer(
            $db: $db,
            $table: $db.staff,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdvanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdvanceRecordsTable> {
  $$AdvanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personType => $composableBuilder(
    column: $table.personType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recoveredAmountPaise => $composableBuilder(
    column: $table.recoveredAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedSalaryRecordId => $composableBuilder(
    column: $table.linkedSalaryRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StaffTableOrderingComposer get linkedStaffId {
    final $$StaffTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedStaffId,
      referencedTable: $db.staff,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StaffTableOrderingComposer(
            $db: $db,
            $table: $db.staff,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdvanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdvanceRecordsTable> {
  $$AdvanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personType => $composableBuilder(
    column: $table.personType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get recoveredAmountPaise => $composableBuilder(
    column: $table.recoveredAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get linkedSalaryRecordId => $composableBuilder(
    column: $table.linkedSalaryRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StaffTableAnnotationComposer get linkedStaffId {
    final $$StaffTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedStaffId,
      referencedTable: $db.staff,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StaffTableAnnotationComposer(
            $db: $db,
            $table: $db.staff,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdvanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdvanceRecordsTable,
          AdvanceRecord,
          $$AdvanceRecordsTableFilterComposer,
          $$AdvanceRecordsTableOrderingComposer,
          $$AdvanceRecordsTableAnnotationComposer,
          $$AdvanceRecordsTableCreateCompanionBuilder,
          $$AdvanceRecordsTableUpdateCompanionBuilder,
          (AdvanceRecord, $$AdvanceRecordsTableReferences),
          AdvanceRecord,
          PrefetchHooks Function({bool linkedStaffId})
        > {
  $$AdvanceRecordsTableTableManager(
    _$AppDatabase db,
    $AdvanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdvanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdvanceRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personName = const Value.absent(),
                Value<String> personType = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> recoveredAmountPaise = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> linkedStaffId = const Value.absent(),
                Value<String?> linkedSalaryRecordId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvanceRecordsCompanion(
                id: id,
                personName: personName,
                personType: personType,
                amountPaise: amountPaise,
                date: date,
                reason: reason,
                recoveredAmountPaise: recoveredAmountPaise,
                status: status,
                linkedStaffId: linkedStaffId,
                linkedSalaryRecordId: linkedSalaryRecordId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personName,
                required String personType,
                required int amountPaise,
                required DateTime date,
                Value<String?> reason = const Value.absent(),
                Value<int> recoveredAmountPaise = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> linkedStaffId = const Value.absent(),
                Value<String?> linkedSalaryRecordId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvanceRecordsCompanion.insert(
                id: id,
                personName: personName,
                personType: personType,
                amountPaise: amountPaise,
                date: date,
                reason: reason,
                recoveredAmountPaise: recoveredAmountPaise,
                status: status,
                linkedStaffId: linkedStaffId,
                linkedSalaryRecordId: linkedSalaryRecordId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AdvanceRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({linkedStaffId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (linkedStaffId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.linkedStaffId,
                                referencedTable: $$AdvanceRecordsTableReferences
                                    ._linkedStaffIdTable(db),
                                referencedColumn:
                                    $$AdvanceRecordsTableReferences
                                        ._linkedStaffIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AdvanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdvanceRecordsTable,
      AdvanceRecord,
      $$AdvanceRecordsTableFilterComposer,
      $$AdvanceRecordsTableOrderingComposer,
      $$AdvanceRecordsTableAnnotationComposer,
      $$AdvanceRecordsTableCreateCompanionBuilder,
      $$AdvanceRecordsTableUpdateCompanionBuilder,
      (AdvanceRecord, $$AdvanceRecordsTableReferences),
      AdvanceRecord,
      PrefetchHooks Function({bool linkedStaffId})
    >;
typedef $$ScreenshotImportsTableCreateCompanionBuilder =
    ScreenshotImportsCompanion Function({
      required String id,
      required String imagePath,
      Value<String?> extractedText,
      Value<int?> extractedAmountPaise,
      Value<DateTime?> extractedDate,
      Value<String?> extractedType,
      Value<double> confidenceScore,
      Value<String> status,
      Value<String?> createdTransactionId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ScreenshotImportsTableUpdateCompanionBuilder =
    ScreenshotImportsCompanion Function({
      Value<String> id,
      Value<String> imagePath,
      Value<String?> extractedText,
      Value<int?> extractedAmountPaise,
      Value<DateTime?> extractedDate,
      Value<String?> extractedType,
      Value<double> confidenceScore,
      Value<String> status,
      Value<String?> createdTransactionId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ScreenshotImportsTableFilterComposer
    extends Composer<_$AppDatabase, $ScreenshotImportsTable> {
  $$ScreenshotImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extractedAmountPaise => $composableBuilder(
    column: $table.extractedAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get extractedDate => $composableBuilder(
    column: $table.extractedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedType => $composableBuilder(
    column: $table.extractedType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdTransactionId => $composableBuilder(
    column: $table.createdTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScreenshotImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScreenshotImportsTable> {
  $$ScreenshotImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extractedAmountPaise => $composableBuilder(
    column: $table.extractedAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get extractedDate => $composableBuilder(
    column: $table.extractedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedType => $composableBuilder(
    column: $table.extractedType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdTransactionId => $composableBuilder(
    column: $table.createdTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScreenshotImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScreenshotImportsTable> {
  $$ScreenshotImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extractedAmountPaise => $composableBuilder(
    column: $table.extractedAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get extractedDate => $composableBuilder(
    column: $table.extractedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractedType => $composableBuilder(
    column: $table.extractedType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdTransactionId => $composableBuilder(
    column: $table.createdTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ScreenshotImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScreenshotImportsTable,
          ScreenshotImport,
          $$ScreenshotImportsTableFilterComposer,
          $$ScreenshotImportsTableOrderingComposer,
          $$ScreenshotImportsTableAnnotationComposer,
          $$ScreenshotImportsTableCreateCompanionBuilder,
          $$ScreenshotImportsTableUpdateCompanionBuilder,
          (
            ScreenshotImport,
            BaseReferences<
              _$AppDatabase,
              $ScreenshotImportsTable,
              ScreenshotImport
            >,
          ),
          ScreenshotImport,
          PrefetchHooks Function()
        > {
  $$ScreenshotImportsTableTableManager(
    _$AppDatabase db,
    $ScreenshotImportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScreenshotImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScreenshotImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScreenshotImportsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<int?> extractedAmountPaise = const Value.absent(),
                Value<DateTime?> extractedDate = const Value.absent(),
                Value<String?> extractedType = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> createdTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenshotImportsCompanion(
                id: id,
                imagePath: imagePath,
                extractedText: extractedText,
                extractedAmountPaise: extractedAmountPaise,
                extractedDate: extractedDate,
                extractedType: extractedType,
                confidenceScore: confidenceScore,
                status: status,
                createdTransactionId: createdTransactionId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String imagePath,
                Value<String?> extractedText = const Value.absent(),
                Value<int?> extractedAmountPaise = const Value.absent(),
                Value<DateTime?> extractedDate = const Value.absent(),
                Value<String?> extractedType = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> createdTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenshotImportsCompanion.insert(
                id: id,
                imagePath: imagePath,
                extractedText: extractedText,
                extractedAmountPaise: extractedAmountPaise,
                extractedDate: extractedDate,
                extractedType: extractedType,
                confidenceScore: confidenceScore,
                status: status,
                createdTransactionId: createdTransactionId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScreenshotImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScreenshotImportsTable,
      ScreenshotImport,
      $$ScreenshotImportsTableFilterComposer,
      $$ScreenshotImportsTableOrderingComposer,
      $$ScreenshotImportsTableAnnotationComposer,
      $$ScreenshotImportsTableCreateCompanionBuilder,
      $$ScreenshotImportsTableUpdateCompanionBuilder,
      (
        ScreenshotImport,
        BaseReferences<
          _$AppDatabase,
          $ScreenshotImportsTable,
          ScreenshotImport
        >,
      ),
      ScreenshotImport,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      required String kind,
      Value<String?> icon,
      Value<bool> isDefault,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String?> icon,
      Value<bool> isDefault,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                kind: kind,
                icon: icon,
                isDefault: isDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                Value<String?> icon = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                icon: icon,
                isDefault: isDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$StaffTableTableManager get staff =>
      $$StaffTableTableManager(_db, _db.staff);
  $$SalaryRecordsTableTableManager get salaryRecords =>
      $$SalaryRecordsTableTableManager(_db, _db.salaryRecords);
  $$AdvanceRecordsTableTableManager get advanceRecords =>
      $$AdvanceRecordsTableTableManager(_db, _db.advanceRecords);
  $$ScreenshotImportsTableTableManager get screenshotImports =>
      $$ScreenshotImportsTableTableManager(_db, _db.screenshotImports);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
}
