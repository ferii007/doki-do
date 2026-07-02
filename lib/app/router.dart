import 'package:flutter/material.dart';

import '../features/finance/presentation/screens/add_category_screen.dart';
import '../features/finance/presentation/screens/add_expense_screen.dart';
import '../features/finance/presentation/screens/add_income_screen.dart';
import '../features/finance/presentation/screens/add_period_screen.dart';
import '../features/finance/presentation/screens/category_detail_screen.dart';
import '../features/finance/presentation/screens/expense_detail_screen.dart';
import '../features/finance/presentation/screens/income_detail_screen.dart';
import '../features/finance/presentation/screens/transaction_templates_screen.dart';

class AppRouter {
  static const dashboard = '/';
  static const addIncome = '/add-income';
  static const addExpense = '/add-expense';
  static const addCategory = '/add-category';
  static const addPeriod = '/add-period';
  static const categoryDetail = '/category-detail';
  static const incomeDetail = '/income-detail';
  static const expenseDetail = '/expense-detail';
  static const transactionTemplates = '/transaction-templates';

  static Map<String, WidgetBuilder> get routes => {
    addIncome: (_) => const AddIncomeScreen(),
    addExpense: (_) => const AddExpenseScreen(),
    addCategory: (_) => const AddCategoryScreen(),
    addPeriod: (_) => const AddPeriodScreen(),
    categoryDetail: (_) => const CategoryDetailScreen(),
    incomeDetail: (_) => const IncomeDetailScreen(),
    expenseDetail: (_) => const ExpenseDetailScreen(),
    transactionTemplates: (_) => const TransactionTemplatesScreen(),
  };
}
