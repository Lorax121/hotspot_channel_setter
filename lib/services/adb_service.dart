import 'package:process_run/shell.dart';

class AdbService {
  final _shell = Shell();

  Future<String> getIwList() async {
    try {
      final result = await _shell.run('su -c iw list');
      
      if (result.first.exitCode == 0) {
        return result.first.stdout;
      } else {
        throw Exception('Failed to get iw list. Exit code: ${result.first.exitCode}\nError: ${result.first.stderr}');
      }
    } catch (e) {
      throw Exception('Error executing getIwList: $e. Is the device rooted?');
    }
  }

  Future<void> setChannel(int frequency) async {
    try {
      final result = await _shell.run('su -c cmd wifi force-softap-channel enabled $frequency');
      
      if (result.first.exitCode != 0) {
        throw Exception('Failed to set channel. Exit code: ${result.first.exitCode}\nError: ${result.first.stderr}');
      }
    } catch (e) {
      throw Exception('Error executing setChannel: $e');
    }
  }
}

