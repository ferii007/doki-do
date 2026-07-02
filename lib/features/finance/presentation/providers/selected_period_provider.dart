import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedPeriodIdProvider =
    NotifierProvider<SelectedPeriodIdNotifier, String?>(
      SelectedPeriodIdNotifier.new,
    );

class SelectedPeriodIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? periodId) {
    state = periodId;
  }
}
