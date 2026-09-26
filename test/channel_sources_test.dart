import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_channel_setter/services/allowed_channel_parser.dart';
import 'package:wifi_channel_setter/services/soft_ap_capability_parser.dart';
import 'package:wifi_channel_setter/services/soft_ap_state_parser.dart';

const dumpsysCapabilityLine =
    'mCurrentSoftApCapability: SupportedFeatures=255 '
    'MaximumSupportedClientNumber=16 '
    'SupportedChannelListIn24g[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] '
    'SupportedChannelListIn5g[36, 40, 44, 48] SupportedChannelListIn6g[] '
    'SupportedChannelListIn60g[] mCountryCodeFromDriverGE';

void main() {
  test('parses only the SoftAP block of the system channel query', () {
    const output = '''
Allowed ch in STA mode:
2412 2437 5180 5260 5500
Allowed ch in SAP mode:
2412 2437 5180 5260
Allowed ch in WiFi-Direct GO mode:
2412 5180
''';

    final channels = AllowedChannelParser.parse(output);

    expect(channels[1], hasLength(2));
    expect(channels[2], hasLength(2));
    expect(channels[1]!.first.channelNumber, 1);
    expect(channels[2]!.last.frequency, 5260);
    expect(channels[2]!.last.channelNumber, 52);
    expect(channels[2]!.first.isAllowedByDefault, isTrue);
  });

  test('ignores frequencies outside the 2.4 and 5 GHz bands', () {
    const output = '''
Allowed ch in SAP mode:
2412 5955 6115 2484 5180
''';

    final channels = AllowedChannelParser.parse(output);

    expect(channels[1]!.map((channel) => channel.frequency), [2412, 2484]);
    expect(channels[1]!.last.channelNumber, 14);
    expect(channels[2]!.map((channel) => channel.frequency), [5180]);
  });

  test('returns empty bands when the SoftAP block is missing', () {
    const output = 'Unknown command: get-allowed-channel';

    final channels = AllowedChannelParser.parse(output);

    expect(channels[1], isEmpty);
    expect(channels[2], isEmpty);
  });

  test('deduplicates repeated frequencies', () {
    const output = '''
Allowed ch in SAP mode:
5180 5180 5200
''';

    final channels = AllowedChannelParser.parse(output);

    expect(channels[2], hasLength(2));
  });

  test('parses the SoftAP capability reported by the device dump', () {
    final channels = SoftApCapabilityParser.parse(dumpsysCapabilityLine);

    expect(channels[1], hasLength(13));
    expect(channels[1]!.first.channelNumber, 1);
    expect(channels[1]!.first.frequency, 2412);
    expect(channels[1]!.last.frequency, 2472);
    expect(channels[2]!.map((channel) => channel.frequency), [
      5180,
      5200,
      5220,
      5240,
    ]);
    expect(channels[2]!.first.channelNumber, 36);
    expect(channels[2]!.first.isAllowedByDefault, isTrue);
    expect(SoftApCapabilityParser.countryCode(dumpsysCapabilityLine), 'GE');
  });

  test('maps channel numbers of both bands to frequencies', () {
    const line =
        'mCurrentSoftApCapability: SupportedChannelListIn24g[6, 14] '
        'SupportedChannelListIn5g[100, 165] SupportedChannelListIn6g[1, 5] '
        'mCountryCodeFromDriverUS';

    final channels = SoftApCapabilityParser.parse(line);

    expect(channels[1]!.map((channel) => channel.frequency), [2437, 2484]);
    expect(channels[1]!.map((channel) => channel.channelNumber), [6, 14]);
    expect(channels[2]!.map((channel) => channel.frequency), [5500, 5825]);
    expect(channels[2]!.map((channel) => channel.channelNumber), [100, 165]);
  });

  test('returns empty bands when the capability line is absent', () {
    final channels = SoftApCapabilityParser.parse('grep: no match');

    expect(channels[1], isEmpty);
    expect(channels[2], isEmpty);
    expect(SoftApCapabilityParser.countryCode('grep: no match'), isNull);
  });

  test('parses the channel stored in the hotspot settings', () {
    const output = 'Channels = {2=36}';

    final state = SoftApStateParser.parse(output);

    expect(state?.channelNumber, 36);
    expect(state?.frequency, 5180);
  });

  test('reports an automatic channel when the settings do not pin one', () {
    const output = 'Channels = {1=0}';

    final state = SoftApStateParser.parse(output);

    expect(state?.channelNumber, isNull);
    expect(state?.frequency, isNull);
  });

  test('picks the pinned band from a dual band configuration', () {
    const output = 'Channels = {1=0,2=44}';

    final state = SoftApStateParser.parse(output);

    expect(state?.channelNumber, 44);
    expect(state?.frequency, 5220);
  });

  test('returns nothing when the state lines are missing', () {
    expect(SoftApStateParser.parse('grep: no match'), isNull);
  });
}
