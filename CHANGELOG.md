# Changelog

## 1.1.0

- Shizuku support: the channel can be set without root, through the shell identity Shizuku provides.
- The channel is stored in the hotspot configuration and survives a reboot, both with Shizuku and with root.
- Current channel indicator on the main screen.
- Settings screen with the access method, the language and a button that hands the channel choice back to the device.
- Root is the default access method on a fresh install; the choice is remembered afterwards.

## 1.0.0

- Root only.
- The channel is applied with `cmd wifi force-softap-channel` and is kept until the next reboot.
