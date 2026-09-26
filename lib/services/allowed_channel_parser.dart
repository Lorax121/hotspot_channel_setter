import '../models/wifi_channel.dart';

class AllowedChannelParser {
  static const String _softApHeader = 'Allowed ch in SAP mode:';
  static const String _sectionMarker = 'Allowed ch in';

  static Map<int, List<WiFiChannel>> parse(String commandOutput) {
    final Map<int, List<WiFiChannel>> bands = {1: [], 2: []};
    final softApSection = _extractSection(commandOutput, _softApHeader);
    final seenFrequencies = <int>{};

    for (final match in RegExp(r'\d+').allMatches(softApSection)) {
      final frequency = int.parse(match.group(0)!);
      if (!seenFrequencies.add(frequency)) continue;

      final band = _bandOf(frequency);
      final channelNumber = _channelNumberOf(frequency);
      if (band == null || channelNumber == null) continue;

      bands[band]!.add(
        WiFiChannel(frequency: frequency, channelNumber: channelNumber),
      );
    }

    for (final channels in bands.values) {
      channels.sort((a, b) => a.frequency.compareTo(b.frequency));
    }
    return bands;
  }

  static String _extractSection(String output, String header) {
    final headerIndex = output.indexOf(header);
    if (headerIndex == -1) return '';

    final sectionStart = headerIndex + header.length;
    final nextSection = output.indexOf(_sectionMarker, sectionStart);
    return nextSection == -1
        ? output.substring(sectionStart)
        : output.substring(sectionStart, nextSection);
  }

  static int? _bandOf(int frequency) {
    if (frequency >= 2412 && frequency <= 2484) return 1;
    if (frequency >= 5170 && frequency <= 5895) return 2;
    return null;
  }

  static int? _channelNumberOf(int frequency) {
    if (frequency == 2484) return 14;
    if (frequency >= 2412 && frequency <= 2472) {
      return (frequency - 2412) % 5 == 0 ? (frequency - 2412) ~/ 5 + 1 : null;
    }
    if (frequency >= 5170 && frequency <= 5895) {
      return frequency % 5 == 0 ? (frequency - 5000) ~/ 5 : null;
    }
    return null;
  }
}
