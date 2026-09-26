import '../models/wifi_channel.dart';
import 'access_method.dart';
import 'allowed_channel_parser.dart';
import 'channel_list.dart';
import 'command_result.dart';
import 'iw_parser.dart';
import 'root_command_backend.dart';
import 'shizuku_command_backend.dart';
import 'soft_ap_capability_parser.dart';
import 'soft_ap_state_parser.dart';
import 'wifi_command_backend.dart';
import 'wifi_command_exception.dart';

class WiFiCommandService {
  WiFiCommandService({
    WiFiCommandBackend? rootBackend,
    ShizukuBackend? shizukuBackend,
  }) : _rootBackend = rootBackend ?? RootCommandBackend(),
       _shizukuBackend = shizukuBackend ?? ShizukuCommandBackend();

  final WiFiCommandBackend _rootBackend;
  final ShizukuBackend _shizukuBackend;

  WiFiCommandBackend? _activeBackend;
  ShizukuStatus? _lastShizukuStatus;
  bool _isExecuting = false;

  AccessBackend? get activeBackend => _activeBackend?.backend;

  /// 0 when the Shizuku server runs as root, 2000 when it was started over adb.
  int? get shizukuUid => _lastShizukuStatus?.uid;

  Future<ChannelList> loadChannels(AccessMode mode) async {
    if (_isExecuting) {
      throw const WiFiCommandException(WiFiCommandErrorType.generic);
    }

    _isExecuting = true;
    _activeBackend = null;
    try {
      return await switch (mode) {
        AccessMode.shizuku => _loadChannelsWithShizuku(),
        AccessMode.root => _loadChannelsWith(_rootBackend),
      };
    } finally {
      _isExecuting = false;
    }
  }

  /// Asks Shizuku for access. Only called when the user taps the connect button.
  Future<bool> requestShizukuPermission() =>
      _shizukuBackend.requestPermission();

  /// Hands the channel choice back to the device, so it picks one by itself.
  Future<void> resetChannel(AccessMode mode) async {
    if (_isExecuting) {
      throw const WiFiCommandException(WiFiCommandErrorType.generic);
    }

    final backend = _activeBackend ?? await _resolveBackend(mode);
    _isExecuting = true;
    try {
      final result = await backend.resetChannel();
      _validateCommandResult(
        result,
        backend: backend.backend,
        command: _WiFiCommand.setChannel,
      );
    } finally {
      _isExecuting = false;
    }
  }

  Future<WiFiCommandBackend> _resolveBackend(AccessMode mode) async {
    if (mode == AccessMode.root) return _rootBackend;

    final status = await _shizukuBackend.getStatus();
    _lastShizukuStatus = status;
    if (!status.running) {
      throw WiFiCommandException(
        status.installed
            ? WiFiCommandErrorType.shizukuNotRunning
            : WiFiCommandErrorType.shizukuNotInstalled,
      );
    }
    return _shizukuBackend;
  }

  /// Reads the channel stored in the hotspot settings, for display purposes only.
  Future<SoftApState?> getSoftApState() async {
    final backend = _activeBackend;
    if (backend == null) return null;

    try {
      final result = await backend.getSoftApState();
      if (result.timedOut || result.exitCode != 0) return null;

      return SoftApStateParser.parse(result.stdout);
    } on WiFiCommandException {
      return null;
    }
  }

  Future<bool> setChannel(int frequency, {required bool persistent}) async {
    if (_isExecuting) {
      throw const WiFiCommandException(WiFiCommandErrorType.generic);
    }

    final backend = _activeBackend;
    if (backend == null) {
      throw const WiFiCommandException(WiFiCommandErrorType.generic);
    }

    _isExecuting = true;
    try {
      final result = await backend.setChannel(
        frequency,
        persistent: persistent,
      );
      _validateCommandResult(
        result,
        backend: backend.backend,
        command: _WiFiCommand.setChannel,
        frequency: frequency,
      );
      return true;
    } finally {
      _isExecuting = false;
    }
  }

  Future<ChannelList> _loadChannelsWithShizuku() async {
    final status = await _shizukuBackend.getStatus();
    _lastShizukuStatus = status;
    if (!status.running) {
      throw WiFiCommandException(
        status.installed
            ? WiFiCommandErrorType.shizukuNotRunning
            : WiFiCommandErrorType.shizukuNotInstalled,
      );
    }
    return _loadChannelsWith(_shizukuBackend);
  }

  Future<ChannelList> _loadChannelsWith(WiFiCommandBackend backend) async {
    final sources = <Future<ChannelList> Function()>[
      () => _loadFromIw(backend),
      () => _loadFromCmdWifi(backend),
      () => _loadFromSoftApCapability(backend),
    ];

    WiFiCommandException? lastFailure;
    for (final source in sources) {
      try {
        return await source();
      } on WiFiCommandException catch (error) {
        if (!_canTryOtherSources(error)) rethrow;
        lastFailure = error;
      }
    }

    throw WiFiCommandException(
      WiFiCommandErrorType.channelListUnavailable,
      params: {'reason': lastFailure?.type.name ?? 'unknown'},
    );
  }

