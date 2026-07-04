import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../finance/presentation/widgets/dashboard/settings_tab_body.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: const SingleChildScrollView(child: SettingsTabBody()),
    );
  }
}
