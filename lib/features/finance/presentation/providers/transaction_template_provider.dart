import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/recurring_due_item.dart';
import '../../domain/entities/recurring_occurrence.dart';
import '../../domain/services/monthly_recurrence_calculator.dart';
import 'finance_repository_provider.dart';
import 'recurring_notification_provider.dart';

final transactionTemplatesProvider = FutureProvider<List<TransactionTemplate>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getTransactionTemplates();
});

final recurringOccurrencesProvider = FutureProvider<List<RecurringOccurrence>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getRecurringOccurrences();
});

final recurringDueItemsProvider = FutureProvider<List<RecurringDueItem>>((
  ref,
) async {
  final templates = await ref.watch(transactionTemplatesProvider.future);
  final occurrences = await ref.watch(recurringOccurrencesProvider.future);
  return MonthlyRecurrenceCalculator.pendingItems(
    templates: templates,
    occurrences: occurrences,
    today: DateTime.now(),
  );
});

final transactionTemplateActionProvider =
    NotifierProvider<TransactionTemplateActionNotifier, bool>(
      TransactionTemplateActionNotifier.new,
    );

class TransactionTemplateActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<bool?> save({
    String? templateId,
    required TransactionType type,
    required String title,
    required int amount,
    String? preferredCategoryName,
    int? dayOfMonth,
    bool isActive = true,
    DateTime? activeFromDate,
    DateTime? endDate,
    bool reminderEnabled = true,
    int reminderHour = 9,
    int reminderMinute = 0,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.saveTransactionTemplate(
        templateId: templateId,
        type: type == TransactionType.income ? 'income' : 'expense',
        title: title,
        amount: amount,
        preferredCategoryName: preferredCategoryName,
        dayOfMonth: dayOfMonth,
        isActive: isActive,
        activeFromDate: activeFromDate,
        endDate: endDate,
        reminderEnabled: reminderEnabled,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );
      _invalidateRecurring();
      bool? permissionGranted;
      if (dayOfMonth != null && reminderEnabled) {
        permissionGranted = await _requestNotificationPermission();
      }
      await _runNotificationTask(() => syncRecurringNotifications(ref));
      return permissionGranted;
    } finally {
      state = false;
    }
  }

  Future<void> delete(String templateId) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.deleteTransactionTemplate(templateId);
      _invalidateRecurring();
      await _runNotificationTask(() => syncRecurringNotifications(ref));
    } finally {
      state = false;
    }
  }

  Future<void> setActive({
    required String templateId,
    required bool isActive,
  }) async {
    state = true;
    try {
      await ref
          .read(financeRepositoryProvider)
          .setTransactionTemplateActive(
            templateId: templateId,
            isActive: isActive,
            changedAt: DateTime.now(),
          );
      _invalidateRecurring();
      await _runNotificationTask(() => syncRecurringNotifications(ref));
    } finally {
      state = false;
    }
  }

  Future<void> skip({
    required String templateId,
    required DateTime dueDate,
  }) async {
    state = true;
    try {
      await ref
          .read(financeRepositoryProvider)
          .skipRecurringOccurrence(templateId: templateId, dueDate: dueDate);
      _invalidateRecurring();
      await _runNotificationTask(
        () => ref
            .read(recurringNotificationServiceProvider)
            .cancelOccurrence(templateId: templateId, dueDate: dueDate),
      );
      await _runNotificationTask(() => syncRecurringNotifications(ref));
    } finally {
      state = false;
    }
  }

  void _invalidateRecurring() {
    ref.invalidate(transactionTemplatesProvider);
    ref.invalidate(recurringOccurrencesProvider);
    ref.invalidate(recurringDueItemsProvider);
  }

  Future<void> _runNotificationTask(Future<Object?> Function() task) async {
    try {
      await task();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'recurring notifications',
        ),
      );
    }
  }

  Future<bool?> _requestNotificationPermission() async {
    try {
      return await ref
          .read(recurringNotificationServiceProvider)
          .requestPermission();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'recurring notifications',
        ),
      );
      return null;
    }
  }
}
