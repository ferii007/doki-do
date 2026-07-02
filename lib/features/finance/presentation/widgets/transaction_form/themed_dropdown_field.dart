import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../../app/theme/app_colors.dart';

class ThemedDropdownOption<T> {
  final T? value;
  final String title;
  final String? subtitle;

  const ThemedDropdownOption({
    required this.value,
    required this.title,
    this.subtitle,
  });
}

class ThemedDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<ThemedDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final FocusNode? focusNode;
  final IconData icon;

  const ThemedDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.focusNode,
    this.icon = Icons.keyboard_arrow_down_rounded,
  });

  @override
  State<ThemedDropdownField<T>> createState() => _ThemedDropdownFieldState<T>();
}

class _ThemedDropdownFieldState<T> extends State<ThemedDropdownField<T>> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Size _fieldSize = Size.zero;
  bool _isOpen = false;

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Builder(
            builder: (fieldContext) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  widget.focusNode?.requestFocus();
                  _toggleOverlay(fieldContext, constraints.maxWidth);
                },
                child: InputDecorator(
                  isFocused: _isOpen || (widget.focusNode?.hasFocus ?? false),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(widget.icon),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    floatingLabelStyle: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    selected?.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  ThemedDropdownOption<T>? get _selectedOption {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  void _toggleOverlay(BuildContext fieldContext, double width) {
    if (_isOpen) {
      _closeOverlay();
      return;
    }
    _openOverlay(fieldContext, width);
  }

  void _openOverlay(BuildContext fieldContext, double width) {
    _closeOverlay();

    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    _fieldSize = renderBox?.size ?? Size(width, 56);
    final dropdownMaxHeight = _dropdownMaxHeight(fieldContext);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, _fieldSize.height + 8),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: _fieldSize.width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dropdownMaxHeight),
                    child: _DropdownOptionsCard<T>(
                      options: widget.options,
                      value: widget.value,
                      onChanged: (value) {
                        _closeOverlay();
                        widget.focusNode?.unfocus();
                        widget.onChanged(value);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _isOpen) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }
  }

  double _dropdownMaxHeight(BuildContext fieldContext) {
    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    final fieldOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final media = MediaQuery.of(fieldContext);
    final bottomLimit =
        media.size.height - media.padding.bottom - media.viewInsets.bottom - 16;
    final availableBelow = bottomLimit - fieldOffset.dy - _fieldSize.height - 8;
    final maxHeight = math.min(280.0, math.max(0.0, availableBelow));
    return maxHeight;
  }
}

class _DropdownOptionsCard<T> extends StatelessWidget {
  final T? value;
  final List<ThemedDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;

  const _DropdownOptionsCard({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              _DropdownOptionTile<T>(
                option: option,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownOptionTile<T> extends StatelessWidget {
  final ThemedDropdownOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _DropdownOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
