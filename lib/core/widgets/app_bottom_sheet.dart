import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppSheetSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppSheetSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class AppSheetHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onClose;

  const AppSheetHeader({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.onClose,
  }) : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSheetHandle(),
        const SizedBox(height: 18),
        Row(
          children: [
            leading ??
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppSheetCloseButton(
              onTap: onClose ?? () => Navigator.maybePop(context),
            ),
          ],
        ),
      ],
    );
  }
}

class AppSheetCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const AppSheetCloseButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class AppSheetSectionTitle extends StatelessWidget {
  final String label;

  const AppSheetSectionTitle({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
