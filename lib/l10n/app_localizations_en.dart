// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'WiFi Channel Setter';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get band2_4GHz => '2.4 GHz';

  @override
  String get band5GHz => '5 GHz';

  @override
  String get selectChannelHint => 'Select a channel';

  @override
  String get availableChannelsLabel => 'Available Channels';

  @override
  String channelDropdownItem(int channelNumber, int frequency) {
    return 'Channel $channelNumber ($frequency MHz)';
  }

  @override
  String get showAllChannelsTitle => 'Show all channels';

  @override
  String get showAllChannelsSubtitle => 'Including DFS and disabled channels';

  @override
  String get applyButton => 'Apply';

  @override
  String applySuccessSnackbar(int channelNumber, int frequency) {
    return 'Channel $channelNumber ($frequency MHz) applied successfully!';
  }

  @override
  String errorSnackbar(String errorMessage) {
    return 'Error: $errorMessage';
  }
}
