import 'access_method.dart';
import 'command_result.dart';

abstract interface class WiFiCommandBackend {
  AccessBackend get backend;

  Future<CommandResult> getSoftApCapability();

  Future<CommandResult> getSoftApState();

  Future<CommandResult> setChannel(int frequency, {required bool persistent});

  Future<CommandResult> resetChannel();
}

/// Root mode reads the channel list with `iw`, Shizuku mode asks the system.
abstract interface class RootBackend implements WiFiCommandBackend {
  Future<CommandResult> getIwList();
}
