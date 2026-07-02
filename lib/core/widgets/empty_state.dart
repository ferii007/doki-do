import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final double minHeight;

  const EmptyState({super.key, required this.message, this.minHeight = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
