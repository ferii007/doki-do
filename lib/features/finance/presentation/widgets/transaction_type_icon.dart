import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

List<TextSpan> transactionTypeTextIconSpans({
  required bool isIncome,
  required Color color,
}) {
  final icon = isIncome ? Icons.add_card_outlined : Icons.credit_card_outlined;
  return [
    TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: color,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontWeight: FontWeight.w900,
      ),
    ),
    if (!isIncome)
      TextSpan(
        text: '−',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
  ];
}

class TransactionTypeIcon extends StatelessWidget {
  final bool isIncome;
  final double size;

  const TransactionTypeIcon({
    super.key,
    required this.isIncome,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.primary : AppColors.danger;
    final iconSize = size * 0.58;
    final badgeSize = size * 0.32;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: isIncome
          ? Icon(Icons.add_card_outlined, color: color, size: iconSize)
          : Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.credit_card_outlined, color: color, size: iconSize),
                Positioned(
                  right: size * 0.18,
                  bottom: size * 0.18,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: size * 0.037,
                      ),
                    ),
                    child: Icon(
                      isIncome ? Icons.add : Icons.remove,
                      color: Colors.white,
                      size: badgeSize * 0.72,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
