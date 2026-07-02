import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../formatters/rupiah_formatter.dart';

class AmountText extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final bool highlightNegative;
  final Color? negativeColor;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.highlightNegative = true,
    this.negativeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;

    return Text(
      RupiahFormatter.format(amount),
      style:
          style?.copyWith(
            color: highlightNegative && isNegative
                ? negativeColor ?? AppColors.danger
                : style?.color,
            fontWeight: highlightNegative && isNegative
                ? FontWeight.w700
                : style?.fontWeight,
          ) ??
          TextStyle(
            color: highlightNegative && isNegative
                ? negativeColor ?? AppColors.danger
                : null,
            fontWeight: highlightNegative && isNegative
                ? FontWeight.w700
                : null,
          ),
    );
  }
}
