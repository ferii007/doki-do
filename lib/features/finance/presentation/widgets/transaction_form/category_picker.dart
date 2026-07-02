import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../domain/entities/category_budget.dart';
import 'themed_dropdown_field.dart';

class CategoryPicker extends StatelessWidget {
  final List<CategoryBudget> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedDropdownField<String>(
      label: context.tr('budget_category'),
      value: selectedCategoryId,
      options: categories
          .map(
            (category) => ThemedDropdownOption<String>(
              value: category.id,
              title: category.name,
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
