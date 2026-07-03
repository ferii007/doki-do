import 'package:flutter/widgets.dart';

class AppSpacing {
  static const double formFieldGap = 28;
  static const double formControlGap = 20;

  const AppSpacing._();
}

class AppFormFieldGap extends StatelessWidget {
  const AppFormFieldGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.formFieldGap);
  }
}

class AppFormControlGap extends StatelessWidget {
  const AppFormControlGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.formControlGap);
  }
}
