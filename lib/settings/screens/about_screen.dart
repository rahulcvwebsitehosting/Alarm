import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/navigation/widgets/app_top_bar.dart';
import 'package:clock_app/settings/screens/licenses.dart';
import 'package:clock_app/settings/types/setting_link.dart';
import 'package:clock_app/settings/widgets/setting_page_link_card.dart';
import 'package:clock_app/system/data/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: AppLocalizations.of(context)!.aboutSettingGroup,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const AboutInfo(),
              SettingPageLinkCard(
                setting: SettingPageLink(
                  'Open Source Licenses',
                  (context) =>
                      AppLocalizations.of(context)!.openSourceLicensesSetting,
                  const LicensesScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutInfo extends StatelessWidget {
  const AboutInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AboutRow(
              icon: Icons.alarm_rounded,
              label: packageInfo?.appName ?? 'Alarm',
              value: 'Smart alarms, timers, and clocks',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 12),
            _AboutRow(
              icon: Icons.info_outline_rounded,
              label: AppLocalizations.of(context)!.versionLabel,
              value: packageInfo?.version ?? '1.0.0',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 12),
            _AboutRow(
              icon: Icons.center_focus_weak_rounded,
              label: AppLocalizations.of(context)!.packageNameLabel,
              value: packageInfo?.packageName ??
                  'com.rahulcvwebsitehosting.alarm',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Icon(icon, color: colorScheme.onSurface),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
