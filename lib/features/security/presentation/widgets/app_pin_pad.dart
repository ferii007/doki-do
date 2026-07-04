import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AppPinDots extends StatelessWidget {
  final int filledCount;
  final int length;
  final bool hasError;

  const AppPinDots({
    super.key,
    required this.filledCount,
    this.length = 6,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < length; index++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: index < filledCount
                    ? (hasError ? AppColors.danger : AppColors.primary)
                    : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasError ? AppColors.danger : AppColors.border,
                  width: 1.5,
                ),
              ),
            ),
            if (index != length - 1) const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

class AppPinPad extends StatelessWidget {
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  const AppPinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const keys = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 18,
            childAspectRatio: 1.35,
            children: [
              for (final key in keys)
                _PinKey(
                  label: '$key',
                  onTap: enabled ? () => onDigit(key) : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PinKey(
                  icon: Icons.fingerprint_rounded,
                  onTap: enabled ? onBiometric : null,
                  invisible: onBiometric == null,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _PinKey(
                  label: '0',
                  onTap: enabled ? () => onDigit(0) : null,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _PinKey(
                  icon: Icons.backspace_outlined,
                  onTap: enabled ? onBackspace : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool invisible;

  const _PinKey({this.label, this.icon, this.onTap, this.invisible = false});

  @override
  Widget build(BuildContext context) {
    if (invisible) return const SizedBox(height: 64);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        overlayColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: 0.08),
        ),
        onTap: onTap,
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: icon == null
                ? Text(
                    label!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(icon, color: AppColors.textPrimary, size: 25),
          ),
        ),
      ),
    );
  }
}
