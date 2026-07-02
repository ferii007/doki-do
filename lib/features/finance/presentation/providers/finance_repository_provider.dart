import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/finance_local_datasource.dart';
import '../../data/repositories/finance_repository_impl.dart';
import '../../domain/repositories/finance_repository.dart';

final financeLocalDatasourceProvider = Provider<FinanceLocalDatasource>((ref) {
  return FinanceLocalDatasource();
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepositoryImpl(
    datasource: ref.watch(financeLocalDatasourceProvider),
  );
});
