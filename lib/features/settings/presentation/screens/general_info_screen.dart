import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class GeneralInfoScreen extends StatelessWidget {
  const GeneralInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('general_info'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.description_outlined,
                title: context.tr('terms_and_conditions'),
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.termsAndConditions),
              ),
              _InfoRow(
                icon: Icons.privacy_tip_outlined,
                title: context.tr('privacy_policy'),
                showDivider: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.privacyPolicy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  final String titleKey;
  final String contentKey;

  const LegalDocumentScreen({
    super.key,
    required this.titleKey,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(titleKey))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.tr(contentKey),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
      ],
    );
  }
}
