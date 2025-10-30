import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_channel_setter/l10n/app_localizations.dart';

import '../models/wifi_channel.dart';
import '../services/adb_service.dart';
import '../services/iw_parser.dart';
import '../services/locale_provider.dart';
import '../services/settings_service.dart';
import '../services/wifi_scanner_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdbService _adbService = AdbService();
  final SettingsService _settingsService = SettingsService();
  final WifiScannerService _wifiScannerService = WifiScannerService();

  bool _isLoading = true;
  String? _errorMessage;
  int _selectedBand = 1;
  bool _showAllChannels = false;
  
  bool _analyzeChannels = false;
  bool _isScanning = false;
  Map<int, int> _channelUsage = {};

  Map<int, List<WiFiChannel>> _allChannels = {};
  List<WiFiChannel> _visibleChannels = [];
  WiFiChannel? _selectedChannel;

  int? _savedChannelFreqBand1;
  int? _savedChannelFreqBand2;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    await _loadSettings();
    await _fetchChannels();
    if(mounted) setState(() { _isLoading = false; });
  }

  Future<void> _loadSettings() async {
    _selectedBand = await _settingsService.getLastBand();
    _savedChannelFreqBand1 = await _settingsService.getChannelForBand(1);
    _savedChannelFreqBand2 = await _settingsService.getChannelForBand(2);
  }

  Future<void> _fetchChannels() async {
    try {
      final iwOutput = await _adbService.getIwList();
      _allChannels = IwParser.parse(iwOutput);
      _updateVisibleChannels();
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); });
    }
  }

  void _updateVisibleChannels() {
    List<WiFiChannel> channelsForBand = _allChannels[_selectedBand] ?? [];
    _visibleChannels = _showAllChannels
        ? channelsForBand
        : channelsForBand.where((c) => c.isAllowedByDefault).toList();

    _selectedChannel = null;
    int? savedFreq = _selectedBand == 1 ? _savedChannelFreqBand1 : _savedChannelFreqBand2;

    if (savedFreq != null) {
      final matchingChannels = _visibleChannels.where((c) => c.frequency == savedFreq);
      if (matchingChannels.isNotEmpty) {
        _selectedChannel = matchingChannels.first;
      }
    }
  }

  Future<void> _onAnalyzeChannelsChanged(bool value) async {
    setState(() => _analyzeChannels = value);

    if (_analyzeChannels) {
      final hasPermissions = await _wifiScannerService.requestPermissions();
      if (!hasPermissions) {
        if (mounted) setState(() => _analyzeChannels = false);
        _showPermissionDeniedDialog();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500)); 

      setState(() => _isScanning = true);
      try {
        final usage = await _wifiScannerService.getChannelUsage();
        if(mounted) setState(() => _channelUsage = usage);
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.orange,
          ));
          setState(() => _analyzeChannels = false);
        }
      } finally {
        if(mounted) setState(() => _isScanning = false);
      }
    } else {
      if(mounted) setState(() => _channelUsage.clear());
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разрешение отклонено'),
        content: const Text(
          'Для анализа загруженности каналов приложению нужен доступ к геолокации. '
          'Это стандартное требование Android для сканирования Wi-Fi сетей.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

void _onBandChanged(int? band) {
  if (band == null) return;
  setState(() {
    _selectedBand = band;
    _updateVisibleChannels();
    
    if (_analyzeChannels) {
      _onAnalyzeChannelsChanged(true);
    }
  });
}

  void _onShowAllChannelsChanged(bool value) {
    setState(() {
      _showAllChannels = value;
      _updateVisibleChannels();
    });
  }

  Future<void> _applyChannel() async {
    if (_selectedChannel == null) return;
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            onSelected: (Locale locale) => Provider.of<LocaleProvider>(context, listen: false).setLocale(locale),
            icon: const Icon(Icons.language),
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('English')),
              const PopupMenuItem(value: Locale('ru'), child: Text('Русский')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(S)
              : _buildMainContent(S),
    );
  }

  Widget _buildErrorView(AppLocalizations S) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(S.errorOccurred, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                onPressed: _initializeScreen,
                icon: const Icon(Icons.refresh),
                label: Text(S.tryAgain),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainContent(AppLocalizations S) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 1, label: Text(S.band2_4GHz), icon: const Icon(Icons.network_wifi_3_bar)),
            ButtonSegment(value: 2, label: Text(S.band5GHz), icon: const Icon(Icons.network_wifi)),
          ],
          selected: {_selectedBand},
          onSelectionChanged: (Set<int> newSelection) {
            _onBandChanged(newSelection.first);
          },
        ),
          const SizedBox(height: 20),
          DropdownButtonFormField<WiFiChannel>(
            value: _selectedChannel,
            hint: Text(S.selectChannelHint),
            isExpanded: true,
            menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
            items: _visibleChannels.map((channel) {
              final usageCount = _channelUsage[channel.channelNumber];
              return DropdownMenuItem(
                value: channel,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.channelDropdownItem(channel.channelNumber, channel.frequency),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_analyzeChannels && !_isScanning)
                      Row(
                        children: [
                          if (usageCount != null && usageCount > 0) ...[
                            Icon(Icons.wifi_tethering, color: Colors.orange.shade600, size: 20),
                            const SizedBox(width: 4),
                            Text('$usageCount', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                          ] else
                            const Icon(Icons.wifi_tethering_off, color: Colors.green, size: 20),
                        ],
                      ),
                    if (_isScanning) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (channel) => setState(() => _selectedChannel = channel),
            decoration: InputDecoration(
              labelText: S.availableChannelsLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          
          SwitchListTile(
            title: const Text('Анализировать загруженность'),
            subtitle: _isScanning
                ? const LinearProgressIndicator()
                : const Text('Показать, какие каналы заняты'),
            value: _analyzeChannels,
            onChanged: _isScanning ? null : _onAnalyzeChannelsChanged,
          ),

          SwitchListTile(
            title: Text(S.showAllChannelsTitle),
            subtitle: Text(S.showAllChannelsSubtitle),
            value: _showAllChannels,
            onChanged: _onShowAllChannelsChanged,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedChannel == null ? null : _applyChannel,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(S.applyButton),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}