import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Channel Setter'**
  String get appName;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @band2_4GHz.
  ///
  /// In en, this message translates to:
  /// **'2.4 GHz'**
  String get band2_4GHz;

  /// No description provided for @band5GHz.
  ///
  /// In en, this message translates to:
  /// **'5 GHz'**
  String get band5GHz;

  /// No description provided for @selectChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Select a channel'**
  String get selectChannelHint;

  /// No description provided for @availableChannelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available channels'**
  String get availableChannelsLabel;

  /// No description provided for @channelDropdownItem.
  ///
  /// In en, this message translates to:
  /// **'Channel {channelNumber} ({frequency} MHz)'**
  String channelDropdownItem(int channelNumber, int frequency);

  /// No description provided for @showAllChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show all channels'**
  String get showAllChannelsTitle;

  /// No description provided for @showAllChannelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Including DFS and disabled ones'**
  String get showAllChannelsSubtitle;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @applyingButton.
  ///
  /// In en, this message translates to:
  /// **'Applying…'**
  String get applyingButton;

  /// No description provided for @applySuccessPersistent.
  ///
  /// In en, this message translates to:
  /// **'Channel {channelNumber} ({frequency} MHz) saved and will be used after a reboot.'**
  String applySuccessPersistent(int channelNumber, int frequency);

  /// No description provided for @applySuccessSession.
  ///
  /// In en, this message translates to:
  /// **'Channel {channelNumber} ({frequency} MHz) applied until the next reboot.'**
  String applySuccessSession(int channelNumber, int frequency);

  /// No description provided for @applyFormatPersist.
  ///
  /// In en, this message translates to:
  /// **'Keep the channel after a reboot'**
  String get applyFormatPersist;

  /// No description provided for @shizukuPersistHint.
  ///
  /// In en, this message translates to:
  /// **'Shizuku saves the channel in the hotspot settings, so it stays after a reboot.'**
  String get shizukuPersistHint;

  /// No description provided for @errorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Error: {errorMessage}'**
  String errorSnackbar(String errorMessage);

  /// No description provided for @quickSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick select:'**
  String get quickSelectLabel;

  /// No description provided for @quickSelectChipLabel.
  ///
  /// In en, this message translates to:
  /// **'{bandName}: {frequency} MHz'**
  String quickSelectChipLabel(String bandName, int frequency);

  /// No description provided for @channelNotFoundSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Channel {frequency} MHz is not in the list. Turn on \"Show all channels\".'**
  String channelNotFoundSnackbar(int frequency);

  /// No description provided for @applyFailedButNoErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'The command did not run and reported no reason.'**
  String get applyFailedButNoErrorSnackbar;

  /// No description provided for @accessModeShizuku.
  ///
  /// In en, this message translates to:
  /// **'Shizuku'**
  String get accessModeShizuku;

  /// No description provided for @accessModeRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get accessModeRoot;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Access method'**
  String get settingsAccessSection;

  /// No description provided for @settingsChannelSection.
  ///
  /// In en, this message translates to:
  /// **'Hotspot channel'**
  String get settingsChannelSection;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsResetChannel.
  ///
  /// In en, this message translates to:
  /// **'Restore automatic channel'**
  String get settingsResetChannel;

  /// No description provided for @resetChannelDone.
  ///
  /// In en, this message translates to:
  /// **'The device picks the channel again'**
  String get resetChannelDone;

  /// No description provided for @errorNeedsConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection to Shizuku'**
  String get errorNeedsConnectionTitle;

  /// No description provided for @errorNeedsRootTitle.
  ///
  /// In en, this message translates to:
  /// **'Root access is required'**
  String get errorNeedsRootTitle;

  /// No description provided for @connectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectButton;

  /// No description provided for @requestRootButton.
  ///
  /// In en, this message translates to:
  /// **'Request root'**
  String get requestRootButton;

  /// No description provided for @checkAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgainButton;

  /// No description provided for @accessBackendShizuku.
  ///
  /// In en, this message translates to:
  /// **'Shizuku'**
  String get accessBackendShizuku;

  /// No description provided for @accessBackendRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get accessBackendRoot;

  /// No description provided for @activeAccessBackend.
  ///
  /// In en, this message translates to:
  /// **'Access: {backend}'**
  String activeAccessBackend(String backend);

  /// No description provided for @commandErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not run the system command.'**
  String get commandErrorGeneric;

  /// No description provided for @commandErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The system did not respond in time.'**
  String get commandErrorTimeout;

  /// No description provided for @commandErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'The system denied the command.'**
  String get commandErrorPermissionDenied;

  /// No description provided for @commandErrorNoPrivilegedAccess.
  ///
  /// In en, this message translates to:
  /// **'No access to system commands. Start Shizuku or grant the app root access.'**
  String get commandErrorNoPrivilegedAccess;

  /// No description provided for @commandErrorRootUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Grant the app root access in KernelSU or Magisk.'**
  String get commandErrorRootUnavailable;

  /// No description provided for @commandErrorShizukuNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is not installed. Install and start it.'**
  String get commandErrorShizukuNotInstalled;

  /// No description provided for @commandErrorShizukuNotRunning.
  ///
  /// In en, this message translates to:
  /// **'The Shizuku service is not running. Start it and try again.'**
  String get commandErrorShizukuNotRunning;

  /// No description provided for @commandErrorShizukuPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'The app needs Shizuku permission.'**
  String get commandErrorShizukuPermissionDenied;

  /// No description provided for @commandErrorShizukuUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This Shizuku version is not supported. Update Shizuku.'**
  String get commandErrorShizukuUnsupported;

  /// No description provided for @commandErrorShizukuServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the Shizuku service. Restart it and try again.'**
  String get commandErrorShizukuServiceUnavailable;

  /// No description provided for @commandErrorIwNotFound.
  ///
  /// In en, this message translates to:
  /// **'The iw tool is not available on this device.'**
  String get commandErrorIwNotFound;

  /// No description provided for @commandErrorCmdWifiNotFound.
  ///
  /// In en, this message translates to:
  /// **'The \"cmd wifi\" command is not supported on this device.'**
  String get commandErrorCmdWifiNotFound;

  /// No description provided for @commandErrorInvalidFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency {frequency} MHz is not available on this device.'**
  String commandErrorInvalidFrequency(int frequency);

  /// No description provided for @commandErrorNoResult.
  ///
  /// In en, this message translates to:
  /// **'The system command returned no result.'**
  String get commandErrorNoResult;

  /// No description provided for @commandErrorBadResult.
  ///
  /// In en, this message translates to:
  /// **'The system returned an empty channel list.'**
  String get commandErrorBadResult;

  /// No description provided for @commandErrorChannelListUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the channel list ({reason}). On Android 11-13 turn the hotspot on once and try again.'**
  String commandErrorChannelListUnavailable(String reason);

  /// No description provided for @commandErrorCommandNeedsRoot.
  ///
  /// In en, this message translates to:
  /// **'Android 12+ allows this command only for root. Start Shizuku through root or switch to Root mode.'**
  String get commandErrorCommandNeedsRoot;

  /// No description provided for @commandErrorChannelNotStored.
  ///
  /// In en, this message translates to:
  /// **'Could not save the channel: {reason}.'**
  String commandErrorChannelNotStored(String reason);

  /// No description provided for @storeReasonRejected.
  ///
  /// In en, this message translates to:
  /// **'the system rejected the new hotspot configuration'**
  String get storeReasonRejected;

  /// No description provided for @storeReasonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'the system did not return the hotspot settings'**
  String get storeReasonUnavailable;

  /// No description provided for @storeReasonUnsupportedAndroid.
  ///
  /// In en, this message translates to:
  /// **'saving a channel requires Android 11 or newer'**
  String get storeReasonUnsupportedAndroid;

  /// No description provided for @storeReasonUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown reason'**
  String get storeReasonUnknown;

  /// No description provided for @applyUntilRebootAction.
  ///
  /// In en, this message translates to:
  /// **'Until reboot'**
  String get applyUntilRebootAction;

  /// No description provided for @channelSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel list: {source}'**
  String channelSourceLabel(String source);

  /// No description provided for @channelSourceIw.
  ///
  /// In en, this message translates to:
  /// **'iw'**
  String get channelSourceIw;

  /// No description provided for @channelSourceCmdWifi.
  ///
  /// In en, this message translates to:
  /// **'cmd wifi'**
  String get channelSourceCmdWifi;

  /// No description provided for @channelSourceSoftApCapability.
  ///
  /// In en, this message translates to:
  /// **'dumpsys'**
  String get channelSourceSoftApCapability;

  /// No description provided for @currentChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Current channel: {channelNumber} ({frequency} MHz)'**
  String currentChannelLabel(int channelNumber, int frequency);

  /// No description provided for @currentChannelAuto.
  ///
  /// In en, this message translates to:
  /// **'Current channel: auto'**
  String get currentChannelAuto;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
