import 'access_method.dart';
import 'command_result.dart';

abstract interface class WiFiCommandBackend {
  AccessBackend get backend;

  Future<CommandResult> getIwList();

  Future<CommandResult> getAllowedChannels();

  Future<CommandResult> getSoftApCapability();

  Future<CommandResult> getSoftApState();

  Future<CommandResult> setChannel(int frequency, {required bool persistent});

  Future<CommandResult> resetChannel();
}
