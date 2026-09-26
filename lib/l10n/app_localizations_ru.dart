// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Настройка канала';

  @override
  String get errorOccurred => 'Произошла ошибка';

  @override
  String get tryAgain => 'Повторить';

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
  String get showAllChannelsSubtitle => 'Включая DFS и отключённые';

  @override
  String get applyButton => 'Применить';

  @override
  String get applyingButton => 'Применение…';

  @override
  String applySuccessPersistent(int channelNumber, int frequency) {
    return 'Канал $channelNumber ($frequency МГц) сохранён и будет использоваться после перезагрузки.';
  }

  @override
  String applySuccessSession(int channelNumber, int frequency) {
    return 'Канал $channelNumber ($frequency МГц) применён до перезагрузки.';
  }

  @override
  String get applyFormatPersist => 'Сохранять канал после перезагрузки';

  @override
  String get shizukuPersistHint =>
      'Shizuku сохраняет канал в настройках точки доступа — он останется после перезагрузки.';

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
    return 'Канал $frequency МГц отсутствует в списке. Включите «Показать все каналы».';
  }

  @override
  String get applyFailedButNoErrorSnackbar =>
      'Команда не выполнилась и не сообщила причину.';

  @override
  String get accessModeShizuku => 'Shizuku';

  @override
  String get accessModeRoot => 'Root';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAccessSection => 'Способ доступа';

  @override
  String get settingsChannelSection => 'Канал точки доступа';

  @override
  String get settingsLanguageSection => 'Язык';

  @override
  String get settingsResetChannel => 'Вернуть автоматический выбор';

  @override
  String get resetChannelDone => 'Канал снова выбирает устройство';

  @override
  String get errorNeedsConnectionTitle => 'Нет подключения к Shizuku';

  @override
  String get errorNeedsRootTitle => 'Нужны root-права';

  @override
  String get connectButton => 'Подключить';

  @override
  String get requestRootButton => 'Запросить root';

  @override
  String get checkAgainButton => 'Проверить снова';

  @override
  String get accessBackendShizuku => 'Shizuku';

  @override
  String get accessBackendRoot => 'Root';

  @override
  String activeAccessBackend(String backend) {
    return 'Доступ: $backend';
  }

  @override
  String get commandErrorGeneric => 'Не удалось выполнить системную команду.';

  @override
  String get commandErrorTimeout => 'Система не ответила вовремя.';

  @override
  String get commandErrorPermissionDenied =>
      'Система запретила выполнение команды.';

  @override
  String get commandErrorNoPrivilegedAccess =>
      'Нет доступа к системным командам. Запустите Shizuku или выдайте приложению root-права.';

  @override
  String get commandErrorRootUnavailable =>
      'Выдайте приложению root-права в KernelSU или Magisk.';

  @override
  String get commandErrorShizukuNotInstalled =>
      'Shizuku не установлен. Установите и запустите его.';

  @override
  String get commandErrorShizukuNotRunning =>
      'Служба Shizuku не запущена. Запустите её и повторите.';

  @override
  String get commandErrorShizukuPermissionDenied =>
      'Приложению нужно разрешение Shizuku.';

  @override
  String get commandErrorShizukuUnsupported =>
      'Версия Shizuku не поддерживается. Обновите Shizuku.';

  @override
  String get commandErrorShizukuServiceUnavailable =>
      'Не удалось подключиться к службе Shizuku. Перезапустите её и повторите.';

  @override
  String get commandErrorIwNotFound => 'Утилита «iw» недоступна на устройстве.';

  @override
  String get commandErrorCmdWifiNotFound =>
      'Команда «cmd wifi» не поддерживается на устройстве.';

  @override
  String commandErrorInvalidFrequency(int frequency) {
    return 'Частота $frequency МГц недоступна для этого устройства.';
  }

  @override
  String get commandErrorNoResult => 'Системная команда не вернула результат.';

  @override
  String get commandErrorBadResult => 'Система вернула пустой список каналов.';

  @override
  String commandErrorChannelListUnavailable(String reason) {
    return 'Не удалось получить список каналов ($reason). На Android 11–13 включите точку доступа один раз и повторите.';
  }

  @override
  String get commandErrorCommandNeedsRoot =>
      'Android 12+ разрешает эту команду только с root. Запустите Shizuku через root или выберите режим Root.';

  @override
  String commandErrorChannelNotStored(String reason) {
    return 'Не удалось сохранить канал: $reason.';
  }

  @override
  String get storeReasonRejected =>
      'система отклонила новую конфигурацию точки доступа';

  @override
  String get storeReasonUnavailable =>
      'система не вернула текущие настройки точки доступа';

  @override
  String get storeReasonUnsupportedAndroid =>
      'для сохранения канала нужен Android 11 или новее';

  @override
  String get storeReasonUnknown => 'причина неизвестна';

  @override
  String get applyUntilRebootAction => 'До перезагрузки';

  @override
  String channelSourceLabel(String source) {
    return 'Список каналов: $source';
  }

  @override
  String get channelSourceIw => 'iw';

  @override
  String get channelSourceCmdWifi => 'cmd wifi';

  @override
  String get channelSourceSoftApCapability => 'dumpsys';

  @override
  String currentChannelLabel(int channelNumber, int frequency) {
    return 'Текущий канал: $channelNumber ($frequency МГц)';
  }

  @override
  String get currentChannelAuto => 'Текущий канал: авто';

  @override
  String get refreshTooltip => 'Обновить';
}
