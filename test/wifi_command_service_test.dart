import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_channel_setter/services/access_method.dart';
import 'package:wifi_channel_setter/services/channel_list.dart';
import 'package:wifi_channel_setter/services/command_result.dart';
import 'package:wifi_channel_setter/services/shizuku_command_backend.dart';
import 'package:wifi_channel_setter/services/wifi_command_backend.dart';
import 'package:wifi_channel_setter/services/wifi_command_exception.dart';
import 'package:wifi_channel_setter/services/wifi_command_service.dart';

const validIwOutput = '''
Wiphy phy0
\tBand 1:
\t\tFrequencies:
\t\t\t* 2412 MHz [1] (20.0 dBm)
\t\t\t* 2437 MHz [6] (20.0 dBm)
\tBand 2:
\t\tFrequencies:
\t\t\t* 5180 MHz [36] (23.0 dBm)
''';

const allowedChannelsOutput = '''
Allowed ch in STA mode:
2412 2437 5180
Allowed ch in SAP mode:
2412 2437 5180 5260
Allowed ch in WiFi-Direct GO mode:
2412 5180
''';

const deviceDumpOutput =
    'mCurrentSoftApCapability: SupportedFeatures=255 '
    'SupportedChannelListIn24g[1, 6] SupportedChannelListIn5g[36, 40] '
    'mCountryCodeFromDriverGE';

const standardListOutput = '''
standard
Allowed ch in SAP mode:
2412 2437
''';

const iwDeniedResult = CommandResult(
  exitCode: 1,
  stdout: '',
  stderr: 'ls: /system/bin/iw: Permission denied',
);

const unknownCommandResult = CommandResult(
  exitCode: 1,
  stdout: '',
  stderr: 'Unknown command: get-allowed-channel',
);

const rootMissingResult = CommandResult(
  exitCode: 1,
  stdout: '',
  stderr: 'sh: su: inaccessible or not found',
);

void main() {
  test('shizuku mode reads channels through Shizuku', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: false),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    final channelList = await service.loadChannels(AccessMode.shizuku);

    expect(channelList.source, ChannelListSource.system);
    expect(channelList.channels[1], hasLength(2));
    expect(service.activeBackend, AccessBackend.shizuku);
    expect(shizuku.allowedChannelsCalls, 1);
    expect(shizuku.iwCalls, 0);
    expect(root.iwCalls, 0);
  });

  test('marks the standard list on Android 11', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: true),
      allowedChannelsResult: const CommandResult(
        exitCode: 0,
        stdout: standardListOutput,
        stderr: '',
      ),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    final channelList = await service.loadChannels(AccessMode.shizuku);

    expect(channelList.source, ChannelListSource.standard);
    expect(channelList.channels[1]!.map((channel) => channel.frequency), [
      2412,
      2437,
    ]);
    expect(shizuku.softApCapabilityCalls, 0);
  });

  test('root mode reads channels through root', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: false, authorized: false),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    final channelList = await service.loadChannels(AccessMode.root);

    expect(channelList.source, ChannelListSource.iw);
    expect(service.activeBackend, AccessBackend.root);
    expect(shizuku.iwCalls, 0);
    expect(root.iwCalls, 1);
  });

  test('explicit Shizuku mode never falls back to root', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: false, authorized: false),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    await expectLater(
      service.loadChannels(AccessMode.shizuku),
      throwsA(
        isA<WiFiCommandException>().having(
          (error) => error.type,
          'type',
          WiFiCommandErrorType.shizukuNotRunning,
        ),
      ),
    );
    expect(root.iwCalls, 0);
  });

  test('reads channels through the system query when iw is blocked', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: true),
      iwResult: iwDeniedResult,
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    final channelList = await service.loadChannels(AccessMode.shizuku);

    expect(channelList.source, ChannelListSource.system);
    expect(channelList.channels[1]![0].channelNumber, 1);
    expect(channelList.channels[2], hasLength(2));
    expect(service.activeBackend, AccessBackend.shizuku);
    expect(shizuku.allowedChannelsCalls, 1);
    expect(shizuku.softApCapabilityCalls, 0);
    expect(root.iwCalls, 0);
  });

  test('reads channels from the device dump when other sources fail', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: true),
      iwResult: iwDeniedResult,
      allowedChannelsResult: unknownCommandResult,
      softApCapabilityResult: const CommandResult(
        exitCode: 0,
        stdout: deviceDumpOutput,
        stderr: '',
      ),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    final channelList = await service.loadChannels(AccessMode.shizuku);

    expect(channelList.source, ChannelListSource.softApCapability);
    expect(channelList.channels[1]!.map((channel) => channel.frequency), [
      2412,
      2437,
    ]);
    expect(channelList.channels[2]!.map((channel) => channel.frequency), [
      5180,
      5200,
    ]);
    expect(service.activeBackend, AccessBackend.shizuku);
    expect(root.iwCalls, 0);
  });

  test('reports an unavailable list when every source fails', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: true),
      iwResult: iwDeniedResult,
      allowedChannelsResult: unknownCommandResult,
      softApCapabilityResult: const CommandResult(
        exitCode: 1,
        stdout: '',
        stderr: 'grep: no match',
      ),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    await expectLater(
      service.loadChannels(AccessMode.shizuku),
      throwsA(
        isA<WiFiCommandException>().having(
          (error) => error.type,
          'type',
          WiFiCommandErrorType.channelListUnavailable,
        ),
      ),
    );
    expect(shizuku.softApCapabilityCalls, 1);
  });

  test('stops the chain when the privilege backend is unavailable', () async {
    final root = FakeBackend(
      AccessBackend.root,
      iwResult: rootMissingResult,
      softApCapabilityResult: rootMissingResult,
    );
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: false, authorized: false),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    await expectLater(
      service.loadChannels(AccessMode.root),
      throwsA(
        isA<WiFiCommandException>().having(
          (error) => error.type,
          'type',
          WiFiCommandErrorType.rootUnavailable,
        ),
      ),
    );
    expect(root.allowedChannelsCalls, 0);
    expect(root.softApCapabilityCalls, 0);
  });

  test('reports the root requirement for the apply command', () async {
    final root = FakeBackend(
      AccessBackend.root,
      iwResult: rootMissingResult,
      softApCapabilityResult: rootMissingResult,
    );
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: true),
      setChannelResult: const CommandResult(
        exitCode: 255,
        stdout: '',
        stderr:
            'java.lang.SecurityException: Uid 2000 does not have access to '
            'force-softap-channel wifi command (or such command doesn\'t exist)',
      ),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    await service.loadChannels(AccessMode.shizuku);

    await expectLater(
      service.setChannel(5180, persistent: false),
      throwsA(
        isA<WiFiCommandException>().having(
          (error) => error.type,
          'type',
          WiFiCommandErrorType.commandNeedsRoot,
        ),
      ),
    );
  });

  test('setChannel stays on the backend selected while loading', () async {
    final root = FakeBackend(AccessBackend.root);
    final shizuku = FakeShizukuBackend(
      const ShizukuStatus(installed: true, running: true, authorized: true),
    );
    final service = WiFiCommandService(
      rootBackend: root,
      shizukuBackend: shizuku,
    );

    await service.loadChannels(AccessMode.shizuku);
    await service.setChannel(5180, persistent: true);

    expect(shizuku.setChannelCalls, [5180]);
    expect(shizuku.setChannelPersistent, [true]);
    expect(root.setChannelCalls, isEmpty);
  });
}

