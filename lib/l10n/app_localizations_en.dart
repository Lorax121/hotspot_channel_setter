// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Channel Setter';

  @override
  String get errorOccurred => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get band2_4GHz => '2.4 GHz';

  @override
  String get band5GHz => '5 GHz';

  @override
  String get selectChannelHint => 'Select a channel';

  @override
  String get availableChannelsLabel => 'Available channels';

  @override
  String channelDropdownItem(int channelNumber, int frequency) {
    return 'Channel $channelNumber ($frequency MHz)';
  }

  @override
  String get showAllChannelsTitle => 'Show all channels';

  @override
  String get showAllChannelsSubtitle => 'Including DFS and disabled ones';

  @override
  String get applyButton => 'Apply';

  @override
  String get applyingButton => 'Applying…';

  @override
  String applySuccessPersistent(int channelNumber, int frequency) {
    return 'Channel $channelNumber ($frequency MHz) saved and will be used after a reboot.';
  }

  @override
  String applySuccessSession(int channelNumber, int frequency) {
    return 'Channel $channelNumber ($frequency MHz) applied until the next reboot.';
  }

  @override
  String get applyFormatPersist => 'Keep the channel after a reboot';

  @override
  String get shizukuPersistHint =>
      'Shizuku saves the channel in the hotspot settings, so it stays after a reboot.';

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
    return 'Channel $frequency MHz is not in the list. Turn on \"Show all channels\".';
  }

  @override
  String get applyFailedButNoErrorSnackbar =>
      'The command did not run and reported no reason.';

  @override
  String get accessModeShizuku => 'Shizuku';

  @override
  String get accessModeRoot => 'Root';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccessSection => 'Access method';

  @override
  String get settingsChannelSection => 'Hotspot channel';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsResetChannel => 'Restore automatic channel';

  @override
  String get resetChannelDone => 'The device picks the channel again';

  @override
  String get errorNeedsConnectionTitle => 'No connection to Shizuku';

  @override
  String get errorNeedsRootTitle => 'Root access is required';

  @override
  String get connectButton => 'Connect';

  @override
  String get requestRootButton => 'Request root';

  @override
  String get checkAgainButton => 'Check again';

  @override
  String get accessBackendShizuku => 'Shizuku';

  @override
  String get accessBackendRoot => 'Root';

  @override
  String activeAccessBackend(String backend) {
    return 'Access: $backend';
  }

  @override
  String get commandErrorGeneric => 'Could not run the system command.';

  @override
  String get commandErrorTimeout => 'The system did not respond in time.';

  @override
  String get commandErrorPermissionDenied => 'The system denied the command.';

  @override
  String get commandErrorNoPrivilegedAccess =>
      'No access to system commands. Start Shizuku or grant the app root access.';

  @override
  String get commandErrorRootUnavailable =>
      'Grant the app root access in KernelSU or Magisk.';

  @override
  String get commandErrorShizukuNotInstalled =>
      'Shizuku is not installed. Install and start it.';

  @override
  String get commandErrorShizukuNotRunning =>
      'The Shizuku service is not running. Start it and try again.';

  @override
  String get commandErrorShizukuPermissionDenied =>
      'The app needs Shizuku permission.';

  @override
  String get commandErrorShizukuUnsupported =>
      'This Shizuku version is not supported. Update Shizuku.';

  @override
  String get commandErrorShizukuServiceUnavailable =>
      'Could not connect to the Shizuku service. Restart it and try again.';

  @override
  String get commandErrorIwNotFound =>
      'The iw tool is not available on this device.';

  @override
  String get commandErrorCmdWifiNotFound =>
      'The \"cmd wifi\" command is not supported on this device.';

  @override
  String commandErrorInvalidFrequency(int frequency) {
    return 'Frequency $frequency MHz is not available on this device.';
  }

  @override
  String get commandErrorNoResult => 'The system command returned no result.';

  @override
  String get commandErrorBadResult =>
      'The system returned an empty channel list.';

  @override
  String commandErrorChannelListUnavailable(String reason) {
    return 'Could not read the channel list ($reason).';
  }

  @override
  String get commandErrorCommandNeedsRoot =>
      'Android 12+ allows this command only for root. Start Shizuku through root or switch to Root mode.';

  @override
  String commandErrorChannelNotStored(String reason) {
    return 'Could not save the channel: $reason.';
  }

  @override
  String get storeReasonRejected =>
      'the system rejected the new hotspot configuration';

  @override
  String get storeReasonUnavailable =>
      'the system did not return the hotspot settings';

  @override
  String get storeReasonUnsupportedAndroid =>
      'saving a channel requires Android 11 or newer';

  @override
  String get storeReasonUnknown => 'unknown reason';

  @override
  String get applyUntilRebootAction => 'Until reboot';

  @override
  String channelSourceLabel(String source) {
    return 'Channel list: $source';
  }

  @override
  String get channelSourceIw => 'iw';

  @override
  String get channelSourceSystem => 'system';

  @override
  String get channelSourceSoftApCapability => 'dumpsys';

  @override
  String get channelSourceStandard => 'standard';

  @override
  String get channelListStandardWarning =>
      'This Android version does not report the device channels. A standard list is shown, so the hotspot may not support every channel in it.';

  @override
  String currentChannelLabel(int channelNumber, int frequency) {
    return 'Current channel: $channelNumber ($frequency MHz)';
  }

  @override
  String get currentChannelAuto => 'Current channel: auto';

  @override
  String get refreshTooltip => 'Refresh';
}
