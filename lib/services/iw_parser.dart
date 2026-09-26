import '../models/wifi_channel.dart';

class IwParser {
  static Map<int, List<WiFiChannel>> parse(String iwOutput) {
    final Map<int, List<WiFiChannel>> bands = {1: [], 2: []};

    final bandRegex = RegExp(r'Band (\d):');
    final matches = bandRegex.allMatches(iwOutput);

    for (var i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);
      final bandNumber = int.parse(match.group(1)!);

      final startIndex = match.end;
      final endIndex = (i + 1 < matches.length)
          ? matches.elementAt(i + 1).start
          : iwOutput.length;

      final bandContent = iwOutput.substring(startIndex, endIndex);

      final freqIndex = bandContent.indexOf('Frequencies:');
      if (freqIndex == -1) continue;

      final frequenciesBlock = bandContent.substring(freqIndex);

      final lineRegex = RegExp(r'\* (\d+) MHz \[(\d+)\]');

      for (final line in frequenciesBlock.split('\n')) {
        final lineMatch = lineRegex.firstMatch(line);

        if (lineMatch != null) {
          final frequency = int.parse(lineMatch.group(1)!);
          final channelNumber = int.parse(lineMatch.group(2)!);

          final isDisabled = line.contains('(disabled)');
          final hasRadarDetection = line.contains('(radar detection)');

          final channel = WiFiChannel(
            frequency: frequency,
            channelNumber: channelNumber,
            isDisabled: isDisabled,
            hasRadarDetection: hasRadarDetection,
          );

          if (bands.containsKey(bandNumber)) {
            bands[bandNumber]!.add(channel);
          }
        }
      }
    }
    return bands;
  }
}
