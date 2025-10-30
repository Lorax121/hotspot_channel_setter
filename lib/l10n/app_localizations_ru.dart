// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Настройка канала WiFi';

  @override
  String get errorOccurred => 'Произошла ошибка';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get band2_4GHz => '2.4 ГГц';

  @override
  String get band5GHz => '5 ГГц';

  @override
  String get selectChannelHint => 'Выберите канал';

  @override
  String get availableChannelsLabel => 'Доступные каналы';

  @override
  String channelDropdownItem(int channelNumber, int frequency) {
    return 'Канал $channelNumber ($frequency МГц)';
  }

  @override
  String get showAllChannelsTitle => 'Показать все каналы';

  @override
  String get showAllChannelsSubtitle => 'Включая каналы с DFS и отключенные';

  @override
  String get applyButton => 'Применить';

  @override
  String applySuccessSnackbar(int channelNumber, int frequency) {
    return 'Канал $channelNumber ($frequency МГц) успешно применен!';
  }

  @override
  String errorSnackbar(String errorMessage) {
    return 'Ошибка: $errorMessage';
  }
}
