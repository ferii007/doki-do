import '../../domain/entities/budget_period.dart';
import '../../domain/entities/budget_allocation_draft.dart';
import '../../domain/entities/budget_snapshot.dart';
import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/recurring_occurrence.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_local_datasource.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceLocalDatasource datasource;

  FinanceRepositoryImpl({required this.datasource});

  @override
  Future<BudgetSnapshot?> getCurrentBudget() async {
    final json = await datasource.getCurrentBudget();
    if (json == null) return null;
    return BudgetSnapshot.fromJson(json);
  }

  @override
  Future<List<BudgetPeriod>> getBudgetPeriods() async {
    final json = await datasource.getBudgetPeriods();
    return json.map(BudgetPeriod.fromJson).toList();
  }

  @override
  Future<BudgetSnapshot> getBudgetByPeriodId(String periodId) async {
    final json = await datasource.getBudgetByPeriodId(periodId);
    return BudgetSnapshot.fromJson(json);
  }

  @override
  Future<List<TransactionTemplate>> getTransactionTemplates() async {
    final json = await datasource.getTransactionTemplates();
    return json.map(TransactionTemplate.fromJson).toList();
  }

  @override
  Future<List<RecurringOccurrence>> getRecurringOccurrences() async {
    final json = await datasource.getRecurringOccurrences();
    return json.map(RecurringOccurrence.fromJson).toList();
  }

  @override
  Future<void> saveTransactionTemplate({
    String? templateId,
    required String type,
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
  }) {
    return datasource.saveTransactionTemplate(
      templateId: templateId,
      type: type,
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
  }

  @override
  Future<void> deleteTransactionTemplate(String templateId) {
    return datasource.deleteTransactionTemplate(templateId);
  }

  @override
  Future<void> setTransactionTemplateActive({
    required String templateId,
    required bool isActive,
    required DateTime changedAt,
  }) {
    return datasource.setTransactionTemplateActive(
      templateId: templateId,
      isActive: isActive,
      changedAt: changedAt,
    );
  }

  @override
  Future<void> skipRecurringOccurrence({
    required String templateId,
    required DateTime dueDate,
  }) {
    return datasource.skipRecurringOccurrence(
      templateId: templateId,
      dueDate: dueDate,
    );
  }

  @override
  Future<BudgetPeriod> addBudgetPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required int initialIncome,
    required String incomeSource,
    required List<BudgetAllocationDraft> defaultAllocations,
    required bool allocationsFollowIncome,
    String? carryOverFromPeriodId,
  }) async {
    final json = await datasource.addBudgetPeriod(
      startDate: startDate,
      endDate: endDate,
      initialIncome: initialIncome,
      incomeSource: incomeSource,
      defaultAllocations: defaultAllocations,
      allocationsFollowIncome: allocationsFollowIncome,
      carryOverFromPeriodId: carryOverFromPeriodId,
    );
    return BudgetPeriod.fromJson(json);
  }

  @override
  Future<void> addIncome({
    required String periodId,
    required int amount,
    required String title,
    required DateTime date,
    String? recurringTemplateId,
    DateTime? recurringDueDate,
  }) {
    return datasource.addIncome(
      periodId: periodId,
      amount: amount,
      title: title,
      date: date,
      recurringTemplateId: recurringTemplateId,
      recurringDueDate: recurringDueDate,
    );
  }

  @override
  Future<void> updateIncome({
    required String periodId,
    required String transactionId,
    required int amount,
    required String title,
    required DateTime date,
  }) {
    return datasource.updateIncome(
      periodId: periodId,
      transactionId: transactionId,
      amount: amount,
      title: title,
      date: date,
    );
  }

  @override
  Future<void> addExpense({
    required String periodId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
    String? recurringTemplateId,
    DateTime? recurringDueDate,
  }) {
    return datasource.addExpense(
      periodId: periodId,
      categoryId: categoryId,
      amount: amount,
      title: title,
      date: date,
      recurringTemplateId: recurringTemplateId,
      recurringDueDate: recurringDueDate,
    );
  }

  @override
  Future<void> updateExpense({
    required String periodId,
    required String transactionId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  }) {
    return datasource.updateExpense(
      periodId: periodId,
      transactionId: transactionId,
      categoryId: categoryId,
      amount: amount,
      title: title,
      date: date,
    );
  }

  @override
  Future<void> deleteTransaction({
    required String periodId,
    required String transactionId,
  }) {
    return datasource.deleteTransaction(
      periodId: periodId,
      transactionId: transactionId,
    );
  }

  @override
  Future<void> addCategory({
    required String periodId,
    required String name,
    required int allocatedAmount,
    num? allocationPercent,
  }) {
    return datasource.addCategory(
      periodId: periodId,
      name: name,
      allocatedAmount: allocatedAmount,
      allocationPercent: allocationPercent,
    );
  }

  @override
  Future<void> updateCategory({
    required String periodId,
    required String categoryId,
    required String name,
  }) {
    return datasource.updateCategory(
      periodId: periodId,
      categoryId: categoryId,
      name: name,
    );
  }

  @override
  Future<void> adjustCategoryBudget({
    required String periodId,
    required String categoryId,
    required String action,
    required int amount,
    required String reason,
    required DateTime date,
    String? relatedCategoryId,
  }) {
    return datasource.adjustCategoryBudget(
      periodId: periodId,
      categoryId: categoryId,
      action: action,
      amount: amount,
      reason: reason,
      date: date,
      relatedCategoryId: relatedCategoryId,
    );
  }

  @override
  Future<void> deleteCategory({
    required String periodId,
    required String categoryId,
  }) {
    return datasource.deleteCategory(
      periodId: periodId,
      categoryId: categoryId,
    );
  }

  @override
  Future<void> updateBudgetPeriod({
    required String periodId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return datasource.updateBudgetPeriod(
      periodId: periodId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> deleteBudgetPeriod(String periodId) {
    return datasource.deleteBudgetPeriod(periodId);
  }
}
