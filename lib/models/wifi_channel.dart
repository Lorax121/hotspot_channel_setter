class WiFiChannel {
  final int frequency;
  final int channelNumber;
  final bool isDisabled;
  final bool hasRadarDetection;

  WiFiChannel({
    required this.frequency,
    required this.channelNumber,
    this.isDisabled = false,
    this.hasRadarDetection = false,
  });

  bool get isAllowedByDefault => !isDisabled && !hasRadarDetection;

  @override
  String toString() {
    return 'Channel $channelNumber ($frequency MHz)';
  }
}
