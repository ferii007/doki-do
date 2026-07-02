import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/category_budget.dart';

class CategoryEditResult {
  final String name;

  const CategoryEditResult({required this.name});
}

class CategoryEditSheet extends StatefulWidget {
  final CategoryBudget category;

  const CategoryEditSheet({super.key, required this.category});

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  late final TextEditingController _nameController;
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _nameFocusNode.addListener(_refreshFocusState);
  }

  @override
  void dispose() {
    _nameFocusNode
      ..removeListener(_refreshFocusState)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('edit_budget_category'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _FocusOnlyLabelTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: context.tr('budget_category_name'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(context.tr('save_changes')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      AppToast.show(
        context,
        context.tr('enter_the_budget_category_name_first'),
      );
      return;
    }

    Navigator.pop(context, CategoryEditResult(name: name));
  }

  void _refreshFocusState() {
    if (mounted) setState(() {});
  }
}

class _FocusOnlyLabelTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;

  const _FocusOnlyLabelTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
