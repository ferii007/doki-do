import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppInlineDivider extends StatelessWidget {
  final double height;
  final double horizontalMargin;

  const AppInlineDivider({
    super.key,
    this.height = 18,
    this.horizontalMargin = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      color: AppColors.border,
    );
  }
}
