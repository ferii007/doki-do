import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class LoadingView extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const LoadingView({super.key, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return _SkeletonPulse(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SkeletonBox(height: 136, borderRadius: 22),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _SkeletonBox(height: 92)),
                SizedBox(width: 12),
                Expanded(child: _SkeletonBox(height: 92)),
              ],
            ),
            SizedBox(height: 18),
            _SkeletonBox(widthFactor: 0.48, height: 22, borderRadius: 8),
            SizedBox(height: 12),
            _SkeletonBox(height: 76),
            SizedBox(height: 10),
            _SkeletonBox(height: 76),
            SizedBox(height: 10),
            _SkeletonBox(height: 76),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final Widget child;

  const _SkeletonPulse({required this.child});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.48,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? height;
  final double borderRadius;
  final double? widthFactor;

  const _SkeletonBox({this.height, this.borderRadius = 16, this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.mintSurface.withValues(alpha: 0.82),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.52)),
      ),
    );

    if (widthFactor == null) {
      return SizedBox(width: double.infinity, child: box);
    }

    return FractionallySizedBox(widthFactor: widthFactor, child: box);
  }
}
