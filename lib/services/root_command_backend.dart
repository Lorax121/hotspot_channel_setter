import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:process_run/shell.dart';

import 'access_method.dart';
import 'command_result.dart';
import 'platform_bridge.dart';
import 'wifi_command_backend.dart';

class RootCommandBackend implements RootBackend {
  RootCommandBackend()
    : _shell = Shell(throwOnError: false, verbose: kDebugMode);

  static const String _appProcess = '/system/bin/app_process';
  static const String _binDir = '/system/bin';
  static const String _setterClass =
      'com.example.wifi_channel_setter.RootChannelSetter';

  final Shell _shell;

  @override
  AccessBackend get backend => AccessBackend.root;

  @override
  Future<CommandResult> getIwList() =>
      _run('su -c "iw list"', timeout: const Duration(seconds: 10));

  @override
  Future<CommandResult> getSoftApCapability() => _run(
    'su -c "dumpsys wifi 2>/dev/null | grep mCurrentSoftApCapability | head -n 1"',
    timeout: const Duration(seconds: 10),
  );

  @override
  Future<CommandResult> getSoftApState() => _runSetter();

  @override
  Future<CommandResult> setChannel(int frequency, {required bool persistent}) {
    if (!persistent) {
      return _run(
        'su -c "cmd wifi force-softap-channel enabled $frequency"',
        timeout: const Duration(seconds: 15),
      );
    }

    return _storeChannel(frequency);
  }

  @override
  Future<CommandResult> resetChannel() => _runSetter(auto: true);

  Future<CommandResult> _storeChannel(int frequency) =>
      _runSetter(frequency: frequency);

  Future<CommandResult> _runSetter({int? frequency, bool auto = false}) async {
    final appInfo = await PlatformBridge.appInfo();
    if (appInfo == null) {
      return const CommandResult(
        exitCode: 126,
        stdout: '',
        stderr: 'Application info is unavailable',
      );
    }

    final argument = auto ? ' auto' : (frequency == null ? '' : ' $frequency');
    return _run(
      'su -c "$_appProcess -Djava.class.path=${appInfo.sourceDir} '
      '$_binDir $_setterClass$argument"',
      timeout: const Duration(seconds: 30),
    );
  }

  Future<CommandResult> _run(
    String command, {
    required Duration timeout,
  }) async {
    try {
      final results = await _shell.run(command).timeout(timeout);
      if (results.isEmpty) {
        return const CommandResult(exitCode: -1, stdout: '', stderr: '');
      }

      final result = results.first;
      return CommandResult(
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    } on TimeoutException {
      _shell.kill();
      return const CommandResult(
        exitCode: 124,
        stdout: '',
        stderr: 'Command timed out',
        timedOut: true,
      );
    } catch (error) {
      return CommandResult(exitCode: 126, stdout: '', stderr: error.toString());
    }
  }
}
