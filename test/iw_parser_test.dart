import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_channel_setter/services/iw_parser.dart';

void main() {
  test('parses supported bands and channel restrictions', () {
    const output = '''
Wiphy phy0
\tBand 1:
\t\tFrequencies:
\t\t\t* 2412 MHz [1] (20.0 dBm)
\t\t\t* 2462 MHz [11] (disabled)
\tBand 2:
\t\tFrequencies:
\t\t\t* 5180 MHz [36] (23.0 dBm)
\t\t\t* 5260 MHz [52] (20.0 dBm) (radar detection)
''';

    final channels = IwParser.parse(output);

    expect(channels[1], hasLength(2));
    expect(channels[1]![0].channelNumber, 1);
    expect(channels[1]![0].isAllowedByDefault, isTrue);
    expect(channels[1]![1].isDisabled, isTrue);
    expect(channels[2], hasLength(2));
    expect(channels[2]![0].frequency, 5180);
    expect(channels[2]![1].hasRadarDetection, isTrue);
    expect(channels[2]![1].isAllowedByDefault, isFalse);
  });
}
