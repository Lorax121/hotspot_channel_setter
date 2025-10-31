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
  /// **'WiFi Channel Setter'**
  String get appName;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
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
  /// **'Available Channels'**
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
  /// **'Including DFS and disabled channels'**
  String get showAllChannelsSubtitle;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @applyingButton.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get applyingButton;

  /// No description provided for @applySuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Channel {channelNumber} ({frequency} MHz) applied successfully!'**
  String applySuccessSnackbar(int channelNumber, int frequency);

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
  /// **'Channel {frequency} MHz not found in the current list. Try enabling \'Show all channels\'.'**
  String channelNotFoundSnackbar(int frequency);

  /// No description provided for @applyFailedButNoErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'The command did not execute but returned no error.'**
  String get applyFailedButNoErrorSnackbar;

  /// No description provided for @adbError_generic.
  ///
  /// In en, this message translates to:
  /// **'Failed to execute command. Please check root access.'**
  String get adbError_generic;

  /// No description provided for @adbError_timeout.
  ///
  /// In en, this message translates to:
  /// **'Command timed out. The device may be unresponsive.'**
  String get adbError_timeout;

  /// No description provided for @adbError_permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please grant root access to the application.'**
  String get adbError_permissionDenied;

  /// No description provided for @adbError_iwNotFound.
  ///
  /// In en, this message translates to:
  /// **'The \'iw\' command was not found on this device.'**
  String get adbError_iwNotFound;

  /// No description provided for @adbError_cmdWifiNotFound.
  ///
  /// In en, this message translates to:
  /// **'The \'cmd wifi\' command is not supported by this device.'**
  String get adbError_cmdWifiNotFound;

  /// No description provided for @adbError_invalidFrequency.
  ///
  /// In en, this message translates to:
  /// **'Invalid frequency {frequency} MHz. The device does not support this channel.'**
  String adbError_invalidFrequency(int frequency);

  /// No description provided for @adbError_noResult.
  ///
  /// In en, this message translates to:
  /// **'The command returned no result. Check root access.'**
  String get adbError_noResult;

  /// No description provided for @adbError_badResult.
  ///
  /// In en, this message translates to:
  /// **'The command returned an empty or invalid result. Check \'iw\' support on the device.'**
  String get adbError_badResult;
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
