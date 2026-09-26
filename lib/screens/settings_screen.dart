import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_channel_setter/l10n/app_localizations.dart';
import '../services/access_method.dart';
import '../services/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.accessMode,
    required this.onAccessModeChanged,
    required this.onResetChannel,
  });

  final AccessMode accessMode;
  final ValueChanged<AccessMode> onAccessModeChanged;
  final Future<void> Function() onResetChannel;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AccessMode _accessMode = widget.accessMode;
  bool _isResetting = false;

  Future<void> _resetChannel() async {
    setState(() => _isResetting = true);
    try {
      await widget.onResetChannel();
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final languageCode = localeProvider.locale?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(S.settingsTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _sectionTitle(context, S.settingsAccessSection),
          _segments(
            SegmentedButton<AccessMode>(
              segments: [
                ButtonSegment(
                  value: AccessMode.shizuku,
                  label: Text(S.accessModeShizuku),
                ),
                ButtonSegment(
                  value: AccessMode.root,
                  label: Text(S.accessModeRoot),
                ),
              ],
              selected: {_accessMode},
              onSelectionChanged: (selection) {
                setState(() => _accessMode = selection.first);
                widget.onAccessModeChanged(selection.first);
              },
            ),
          ),
          const Divider(),
          _sectionTitle(context, S.settingsChannelSection),
          ListTile(
            leading: const Icon(Icons.restart_alt_outlined),
            title: Text(S.settingsResetChannel),
            enabled: !_isResetting,
            onTap: _resetChannel,
          ),
          const Divider(),
          _sectionTitle(context, S.settingsLanguageSection),
          _segments(
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'ru', label: Text('Русский')),
              ],
              selected: {languageCode},
              onSelectionChanged: (selection) =>
                  localeProvider.setLocale(Locale(selection.first)),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _segments(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
