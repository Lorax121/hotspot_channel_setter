import '../models/wifi_channel.dart';

class SoftApCapabilityParser {
  static const String _lineMarker = 'mCurrentSoftApCapability';
  static const String _channels24Marker = 'SupportedChannelListIn24g[';
  static const String _channels5Marker = 'SupportedChannelListIn5g[';

  static String? countryCode(String dumpOutput) {
    final match = RegExp(
      r'mCountryCodeFromDriver\s*([A-Z]{2})',
    ).firstMatch(dumpOutput);
    return match?.group(1);
  }

  static Map<int, List<WiFiChannel>> parse(String dumpOutput) {
    if (!dumpOutput.contains(_lineMarker)) {
      return {1: [], 2: []};
    }

    return {
      1: _channels(dumpOutput, _channels24Marker, _frequencyOf24g),
      2: _channels(dumpOutput, _channels5Marker, _frequencyOf5g),
    };
  }

  static List<WiFiChannel> _channels(
    String dumpOutput,
    String marker,
    int? Function(int) frequencyOf,
  ) {
    final section = _section(dumpOutput, marker);
    if (section == null) return [];

    final channels = <WiFiChannel>[];
    for (final match in RegExp(r'\d+').allMatches(section)) {
      final channelNumber = int.parse(match.group(0)!);
      final frequency = frequencyOf(channelNumber);
      if (frequency == null) continue;

      channels.add(
        WiFiChannel(frequency: frequency, channelNumber: channelNumber),
      );
    }
    channels.sort((a, b) => a.frequency.compareTo(b.frequency));
    return channels;
  }

  static String? _section(String dumpOutput, String marker) {
    final start = dumpOutput.indexOf(marker);
    if (start == -1) return null;

    final end = dumpOutput.indexOf(']', start);
    if (end == -1) return null;

    return dumpOutput.substring(start + marker.length, end);
  }

  static int? _frequencyOf24g(int channelNumber) {
    if (channelNumber == 14) return 2484;
    if (channelNumber >= 1 && channelNumber <= 13) {
      return 2407 + 5 * channelNumber;
    }
    return null;
  }

  static int? _frequencyOf5g(int channelNumber) {
    if (channelNumber < 32 || channelNumber > 177) return null;

    final frequency = 5000 + 5 * channelNumber;
    return frequency >= 5150 && frequency <= 5895 ? frequency : null;
  }
}
