import 'package:flutter/material.dart';

import '../features/backup/presentation/screens/local_backup_screen.dart';
import '../features/finance/presentation/screens/add_category_screen.dart';
import '../features/finance/presentation/screens/add_expense_screen.dart';
import '../features/finance/presentation/screens/add_income_screen.dart';
import '../features/finance/presentation/screens/add_period_screen.dart';
import '../features/finance/presentation/screens/category_detail_screen.dart';
import '../features/finance/presentation/screens/expense_detail_screen.dart';
import '../features/finance/presentation/screens/income_detail_screen.dart';
import '../features/finance/presentation/screens/transaction_templates_screen.dart';
import '../features/notifications/presentation/screens/notification_center_screen.dart';
import '../features/security/presentation/screens/app_lock_settings_screen.dart';
import '../features/settings/presentation/screens/general_info_screen.dart';
import '../features/settings/presentation/screens/export_report_templates_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

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
  static const appLockSettings = '/app-lock-settings';
  static const localBackup = '/local-backup';
  static const settings = '/settings';
  static const generalInfo = '/general-info';
  static const termsAndConditions = '/terms-and-conditions';
  static const privacyPolicy = '/privacy-policy';
  static const notifications = '/notifications';
  static const exportReportTemplates = '/export-report-templates';

  static Map<String, WidgetBuilder> get routes => {
    addIncome: (_) => const AddIncomeScreen(),
    addExpense: (_) => const AddExpenseScreen(),
    addCategory: (_) => const AddCategoryScreen(),
    addPeriod: (_) => const AddPeriodScreen(),
    categoryDetail: (_) => const CategoryDetailScreen(),
    incomeDetail: (_) => const IncomeDetailScreen(),
    expenseDetail: (_) => const ExpenseDetailScreen(),
    transactionTemplates: (_) => const TransactionTemplatesScreen(),
    appLockSettings: (_) => const AppLockSettingsScreen(),
    localBackup: (_) => const LocalBackupScreen(),
    settings: (_) => const SettingsScreen(),
    generalInfo: (_) => const GeneralInfoScreen(),
    termsAndConditions: (_) => const LegalDocumentScreen(
      titleKey: 'terms_and_conditions',
      contentKey: 'terms_and_conditions_content',
    ),
    privacyPolicy: (_) => const LegalDocumentScreen(
      titleKey: 'privacy_policy',
      contentKey: 'privacy_policy_content',
    ),
    notifications: (_) => const NotificationCenterScreen(),
    exportReportTemplates: (_) => const ExportReportTemplatesScreen(),
  };
}