  bool _canTryOtherSources(WiFiCommandException error) {
    return switch (error.type) {
      WiFiCommandErrorType.noPrivilegedAccess ||
      WiFiCommandErrorType.rootUnavailable ||
      WiFiCommandErrorType.shizukuNotInstalled ||
      WiFiCommandErrorType.shizukuNotRunning ||
      WiFiCommandErrorType.shizukuPermissionDenied ||
      WiFiCommandErrorType.shizukuUnsupported ||
      WiFiCommandErrorType.shizukuServiceUnavailable => false,
      _ => true,
    };
  }

  Future<ChannelList> _loadFromIw(WiFiCommandBackend backend) async {
    final result = await backend.getIwList();
    _validateCommandResult(
      result,
      backend: backend.backend,
      command: _WiFiCommand.iwList,
    );
    return _buildChannelList(
      backend,
      ChannelListSource.iw,
      IwParser.parse(result.stdout),
    );
  }

  Future<ChannelList> _loadFromCmdWifi(WiFiCommandBackend backend) async {
    final result = await backend.getAllowedChannels();
    _validateCommandResult(
      result,
      backend: backend.backend,
      command: _WiFiCommand.allowedChannels,
    );
    return _buildChannelList(
      backend,
      ChannelListSource.cmdWifi,
      AllowedChannelParser.parse(result.stdout),
    );
  }

  Future<ChannelList> _loadFromSoftApCapability(
    WiFiCommandBackend backend,
  ) async {
    final result = await backend.getSoftApCapability();
    _validateCommandResult(
      result,
      backend: backend.backend,
      command: _WiFiCommand.softApCapability,
    );
    return _buildChannelList(
      backend,
      ChannelListSource.softApCapability,
      SoftApCapabilityParser.parse(result.stdout),
    );
  }

  ChannelList _buildChannelList(
    WiFiCommandBackend backend,
    ChannelListSource source,
    Map<int, List<WiFiChannel>> channels,
  ) {
    if (channels.values.every((channelsOfBand) => channelsOfBand.isEmpty)) {
      throw const WiFiCommandException(WiFiCommandErrorType.badResult);
    }

    _activeBackend = backend;
    return ChannelList(source, channels);
  }

  void _validateCommandResult(
    CommandResult result, {
    required AccessBackend backend,
    required _WiFiCommand command,
    int? frequency,
  }) {
    if (result.timedOut) {
      throw const WiFiCommandException(WiFiCommandErrorType.timeout);
    }

    final output = result.combinedOutput.toLowerCase();

    if (output.contains('does not have access to')) {
      throw const WiFiCommandException(WiFiCommandErrorType.commandNeedsRoot);
    }

    // Success is decided by the exit code only: "dumpsys" writes a harmless broken pipe notice
    // to stderr whenever the pipeline stops reading early.
    if (result.exitCode == 0) {
      return;
    }

    if (output.contains('softap configuration') ||
        output.contains('requires android 11')) {
      throw WiFiCommandException(
        WiFiCommandErrorType.channelNotStored,
        params: {'reason': _firstLine(result.combinedOutput)},
      );
    }

    if (command == _WiFiCommand.setChannel && _isUnsupportedCommand(output)) {
      throw const WiFiCommandException(WiFiCommandErrorType.cmdWifiNotFound);
    }

    if (backend == AccessBackend.root && _isRootUnavailable(output)) {
      throw const WiFiCommandException(WiFiCommandErrorType.rootUnavailable);
    }
    if (output.contains('permission denied') ||
        output.contains('not permitted') ||
        output.contains('access denied') ||
        output.contains('not allowed')) {
      throw const WiFiCommandException(WiFiCommandErrorType.permissionDenied);
    }
    if (output.contains('invalid')) {
      throw WiFiCommandException(
        WiFiCommandErrorType.invalidFrequency,
        params: {'frequency': frequency ?? 0},
      );
    }
    if (output.contains('not found') || output.contains('no such file')) {
      throw WiFiCommandException(
        command == _WiFiCommand.iwList
            ? WiFiCommandErrorType.iwNotFound
            : WiFiCommandErrorType.cmdWifiNotFound,
      );
    }
    if (result.combinedOutput.isEmpty) {
      throw const WiFiCommandException(WiFiCommandErrorType.noResult);
    }
    throw const WiFiCommandException(WiFiCommandErrorType.generic);
  }

  String _firstLine(String text) {
    final trimmed = text.trim();
    final newline = trimmed.indexOf('\n');
    return newline == -1 ? trimmed : trimmed.substring(0, newline);
  }

  bool _isUnsupportedCommand(String output) {
    return output.contains('unknown command') ||
        output.contains('not supported') ||
        output.contains('unsupported');
  }

  bool _isRootUnavailable(String output) {
    return output.contains('su: not found') ||
        output.contains('su: inaccessible') ||
        output.contains('cannot run program "su"') ||
        output.contains('no such file or directory');
  }
}

enum _WiFiCommand { iwList, allowedChannels, softApCapability, setChannel }
