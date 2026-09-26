import 'package:flutter/services.dart';

import 'access_method.dart';
import 'command_result.dart';
import 'platform_bridge.dart';
import 'wifi_command_backend.dart';
import 'wifi_command_exception.dart';

class ShizukuStatus {
  const ShizukuStatus({
    required this.installed,
    required this.running,
    required this.authorized,
    this.uid,
  });

  final bool installed;
  final bool running;
  final bool authorized;

  /// UID of the Shizuku server: 0 for root, 2000 for adb/shell.
  final int? uid;
}

abstract interface class ShizukuBackend implements WiFiCommandBackend {
  Future<ShizukuStatus> getStatus();

  Future<bool> requestPermission();
}

class ShizukuCommandBackend implements ShizukuBackend {
  static const MethodChannel _channel = PlatformBridge.channel;

  @override
  AccessBackend get backend => AccessBackend.shizuku;

  @override
  Future<ShizukuStatus> getStatus() async {
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'getStatus',
      );
      final uid = response?['uid'] as int?;
      return ShizukuStatus(
        installed: response?['installed'] == true,
        running: response?['running'] == true,
        authorized: response?['authorized'] == true,
        uid: uid == null || uid < 0 ? null : uid,
      );
    } on MissingPluginException {
      return const ShizukuStatus(
        installed: false,
        running: false,
        authorized: false,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      return granted == true;
    } on PlatformException catch (error) {
      throw WiFiCommandException(_mapPlatformError(error.code));
    } on MissingPluginException {
      throw const WiFiCommandException(WiFiCommandErrorType.shizukuUnsupported);
    }
  }

  @override
  Future<CommandResult> getIwList() => _invoke('getIwList');

  @override
  Future<CommandResult> getAllowedChannels() => _invoke('getAllowedChannels');

  @override
  Future<CommandResult> getSoftApCapability() => _invoke('getSoftApCapability');

  @override
  Future<CommandResult> getSoftApState() => _invoke('getSoftApState');

  @override
  Future<CommandResult> resetChannel() => _invoke('resetChannel');

  @override
  Future<CommandResult> setChannel(int frequency, {required bool persistent}) =>
      _invoke(
        'setChannel',
        arguments: {'frequency': frequency, 'persistent': persistent},
      );

  Future<CommandResult> _invoke(
    String method, {
    Map<String, dynamic>? arguments,
  }) async {
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        method,
        arguments,
      );
      if (response == null) {
        throw const WiFiCommandException(WiFiCommandErrorType.noResult);
      }

      return CommandResult(
        exitCode: response['exitCode'] as int? ?? -1,
        stdout: response['stdout'] as String? ?? '',
        stderr: response['stderr'] as String? ?? '',
        timedOut: response['timedOut'] == true,
      );
    } on PlatformException catch (error) {
      throw WiFiCommandException(_mapPlatformError(error.code));
    } on MissingPluginException {
      throw const WiFiCommandException(WiFiCommandErrorType.shizukuUnsupported);
    }
  }

  WiFiCommandErrorType _mapPlatformError(String code) {
    return switch (code) {
      'shizuku_not_installed' => WiFiCommandErrorType.shizukuNotInstalled,
      'shizuku_not_running' => WiFiCommandErrorType.shizukuNotRunning,
      'shizuku_permission_denied' =>
        WiFiCommandErrorType.shizukuPermissionDenied,
      'shizuku_unsupported' => WiFiCommandErrorType.shizukuUnsupported,
      'shizuku_service_connection' ||
      'shizuku_execution' => WiFiCommandErrorType.shizukuServiceUnavailable,
      'invalid_argument' => WiFiCommandErrorType.invalidFrequency,
      _ => WiFiCommandErrorType.generic,
    };
  }
}
