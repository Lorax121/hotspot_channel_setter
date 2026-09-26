<div align="center">
  <img src="assets/icon/icon.png" width="128" height="128" alt="Иконка приложения">
  <h1>WiFi Channel Setter</h1>
  <p>Устанавливает канал точки доступа Wi-Fi (SoftAP) на Android через Shizuku или root.</p>
  <p><a href="README.md">English</a> | <a href="README.ru.md">Русский</a></p>
</div>

<p align="center">
  <img src="assets/screenshots/screen-root.jpg" width="300" alt="Режим Root">
  <img src="assets/screenshots/screen-shizuku.jpg" width="300" alt="Режим Shizuku">
</p>

## Возможности

- Показывает каналы, которые устройство сообщает для диапазонов 2.4 и 5 ГГц, с опцией включить DFS и отключённые.
- Записывает выбранный канал в конфигурацию точки доступа, поэтому выбор сохраняется после перезагрузки.
- Показывает канал, который сейчас записан в настройках точки доступа.
- Два способа доступа — Shizuku (без root) и root; выбранный запоминается.
- Русский и английский языки.

## Требования

- Android 11 или новее.
- Установленный и запущенный Shizuku либо root.

## Как это работает

- **Список каналов** — приложение спрашивает само устройство: `iw list`, `cmd wifi get-allowed-channel` (Android 14 и новее) либо данные SoftAP из `dumpsys wifi`. Используемый источник показан в приложении.
- **Применение** — канал записывается в конфигурацию точки доступа, которую использует системная точка доступа:

  ```text
  getSoftApConfiguration() -> копия с новым каналом -> setSoftApConfiguration()
  ```

- **Текущий канал** — читается тем же конфигурационным API.

В режиме Shizuku этот код выполняется в Shizuku user service с правами shell, в режиме root — во вспомогательном процессе, запущенном через `app_process`.

В режиме root канал можно также применить только на текущую сессию — устаревшей командой, которую Android 12 и новее разрешает только root:

```shell
cmd wifi force-softap-channel enabled <частота>
```

## Установка

Скачайте APK со страницы [Релизов](https://github.com/Lorax121/hotspot_channel_setter/releases). Сборки 1.0.x подписаны другим ключом, поэтому перед установкой 1.1.0 старую версию нужно удалить.

## Сборка

```shell
flutter pub get
flutter build apk --release
```

Релизные сборки подписываются ключом, описанным в `android/key.properties` — файл не отслеживается Git.

## История изменений

См. [CHANGELOG.md](CHANGELOG.md).
