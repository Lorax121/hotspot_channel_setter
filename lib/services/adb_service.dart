import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:process_run/shell.dart';
import 'adb_exception.dart'; 

class AdbService {
  final Shell _shell = Shell(verbose: kDebugMode);
  bool _isExecuting = false;

  Future<String> getIwList() async {
    if (_isExecuting) throw AdbException(AdbErrorType.generic); 

    _isExecuting = true;
    debugPrint("[AdbService] Trying to get 'iw list'...");
    
    try {
      final resultList = await _shell.run('su -c "iw list"').timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw AdbException(AdbErrorType.timeout),
      );
      
      if (resultList.isEmpty) throw AdbException(AdbErrorType.noResult);

      final result = resultList.first;

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.isEmpty || output.length < 100) throw AdbException(AdbErrorType.badResult);
        
        debugPrint("[AdbService] 'iw list' executed successfully.");
        return output;
      } else {
        final stderr = result.stderr.toString().toLowerCase();
        if (stderr.contains('not found') || stderr.contains('no such file')) throw AdbException(AdbErrorType.iwNotFound);
        if (stderr.contains('permission denied') || stderr.contains('not permitted')) throw AdbException(AdbErrorType.permissionDenied);
        
        throw AdbException(AdbErrorType.generic);
      }
    } on TimeoutException {
      throw AdbException(AdbErrorType.timeout);
    } catch (e) {
      debugPrint("[AdbService] Exception during 'iw list': $e");
      if (e is AdbException) rethrow; 
      throw AdbException(AdbErrorType.generic); 
    } finally {
      _isExecuting = false;
    }
  }

  Future<bool> setChannel(int frequency) async {
    if (_isExecuting) throw AdbException(AdbErrorType.generic);

    _isExecuting = true;
    final command = 'su -c "cmd wifi force-softap-channel enabled $frequency"';
    debugPrint("[AdbService] Trying to execute command: $command");
    
    try {
      final resultList = await _shell.run(command).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw AdbException(AdbErrorType.timeout),
      );

      if (resultList.isEmpty) throw AdbException(AdbErrorType.noResult);

      final result = resultList.first;

      if (result.exitCode == 0) {
        final stdout = result.stdout.toString().toLowerCase();
        if (stdout.contains('error') || stdout.contains('failed')) throw AdbException(AdbErrorType.generic);
        
        debugPrint("[AdbService] Set channel command executed successfully.");
        return true; 
      } else {
        final fullOutput = '${result.stdout} ${result.stderr}'.toLowerCase();
        
        if (fullOutput.contains('not found')) throw AdbException(AdbErrorType.cmdWifiNotFound);
        if (fullOutput.contains('permission denied') || fullOutput.contains('not permitted')) throw AdbException(AdbErrorType.permissionDenied);
        if (fullOutput.contains('invalid')) throw AdbException(AdbErrorType.invalidFrequency, params: {'frequency': frequency});
        
        throw AdbException(AdbErrorType.generic);
      }
    } on TimeoutException {
      throw AdbException(AdbErrorType.timeout);
    } catch (e) {
      debugPrint("[AdbService] Exception during setChannel: $e");
      if (e is AdbException) rethrow;
      throw AdbException(AdbErrorType.generic);
    } finally {
      _isExecuting = false;
    }
  }
}