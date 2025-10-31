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
  String get applyingButton => 'Applying...';

  @override
  String applySuccessSnackbar(int channelNumber, int frequency) {
    return 'Channel $channelNumber ($frequency MHz) applied successfully!';
  }

  @override
  String errorSnackbar(String errorMessage) {
    return 'Error: $errorMessage';
  }

  @override
  String get quickSelectLabel => 'Quick select:';

  @override
  String quickSelectChipLabel(String bandName, int frequency) {
    return '$bandName: $frequency MHz';
  }

  @override
  String channelNotFoundSnackbar(int frequency) {
    return 'Channel $frequency MHz not found in the current list. Try enabling \'Show all channels\'.';
  }

  @override
  String get applyFailedButNoErrorSnackbar =>
      'The command did not execute but returned no error.';

  @override
  String get adbError_generic =>
      'Failed to execute command. Please check root access.';

  @override
  String get adbError_timeout =>
      'Command timed out. The device may be unresponsive.';

  @override
  String get adbError_permissionDenied =>
      'Permission denied. Please grant root access to the application.';

  @override
  String get adbError_iwNotFound =>
      'The \'iw\' command was not found on this device.';

  @override
  String get adbError_cmdWifiNotFound =>
      'The \'cmd wifi\' command is not supported by this device.';

  @override
  String adbError_invalidFrequency(int frequency) {
    return 'Invalid frequency $frequency MHz. The device does not support this channel.';
  }

  @override
  String get adbError_noResult =>
      'The command returned no result. Check root access.';

  @override
  String get adbError_badResult =>
      'The command returned an empty or invalid result. Check \'iw\' support on the device.';
}
