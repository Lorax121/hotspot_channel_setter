import '../models/wifi_channel.dart';

enum ChannelListSource { iw, cmdWifi, softApCapability }

class ChannelList {
  const ChannelList(this.source, this.channels);

  final ChannelListSource source;
  final Map<int, List<WiFiChannel>> channels;
}
