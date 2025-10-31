<!-- README.md -->

<div align="center">
  <img src="assets/icon/icon.png" width="128" height="128" alt="App Icon">
  <h1>WiFi Channel Setter</h1>
  <p>A simple Android application for <strong>rooted devices</strong> to force a specific Wi-Fi hotspot (SoftAP) channel.</p>
  <p>
    <a href="README.md">English</a> | <a href="README.ru.md">Русский</a>
  </p>
</div>

---

## 📋 Overview

This Flutter-based application provides a straightforward way to control the channel of your Android device's Wi-Fi hotspot. It is designed for advanced users and developers who need to set a consistent, non-congested channel for testing, streaming, or stability purposes.

The app retrieves a list of all supported channels directly from the system, allows you to choose one, and applies it using a root command.


<p align="center">
  <img src="assets\icon\images\screenshot_en.jpg" alt="App Screenshot" width="300">
</p>

## ✨ Features

- **Channel Listing**: Fetches all available Wi-Fi channels for both 2.4 GHz and 5 GHz bands.
- **Smart Filtering**: By default, it only shows channels that are safe and allowed for use (non-DFS and enabled). An option to "Show all channels" is available for advanced users.
- **Persistent Memory**: The app remembers the last applied channel for each band (2.4 GHz and 5 GHz) separately, making it easy to re-apply your preferred settings.
- **Quick Select**: Displays badges for the last used channels for quick selection.
- **Root-Powered**: Utilizes root privileges to apply settings that are normally inaccessible to standard applications.
- **Multi-language Support**: Available in English and Russian.

## ⚠️ Requirements

- **Root Access is MANDATORY.** The core functionality of this app relies on executing privileged commands. It will not work on non-rooted devices.
- **Android Device**: The application is built for Android.

## 🛠️ How It Works

The application operates using two primary root commands executed via `su`:

1.  **Fetching Channels**: To get a list of all channels supported by your device's hardware, the app runs the following command:
    ```shell
    su -c "iw list"
    ```
    The output of this command contains detailed information about your Wi-Fi hardware capabilities, including supported frequencies and channels for each band. The app parses this output to build the channel selection list.

2.  **Applying a Channel**: When you press the "Apply" button, the app executes the Android `cmd` service to force the SoftAP (hotspot) to operate on the selected frequency:
    ```shell
    su -c "cmd wifi force-softap-channel enabled <frequency>"
    ```
    Where `<frequency>` is the selected channel's frequency in MHz (e.g., `2412` for Channel 1, `5180` for Channel 36).

## 🚀 Getting Started

1.  Ensure your Android device is rooted.
2.  Download the latest release APK from the [Releases](https://github.com/Lorax121/hotspot_channel_setter/releases) page.
3.  Install the APK on your device.
4.  Launch the app and grant root permissions when prompted by your root management app (e.g., Magisk).
5.  Select a band, choose a channel, and tap "Apply".
6.  Enable your Wi-Fi hotspot. It will now operate on the channel you selected.

## 🏗️ Building from Source

If you wish to build the project yourself:

1.  Clone the repository:
    ```shell
    git clone https://github.com/Lorax121/hotspot_channel_setter.git
    ```
2.  Navigate to the project directory:
    ```shell
    cd hotspot_channel_setter
    ```
3.  Get dependencies:
    ```shell
    flutter pub get
    ```
4.  Build the APK:
    ```shell
    flutter build apk --release
    ```
    The output APK will be located in `build/app/outputs/flutter-apk/`.

---
<div align="center">
  <p>Developed with ❤️ using Flutter</p>
</div>