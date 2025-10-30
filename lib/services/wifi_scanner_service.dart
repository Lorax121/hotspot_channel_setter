import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiScannerService {
  
  Future<bool> requestPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  Future<Map<int, int>> getChannelUsage() async {
    if (!await isLocationServiceEnabled()) {
      throw Exception("Пожалуйста, включите службу геолокации (GPS) в настройках телефона.");
    }
    
    final canScan = await WiFiScan.instance.canStartScan(askPermissions: false);
    if (canScan != CanStartScan.yes) {
      throw Exception("Пожалуйста, включите Wi-Fi для сканирования сетей.");
    }
    
    final result = await WiFiScan.instance.startScan();
    if (!result) {
      throw Exception("Не удалось запустить сканирование Wi-Fi.");
    }
    
    final networks = await WiFiScan.instance.getScannedResults();
    
    final Map<int, int> channelCounts = {};
    for (final network in networks) {
      final channel = _frequencyToChannel(network.frequency);
      if (channel != null) {
        channelCounts.update(channel, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return channelCounts;
  }

  int? _frequencyToChannel(int freq) {
    if (freq >= 2412 && freq <= 2484) {
      if (freq == 2484) return 14;
      return (freq - 2412) ~/ 5 + 1;
    } else if (freq >= 5180 && freq <= 5825) {
      return (freq - 5180) ~/ 5 + 36;
    }
    return null;
  }
}