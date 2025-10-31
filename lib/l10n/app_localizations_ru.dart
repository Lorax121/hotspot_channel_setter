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
  String get applyingButton => 'Применение...';

  @override
  String applySuccessSnackbar(int channelNumber, int frequency) {
    return 'Канал $channelNumber ($frequency МГц) успешно применен!';
  }

  @override
  String errorSnackbar(String errorMessage) {
    return 'Ошибка: $errorMessage';
  }

  @override
  String get quickSelectLabel => 'Быстрый выбор:';

  @override
  String quickSelectChipLabel(String bandName, int frequency) {
    return '$bandName: $frequency МГц';
  }

  @override
  String channelNotFoundSnackbar(int frequency) {
    return 'Канал $frequency МГц не найден в текущем списке. Попробуйте включить \'Показать все каналы\'.';
  }

  @override
  String get applyFailedButNoErrorSnackbar =>
      'Команда не выполнилась, но не вернула ошибку.';

  @override
  String get adbError_generic =>
      'Не удалось выполнить команду. Проверьте root-доступ.';

  @override
  String get adbError_timeout => 'Таймаут команды. Устройство не отвечает.';

  @override
  String get adbError_permissionDenied =>
      'Доступ запрещен. Предоставьте root-права приложению.';

  @override
  String get adbError_iwNotFound => 'Команда \'iw\' не найдена на устройстве.';

  @override
  String get adbError_cmdWifiNotFound =>
      'Команда \'cmd wifi\' не поддерживается на этом устройстве.';

  @override
  String adbError_invalidFrequency(int frequency) {
    return 'Неверная частота $frequency МГц. Устройство не поддерживает этот канал.';
  }

  @override
  String get adbError_noResult =>
      'Команда не вернула результата. Проверьте root-доступ.';

  @override
  String get adbError_badResult =>
      'Команда вернула пустой или некорректный результат. Проверьте поддержку \'iw\' на устройстве.';
}
