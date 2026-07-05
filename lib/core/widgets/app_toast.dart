import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppToast {
  static const _maximumVisible = 3;
  static const _exitDuration = Duration(milliseconds: 220);
  static final List<_ToastItem> _items = [];
  static OverlayEntry? _overlayEntry;
  static int _nextId = 0;

  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    assert(actionLabel == null || onAction != null);
    final overlay = Overlay.of(context, rootOverlay: true);
    final item = _ToastItem(
      id: _nextId++,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    _items.insert(0, item);

    while (_items.where((item) => !item.exiting).length > _maximumVisible) {
      final oldestVisible = _items.lastWhere((item) => !item.exiting);
      _beginDismiss(oldestVisible, rebuild: false);
    }

    _overlayEntry ??= OverlayEntry(builder: _buildOverlay);
    if (!_overlayEntry!.mounted) overlay.insert(_overlayEntry!);
    _overlayEntry!.markNeedsBuild();

    item.timer = Timer(
      Duration(seconds: actionLabel == null ? 2 : 5),
      () => _beginDismiss(item),
    );
  }

  static Widget _buildOverlay(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 16,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, item) in _items.indexed) ...[
              _ToastCard(
                key: ValueKey(item.id),
                item: item,
                onDismiss: () => _beginDismiss(item),
              ),
              if (index != _items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  static void _beginDismiss(_ToastItem item, {bool rebuild = true}) {
    if (item.exiting) return;
    item.timer?.cancel();
    item.timer = null;
    item.exiting = true;
    if (rebuild) _overlayEntry?.markNeedsBuild();
    item.exitTimer = Timer(_exitDuration, () => _removeImmediately(item));
  }

  static void _removeImmediately(_ToastItem item) {
    item.timer?.cancel();
    item.exitTimer?.cancel();
    item.timer = null;
    item.exitTimer = null;
    _items.remove(item);
    if (_items.isEmpty) {
      final entry = _overlayEntry;
      if (entry?.mounted ?? false) entry!.remove();
      _overlayEntry = null;
      return;
    }
    _overlayEntry?.markNeedsBuild();
  }
}

class _ToastItem {
  final int id;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  Timer? timer;
  Timer? exitTimer;
  bool exiting = false;

  _ToastItem({
    required this.id,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
}

class _ToastCard extends StatelessWidget {
  final _ToastItem item;
  final VoidCallback onDismiss;

  const _ToastCard({super.key, required this.item, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: item.exiting ? const Offset(0, 0.65) : Offset.zero,
      duration: AppToast._exitDuration,
      curve: Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: item.exiting ? 0 : 1,
        duration: AppToast._exitDuration,
        curve: Curves.easeInCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.overlay,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    onDismiss();
                    item.onAction?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    item.actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
