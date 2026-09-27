<div align="center">
  <img src="assets/icon/icon.png" width="128" height="128" alt="App icon">
  <h1>Hotspot Channel Setter</h1>
  <p>Sets the Wi-Fi hotspot (SoftAP) channel on Android, with Shizuku or root.</p>
  <p><a href="README.md">English</a> | <a href="README.ru.md">Русский</a></p>
</div>

<p align="center">
  <img src="assets/screenshots/screen-root.jpg" width="300" alt="Root mode">
  <img src="assets/screenshots/screen-shizuku.jpg" width="300" alt="Shizuku mode">
</p>

## Features

- Lists the channels the device reports for the 2.4 GHz and 5 GHz bands, with an option to include DFS and disabled ones.
- Stores the selected channel in the hotspot configuration, so the choice survives a reboot.
- Shows the channel currently stored in the hotspot settings.
- Two access methods, Shizuku (no root) and root; the selected one is remembered.
- English and Russian.

## Requirements

- Shizuku installed and running, or root.
- Android 12 or newer for Shizuku mode.

## Version support

List and apply were checked on emulators: Android 10, 11, 12, 14, 15, 16 and 17. Android 13 was checked on a real device.

| Android | Shizuku — list | Shizuku — apply | Root — list | Root — apply |
| :---: | :--- | :---: | :--- | :---: |
| 10 | not available | — | `iw list` | — |
| 11 | standard list when the system reports nothing | ✓ | `iw list` | ✓ |
| 12–17 | system capability | ✓ | `iw list` | ✓ |

Methods the app uses:

**Channel list**

| Method | Mode | Android |
| :--- | :---: | :---: |
| System hotspot capability | Shizuku | 12+ |
| `dumpsys wifi` — `mCurrentSoftApCapability` (second source) | Shizuku, root | 13+ |
| `iw list` (main source) | root | 10+ |
| Standard channel list | Shizuku | 11 |

**Apply**

| Method | Mode | Android | Lasts |
| :--- | :---: | :---: | :--- |
| Hidden `setSoftApConfiguration` | Shizuku, root | 11+ | after a reboot |
| `cmd wifi force-softap-channel` | root | 11+ | until a reboot |

On Android 10 the channel cannot be applied: the system API for it does not exist, and `cmd wifi` of that version has neither `force-softap-channel` nor `get-allowed-channel`.

## How it works

- **Channel list** — Shizuku mode reads the hotspot capability the system reports (Android 12 and newer), with the framework dump as a second source (Android 13 and newer); on Android 11 it shows the standard list. Root mode uses `iw list` and the dump.
- **Apply** — the channel is written into the hotspot configuration, which is what the system hotspot uses:

  ```text
  getSoftApConfiguration() -> copy with the new channel -> setSoftApConfiguration()
  ```

- **Current channel** — read back with the same configuration API.

In Shizuku mode this code runs in a Shizuku user service with shell identity, in root mode in a helper process started with `app_process`.

Root mode can also apply the channel for the current session only, with the legacy command that Android 12 and newer allow to root alone:

```shell
cmd wifi force-softap-channel enabled <frequency>
```

## Install

Download the APK from the [Releases](https://github.com/Lorax121/hotspot_channel_setter/releases) page. Builds of 1.0.x are signed with a different key, so the old version has to be uninstalled before installing 1.1.x.

## Build

```shell
flutter pub get
flutter build apk --release
```

Release builds are signed with the keystore described in `android/key.properties`, which is not tracked by Git.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