class FakeBackend implements RootBackend {
  FakeBackend(
    this.backend, {
    this.iwResult = const CommandResult(
      exitCode: 0,
      stdout: validIwOutput,
      stderr: '',
    ),
    this.allowedChannelsResult,
    this.softApCapabilityResult,
    this.setChannelResult,
  });

  @override
  final AccessBackend backend;
  final CommandResult iwResult;
  final CommandResult? allowedChannelsResult;
  final CommandResult? softApCapabilityResult;
  final CommandResult? setChannelResult;
  int iwCalls = 0;
  int allowedChannelsCalls = 0;
  int softApCapabilityCalls = 0;
  final List<int> setChannelCalls = [];
  final List<bool> setChannelPersistent = [];

  @override
  Future<CommandResult> getIwList() async {
    iwCalls++;
    return iwResult;
  }

  Future<CommandResult> getAllowedChannels() async {
    allowedChannelsCalls++;
    return allowedChannelsResult ??
        const CommandResult(
          exitCode: 0,
          stdout: allowedChannelsOutput,
          stderr: '',
        );
  }

  @override
  Future<CommandResult> getSoftApCapability() async {
    softApCapabilityCalls++;
    return softApCapabilityResult ??
        const CommandResult(exitCode: 0, stdout: deviceDumpOutput, stderr: '');
  }

  @override
  Future<CommandResult> getSoftApState() async =>
      const CommandResult(exitCode: 0, stdout: 'Channels = {2=36}', stderr: '');

  @override
  Future<CommandResult> resetChannel() async =>
      const CommandResult(exitCode: 0, stdout: '', stderr: '');

  @override
  Future<CommandResult> setChannel(
    int frequency, {
    required bool persistent,
  }) async {
    setChannelCalls.add(frequency);
    setChannelPersistent.add(persistent);
    return setChannelResult ??
        const CommandResult(exitCode: 0, stdout: '', stderr: '');
  }
}

class FakeShizukuBackend extends FakeBackend implements ShizukuBackend {
  FakeShizukuBackend(
    this.status, {
    super.iwResult,
    super.allowedChannelsResult,
    super.softApCapabilityResult,
    super.setChannelResult,
  }) : super(AccessBackend.shizuku);

  final ShizukuStatus status;

  @override
  Future<ShizukuStatus> getStatus() async => status;

  @override
  Future<bool> requestPermission() async => true;
}
