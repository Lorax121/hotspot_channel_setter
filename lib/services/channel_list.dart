import '../models/wifi_channel.dart';

enum ChannelListSource { iw, system, softApCapability, standard }

class ChannelList {
  const ChannelList(this.source, this.channels);

  final ChannelListSource source;
  final Map<int, List<WiFiChannel>> channels;
}
