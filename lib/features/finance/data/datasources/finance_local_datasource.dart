import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/budget_allocation_draft.dart';
import '../local/empty_finance_data.dart';

class FinanceLocalDatasource {
  static const _storageFileName = 'doki_do_finance.json';

  final _uuid = const Uuid();
  Map<String, dynamic>? _database;

  Future<Map<String, dynamic>?> getCurrentBudget() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final currentPeriodId = database['current_period_id'] as String?;
    if (currentPeriodId == null) return null;

    return getBudgetByPeriodId(currentPeriodId);
  }

  Future<List<Map<String, dynamic>>> getBudgetPeriods() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final database = await _readDatabase();
    return (database['periods'] as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>> getBudgetByPeriodId(String periodId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final database = await _readDatabase();
    return {'status': 'success', 'data': _findPeriod(database, periodId)};
  }

  Future<List<Map<String, dynamic>>> getTransactionTemplates() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final database = await _readDatabase();
    return (database['transaction_templates'] as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveTransactionTemplate({
    String? templateId,
    required String type,
    required String title,
    required int amount,
    String? preferredCategoryName,
    int? dayOfMonth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final database = await _readDatabase();
    final templates = (database['transaction_templates'] as List)
        .cast<Map<String, dynamic>>();
    final normalizedTitle = title.trim();
    final normalizedCategory = preferredCategoryName?.trim();
    final template = {
      'transaction_template_id': templateId ?? _uuid.v4(),
      'title': normalizedTitle,
      'amount': amount,
      'type': type,
      'preferred_category_name':
          normalizedCategory == null || normalizedCategory.isEmpty
          ? null
          : normalizedCategory,
      'day_of_month': dayOfMonth,
      'created_at': DateTime.now().toIso8601String(),
    };

    final index = templateId == null
        ? -1
        : templates.indexWhere(
            (item) => item['transaction_template_id'] == templateId,
          );
    if (index == -1) {
      templates.add(template);
    } else {
      template['created_at'] = templates[index]['created_at'];
      templates[index] = template;
    }
    _sortTransactionTemplates(templates);
    await _saveDatabase();
  }

  Future<void> deleteTransactionTemplate(String templateId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final database = await _readDatabase();
    final templates = (database['transaction_templates'] as List)
        .cast<Map<String, dynamic>>();
    templates.removeWhere(
      (item) => item['transaction_template_id'] == templateId,
    );
    await _saveDatabase();
  }

  Future<Map<String, dynamic>> addBudgetPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required int initialIncome,
    required String incomeSource,
    required List<BudgetAllocationDraft> defaultAllocations,
    required bool allocationsFollowIncome,
    String? carryOverFromPeriodId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final periods = (database['periods'] as List).cast<Map<String, dynamic>>();
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    final periodId =
        'period_${normalizedStart.year}_${normalizedStart.month.toString().padLeft(2, '0')}_${normalizedStart.day.toString().padLeft(2, '0')}_${_uuid.v4().substring(0, 8)}';
    final period = {
      'period_id': periodId,
      'start_date': normalizedStart.toIso8601String(),
      'end_date': DateTime(
        normalizedEnd.year,
        normalizedEnd.month,
        normalizedEnd.day,
        23,
        59,
        59,
      ).toIso8601String(),
      'total_income': 0,
      'total_allocatable': 0,
      'allocations_follow_income': allocationsFollowIncome,
      'categories': defaultAllocations.map((allocation) {
        final category = {
          'category_id': _uuid.v4(),
          'category_name': allocation.name,
          'base_allocated_amount': allocation.amount,
          'allocated_amount': allocation.amount,
          'remaining_amount': allocation.amount,
        };
        if (allocationsFollowIncome) {
          category['allocation_percent'] = allocation.percentage;
        }
        return category;
      }).toList(),
      'transactions': [
        if (initialIncome > 0)
          {
            'transaction_id': _uuid.v4(),
            'category_id': null,
            'title': incomeSource,
            'amount': initialIncome,
            'date': normalizedStart.toIso8601String(),
            'type': 'income',
          },
      ],
      'category_adjustments': <Map<String, dynamic>>[],
    };
    _recalculatePeriod(period);

    final carryOverPeriod = carryOverFromPeriodId == null
        ? null
        : _findPeriod(database, carryOverFromPeriodId);
    if (carryOverPeriod != null) {
      _recalculatePeriod(carryOverPeriod);
      final carryOverAmount = _asInt(carryOverPeriod['total_allocatable']);
      if (carryOverAmount > 0) {
        (carryOverPeriod['transactions'] as List).add({
          'transaction_id': _uuid.v4(),
          'category_id': null,
          'title': 'Transfer ke periode ${_periodLabel(period)}',
          'amount': carryOverAmount,
          'date': normalizedStart.toIso8601String(),
          'type': 'expense',
        });
        (period['transactions'] as List).add({
          'transaction_id': _uuid.v4(),
          'category_id': null,
          'title': 'Transfer dari periode ${_periodLabel(carryOverPeriod)}',
          'amount': carryOverAmount,
          'date': normalizedStart.toIso8601String(),
          'type': 'income',
        });
        _recalculatePeriod(carryOverPeriod);
        _recalculatePeriod(period);
      } else if (carryOverAmount < 0) {
        final deficitAmount = carryOverAmount.abs();
        (carryOverPeriod['transactions'] as List).add({
          'transaction_id': _uuid.v4(),
          'category_id': null,
          'title': 'Ditombok dari periode ${_periodLabel(period)}',
          'amount': deficitAmount,
          'date': normalizedStart.toIso8601String(),
          'type': 'income',
        });
        (period['transactions'] as List).add({
          'transaction_id': _uuid.v4(),
          'category_id': null,
          'title': 'Menombok periode ${_periodLabel(carryOverPeriod)}',
          'amount': deficitAmount,
          'date': normalizedStart.toIso8601String(),
          'type': 'expense',
        });
        _recalculatePeriod(carryOverPeriod);
        _recalculatePeriod(period);
      }
    }

    periods.add(period);
    _sortPeriods(periods);
    database['current_period_id'] = periodId;
    await _saveDatabase();

    return period;
  }

  Future<void> addIncome({
    required String periodId,
    required int amount,
    required String title,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);

    (data['transactions'] as List).add({
      'transaction_id': _uuid.v4(),
      'category_id': null,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': 'income',
    });
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> updateIncome({
    required String periodId,
    required String transactionId,
    required int amount,
    required String title,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    final transaction = _findTransaction(data, transactionId);
    transaction['title'] = title;
    transaction['amount'] = amount;
    transaction['date'] = date.toIso8601String();
    transaction['type'] = 'income';
    transaction['category_id'] = null;
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> addExpense({
    required String periodId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);

    (data['transactions'] as List).add({
      'transaction_id': _uuid.v4(),
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': 'expense',
    });

    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> updateExpense({
    required String periodId,
    required String transactionId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    final transaction = _findTransaction(data, transactionId);
    transaction['category_id'] = categoryId;
    transaction['title'] = title;
    transaction['amount'] = amount;
    transaction['date'] = date.toIso8601String();
    transaction['type'] = 'expense';
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> deleteTransaction({
    required String periodId,
    required String transactionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    (data['transactions'] as List).removeWhere((transaction) {
      final item = transaction as Map<String, dynamic>;
      return item['transaction_id'] == transactionId;
    });
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> addCategory({
    required String periodId,
    required String name,
    required int allocatedAmount,
    num? allocationPercent,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    final category = {
      'category_id': _uuid.v4(),
      'category_name': name,
      'base_allocated_amount': allocatedAmount,
      'allocated_amount': allocatedAmount,
      'remaining_amount': allocatedAmount,
    };
    if (allocationPercent != null) {
      category['allocation_percent'] = allocationPercent;
    }

    (data['categories'] as List).add(category);
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> updateCategory({
    required String periodId,
    required String categoryId,
    required String name,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    final category = _findCategory(data, categoryId);
    category['category_name'] = name;
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> adjustCategoryBudget({
    required String periodId,
    required String categoryId,
    required String action,
    required int amount,
    required String reason,
    required DateTime date,
    String? relatedCategoryId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    _recalculatePeriod(data);

    final category = _findCategory(data, categoryId);
    final previousAmount = _asInt(category['allocated_amount']);
    final newAmount = switch (action) {
      'increase' => previousAmount + amount,
      'decrease' => previousAmount - amount,
      'set' => amount,
      _ => previousAmount,
    };
    if (newAmount < 0) {
      throw StateError('Nominal anggaran tidak boleh kurang dari nol.');
    }

    final deltaAmount = newAmount - previousAmount;
    if (deltaAmount == 0) return;

    if (relatedCategoryId == null && deltaAmount > 0) {
      final remainingAllocation = _remainingAllocation(data);
      if (deltaAmount > remainingAllocation) {
        throw StateError(
          'Nominal melebihi sisa yang belum dibagi, yaitu ${_formatPlainAmount(remainingAllocation)}.',
        );
      }
    }

    if (relatedCategoryId != null) {
      final relatedCategory = _findCategory(data, relatedCategoryId);
      final relatedPreviousAmount = _asInt(relatedCategory['allocated_amount']);
      final relatedNewAmount = relatedPreviousAmount - deltaAmount;
      if (relatedNewAmount < 0) {
        throw StateError('Nominal anggaran sumber tidak mencukupi.');
      }
      _appendCategoryAdjustment(
        data,
        categoryId: relatedCategoryId,
        relatedCategoryId: categoryId,
        action: _actionFromDelta(-deltaAmount),
        amount: deltaAmount.abs(),
        deltaAmount: -deltaAmount,
        previousAmount: relatedPreviousAmount,
        newAmount: relatedNewAmount,
        reason: reason,
        date: date,
      );
      _syncCategoryFormula(
        relatedCategory,
        totalIncome: _asInt(data['total_income']),
        targetAmount: relatedNewAmount,
      );
    }

    _appendCategoryAdjustment(
      data,
      categoryId: categoryId,
      relatedCategoryId: relatedCategoryId,
      action: action,
      amount: deltaAmount.abs(),
      deltaAmount: deltaAmount,
      previousAmount: previousAmount,
      newAmount: newAmount,
      reason: reason,
      date: date,
    );

    _syncCategoryFormula(
      category,
      totalIncome: _asInt(data['total_income']),
      targetAmount: newAmount,
    );
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> deleteCategory({
    required String periodId,
    required String categoryId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final data = _findPeriod(database, periodId);
    final hasTransactions = (data['transactions'] as List).any((transaction) {
      final item = transaction as Map<String, dynamic>;
      return item['category_id'] == categoryId;
    });
    final hasAdjustments = (data['category_adjustments'] as List).any((
      adjustment,
    ) {
      final item = adjustment as Map<String, dynamic>;
      return item['category_id'] == categoryId ||
          item['related_category_id'] == categoryId;
    });
    if (hasTransactions || hasAdjustments) {
      throw StateError('Anggaran sudah memiliki riwayat.');
    }

    (data['categories'] as List).removeWhere((category) {
      final item = category as Map<String, dynamic>;
      return item['category_id'] == categoryId;
    });
    _recalculatePeriod(data);
    await _saveDatabase();
  }

  Future<void> deleteBudgetPeriod(String periodId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final periods = (database['periods'] as List).cast<Map<String, dynamic>>();
    periods.removeWhere((item) => item['period_id'] == periodId);
    if (database['current_period_id'] == periodId) {
      database['current_period_id'] = periods.isEmpty
          ? null
          : periods.first['period_id'];
    }
    await _saveDatabase();
  }

  Future<void> updateBudgetPeriod({
    required String periodId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final database = await _readDatabase();
    final periods = (database['periods'] as List).cast<Map<String, dynamic>>();
    final period = _findPeriod(database, periodId);
    final normalizedStart = _dateOnly(startDate);
    final normalizedEnd = _dateOnly(endDate);
    if (!normalizedEnd.isAfter(normalizedStart)) {
      throw StateError('Tanggal selesai periode harus setelah tanggal mulai.');
    }
    if (_rangeOverlapsExistingPeriod(
      periods,
      periodId,
      normalizedStart,
      normalizedEnd,
    )) {
      throw StateError('Tanggal yang dipilih bertabrakan dengan periode lain.');
    }

    period['start_date'] = normalizedStart.toIso8601String();
    period['end_date'] = DateTime(
      normalizedEnd.year,
      normalizedEnd.month,
      normalizedEnd.day,
      23,
      59,
      59,
    ).toIso8601String();
    _sortPeriods(periods);
    await _saveDatabase();
  }

  Future<Map<String, dynamic>> _readDatabase() async {
    if (_database != null) return _database!;

    final file = await _storageFile();
    if (!await file.exists()) {
      _database = createEmptyFinanceData();
      await _saveDatabase();
      return _database!;
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Finance storage root must be an object.');
      }
      _database = _normalizeDatabase(decoded);
      await _saveDatabase();
      return _database!;
    } on FormatException {
      _database = createEmptyFinanceData();
      await _saveDatabase();
      return _database!;
    }
  }

  Future<void> _saveDatabase() async {
    final file = await _storageFile();
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(_database ?? createEmptyFinanceData()),
    );
  }

  Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }

  Map<String, dynamic> _normalizeDatabase(Map<String, dynamic> database) {
    final normalized = createEmptyFinanceData();
    final rawPeriods = database['periods'];
    final periods = rawPeriods is List
        ? rawPeriods.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    for (final period in periods) {
      period['categories'] = (period['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      period['transactions'] = (period['transactions'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      period['category_adjustments'] =
          (period['category_adjustments'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
      final rawTotalIncome = (period['transactions'] as List)
          .cast<Map<String, dynamic>>()
          .where((transaction) => transaction['type'] == 'income')
          .fold<int>(
            0,
            (total, transaction) => total + _asInt(transaction['amount']),
          );
      for (final category
          in (period['categories'] as List).cast<Map<String, dynamic>>()) {
        category['base_allocated_amount'] =
            category['base_allocated_amount'] as int? ??
            _asInt(category['allocated_amount']);
        if (category.containsKey('allocation_percent') && rawTotalIncome > 0) {
          category['allocation_percent'] = _normalizePercent(
            _percentageFromAmount(
              _asInt(
                category['base_allocated_amount'] ??
                    category['allocated_amount'],
              ),
              rawTotalIncome,
            ),
          );
        }
      }
      period['allocations_follow_income'] =
          period['allocations_follow_income'] as bool? ??
          (period['categories'] as List).cast<Map<String, dynamic>>().any(
            (category) => category.containsKey('allocation_percent'),
          );
      _recalculatePeriod(period);
    }

    _sortPeriods(periods);
    normalized['periods'] = periods;
    normalized['transaction_templates'] =
        (database['transaction_templates'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .where((item) {
              return item['transaction_template_id'] is String &&
                  item['title'] is String &&
                  item['amount'] is int &&
                  item['type'] is String &&
                  item['created_at'] is String;
            })
            .map((item) {
              return {
                'transaction_template_id': item['transaction_template_id'],
                'title': item['title'],
                'amount': _asInt(item['amount']),
                'type': item['type'] == 'income' ? 'income' : 'expense',
                'preferred_category_name': item['preferred_category_name'],
                'day_of_month': item['day_of_month'],
                'created_at': item['created_at'],
              };
            })
            .toList();
    _sortTransactionTemplates(
      (normalized['transaction_templates'] as List)
          .cast<Map<String, dynamic>>(),
    );

    final currentPeriodId = database['current_period_id'] as String?;
    final currentIdIsValid =
        currentPeriodId != null &&
        periods.any((period) => period['period_id'] == currentPeriodId);
    normalized['current_period_id'] = currentIdIsValid
        ? currentPeriodId
        : (periods.isEmpty ? null : periods.first['period_id']);

    return normalized;
  }

  Map<String, dynamic> _findPeriod(
    Map<String, dynamic> database,
    String periodId,
  ) {
    return (database['periods'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((period) => period['period_id'] == periodId);
  }

  Map<String, dynamic> _findTransaction(
    Map<String, dynamic> period,
    String transactionId,
  ) {
    return (period['transactions'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (transaction) => transaction['transaction_id'] == transactionId,
        );
  }

  Map<String, dynamic> _findCategory(
    Map<String, dynamic> period,
    String categoryId,
  ) {
    return (period['categories'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((category) => category['category_id'] == categoryId);
  }

  void _recalculatePeriod(Map<String, dynamic> period) {
    final transactions = (period['transactions'] as List)
        .cast<Map<String, dynamic>>();
    final categories = (period['categories'] as List)
        .cast<Map<String, dynamic>>();
    final adjustments = (period['category_adjustments'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final totalIncome = transactions
        .where((transaction) => transaction['type'] == 'income')
        .fold<int>(
          0,
          (total, transaction) => total + _asInt(transaction['amount']),
        );
    final totalExpense = transactions
        .where((transaction) => transaction['type'] == 'expense')
        .fold<int>(
          0,
          (total, transaction) => total + _asInt(transaction['amount']),
        );

    for (final category in categories) {
      final categoryId = category['category_id'];
      final followsIncome = category.containsKey('allocation_percent');
      final adjustmentTotal = followsIncome
          ? 0
          : adjustments
                .where((adjustment) => adjustment['category_id'] == categoryId)
                .fold<int>(
                  0,
                  (total, adjustment) =>
                      total + _asInt(adjustment['delta_amount']),
                );
      var baseAllocatedAmount = _asInt(
        category['base_allocated_amount'] ?? category['allocated_amount'],
      );
      if (followsIncome) {
        final percentage = _asDouble(category['allocation_percent']);
        baseAllocatedAmount = _amountFromPercentage(totalIncome, percentage);
        category['base_allocated_amount'] = baseAllocatedAmount;
      }
      final allocatedAmount = baseAllocatedAmount + adjustmentTotal;
      category['allocated_amount'] = allocatedAmount;
      final categoryExpense = transactions
          .where(
            (transaction) =>
                transaction['type'] == 'expense' &&
                transaction['category_id'] == categoryId,
          )
          .fold<int>(
            0,
            (total, transaction) => total + _asInt(transaction['amount']),
          );
      category['remaining_amount'] = allocatedAmount - categoryExpense;
    }

    period['total_income'] = totalIncome;
    period['total_allocatable'] = totalIncome - totalExpense;
  }

  void _sortPeriods(List<Map<String, dynamic>> periods) {
    periods.sort((a, b) {
      final aStart = DateTime.parse(a['start_date'] as String);
      final bStart = DateTime.parse(b['start_date'] as String);
      return bStart.compareTo(aStart);
    });
  }

  void _sortTransactionTemplates(List<Map<String, dynamic>> templates) {
    templates.sort((a, b) {
      final aRecurring = a['day_of_month'] != null;
      final bRecurring = b['day_of_month'] != null;
      if (aRecurring != bRecurring) return aRecurring ? -1 : 1;
      final aCreated = DateTime.parse(a['created_at'] as String);
      final bCreated = DateTime.parse(b['created_at'] as String);
      return bCreated.compareTo(aCreated);
    });
  }

  int _amountFromPercentage(int total, num percentage) {
    return ((total * percentage) / 100).round();
  }

  double _percentageFromAmount(int amount, int total) {
    if (total <= 0) return 0;
    return (amount / total) * 100;
  }

  void _syncCategoryFormula(
    Map<String, dynamic> category, {
    required int totalIncome,
    required int targetAmount,
  }) {
    if (!category.containsKey('allocation_percent')) return;

    final percentage = _percentageFromAmount(targetAmount, totalIncome);
    category['allocation_percent'] = _normalizePercent(percentage);
    category['base_allocated_amount'] = targetAmount;
    category['allocated_amount'] = targetAmount;
  }

  num _normalizePercent(double value) {
    final rounded = double.parse(value.toStringAsFixed(6));
    if (rounded == rounded.roundToDouble()) return rounded.toInt();
    return rounded;
  }

  int _remainingAllocation(Map<String, dynamic> period) {
    final categories = (period['categories'] as List)
        .cast<Map<String, dynamic>>();
    final allocatedTotal = categories.fold<int>(
      0,
      (total, category) => total + _asInt(category['allocated_amount']),
    );
    return _asInt(period['total_income']) - allocatedTotal;
  }

  String _formatPlainAmount(int value) {
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buffer = StringBuffer(sign);
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _periodLabel(Map<String, dynamic> period) {
    final startDate = DateTime.parse(period['start_date'] as String);
    final endDate = DateTime.parse(period['end_date'] as String);
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _rangeOverlapsExistingPeriod(
    List<Map<String, dynamic>> periods,
    String ignoredPeriodId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return periods.any((period) {
      if (period['period_id'] == ignoredPeriodId) return false;
      final periodStart = _dateOnly(
        DateTime.parse(period['start_date'] as String),
      );
      final periodEnd = _dateOnly(DateTime.parse(period['end_date'] as String));
      return !endDate.isBefore(periodStart) && !startDate.isAfter(periodEnd);
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _actionFromDelta(int deltaAmount) {
    return deltaAmount >= 0 ? 'increase' : 'decrease';
  }

  void _appendCategoryAdjustment(
    Map<String, dynamic> period, {
    required String categoryId,
    required String action,
    required int amount,
    required int deltaAmount,
    required int previousAmount,
    required int newAmount,
    required String reason,
    required DateTime date,
    String? relatedCategoryId,
  }) {
    (period['category_adjustments'] as List).add({
      'adjustment_id': _uuid.v4(),
      'category_id': categoryId,
      'related_category_id': relatedCategoryId,
      'type': action,
      'amount': amount,
      'delta_amount': deltaAmount,
      'previous_amount': previousAmount,
      'new_amount': newAmount,
      'reason': reason,
      'date': date.toIso8601String(),
    });
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }
}
