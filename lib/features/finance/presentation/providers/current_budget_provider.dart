import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_period.dart';
import '../../domain/entities/budget_snapshot.dart';
import '../../domain/usecases/get_budget_by_period_id.dart';
import '../../domain/usecases/get_current_budget.dart';
import '../../domain/usecases/get_budget_periods.dart';
import 'finance_repository_provider.dart';
import 'selected_period_provider.dart';

final budgetPeriodsProvider = FutureProvider<List<BudgetPeriod>>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return GetBudgetPeriods(repository).call();
});

final currentBudgetProvider = FutureProvider<BudgetSnapshot?>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  final selectedPeriodId = ref.watch(selectedPeriodIdProvider);

  if (selectedPeriodId == null) {
    return GetCurrentBudget(repository).call();
  }

  return GetBudgetByPeriodId(repository).call(selectedPeriodId);
});

final budgetByPeriodProvider = FutureProvider.family<BudgetSnapshot, String>((
  ref,
  periodId,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return GetBudgetByPeriodId(repository).call(periodId);
});

final allBudgetSnapshotsProvider = FutureProvider<List<BudgetSnapshot>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  final periods = await GetBudgetPeriods(repository).call();
  final snapshots = <BudgetSnapshot>[];

  for (final period in periods) {
    snapshots.add(await GetBudgetByPeriodId(repository).call(period.id));
  }

  return snapshots;
});
