class SoftApState {
  const SoftApState({required this.channelNumber, required this.frequency});

  /// Channel from the stored hotspot configuration, null when the device picks it automatically.
  final int? channelNumber;
  final int? frequency;
}

class SoftApStateParser {
  static const int _band24Ghz = 1;
  static const int _band5Ghz = 2;

  static SoftApState? parse(String commandOutput) {
    final match = RegExp(r'Channels = \{([^}]*)\}').firstMatch(commandOutput);
    if (match == null) return null;

    for (final entry in match.group(1)!.split(',')) {
      final parts = entry.split('=');
      if (parts.length != 2) continue;

      final band = int.tryParse(parts[0].trim());
      final channel = int.tryParse(parts[1].trim());
      if (band == null || channel == null || channel == 0) continue;

      return SoftApState(
        channelNumber: channel,
        frequency: _frequencyOf(band, channel),
      );
    }

    // The configuration exists, but the device picks the channel itself.
    return const SoftApState(channelNumber: null, frequency: null);
  }

  static int? _frequencyOf(int band, int channel) {
    return switch (band) {
      _band24Ghz => channel == 14 ? 2484 : 2407 + 5 * channel,
      _band5Ghz => 5000 + 5 * channel,
      _ => null,
    };
  }
}
