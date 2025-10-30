import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyLastBand = 'last_selected_band';
  static const String _keyChannelForBand2_4 = 'channel_for_band_2_4';
  static const String _keyChannelForBand5 = 'channel_for_band_5';

  String _getKeyForBand(int band) {
    return band == 1 ? _keyChannelForBand2_4 : _keyChannelForBand5;
  }

  Future<void> saveChannelForBand(int band, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getKeyForBand(band), frequency);
  }

  Future<int?> getChannelForBand(int band) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_getKeyForBand(band));
  }

  Future<void> saveLastBand(int band) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastBand, band);
  }

  Future<int> getLastBand() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastBand) ?? 1; 
  }
}