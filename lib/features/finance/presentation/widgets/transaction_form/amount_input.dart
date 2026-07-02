import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/currency_input_formatter.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;

  const AmountInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: context.tr('amount'),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const _CurrencyPrefix(),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _CurrencyPrefix extends StatelessWidget {
  const _CurrencyPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Text(
        CurrencyFormatterPreference.current.symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
