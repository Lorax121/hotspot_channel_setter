import 'package:flutter/services.dart';

class AppInfo {
  const AppInfo({required this.packageName, required this.sourceDir});

  final String packageName;
  final String sourceDir;
}

class PlatformBridge {
  static const MethodChannel channel = MethodChannel(
    'wifi_channel_setter/shizuku',
  );

  static Future<AppInfo?> appInfo() async {
    try {
      final response = await channel.invokeMapMethod<String, dynamic>(
        'getAppInfo',
      );
      final sourceDir = response?['sourceDir'] as String?;
      if (sourceDir == null) return null;

      return AppInfo(
        packageName: response?['packageName'] as String? ?? '',
        sourceDir: sourceDir,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
