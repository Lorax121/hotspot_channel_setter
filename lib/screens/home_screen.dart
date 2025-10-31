import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_channel_setter/l10n/app_localizations.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/wifi_channel.dart';
import '../services/adb_exception.dart';
import '../services/adb_service.dart';
import '../services/iw_parser.dart';
import '../services/locale_provider.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdbService _adbService = AdbService();
  final SettingsService _settingsService = SettingsService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isApplying = false;

  int _selectedBand = 1;
  bool _showAllChannels = false;
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
    } on AdbException catch (e) {
      if (mounted) {
        final S = AppLocalizations.of(context)!;
        setState(() { _errorMessage = _getLocalizedError(e, S); });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = e.toString(); });
      }
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
      try {
        _selectedChannel = _visibleChannels.firstWhere((c) => c.frequency == savedFreq);
      } catch (e) {
        _selectedChannel = null;
      }
    }
  }

  void _onBandChanged(int? band) {
    if (band == null || band == _selectedBand) return;
    setState(() {
      _selectedBand = band;
      _settingsService.saveLastBand(band);
      _updateVisibleChannels();
    });
  }

  void _onShowAllChannelsChanged(bool value) {
    setState(() {
      _showAllChannels = value;
      _updateVisibleChannels();
    });
  }

  Future<void> _applyChannel() async {
    if (_selectedChannel == null || _isApplying) return;

    setState(() => _isApplying = true);
    final S = AppLocalizations.of(context)!;

    try {
      final success = await _adbService.setChannel(_selectedChannel!.frequency);
      
      if (success && mounted) {
        await _settingsService.saveChannelForBand(_selectedBand, _selectedChannel!.frequency);
        await _settingsService.saveLastBand(_selectedBand);
        await _loadSettings(); 
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.applySuccessSnackbar(_selectedChannel!.channelNumber, _selectedChannel!.frequency)),
          backgroundColor: Colors.green.shade700,
        ));
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.applyFailedButNoErrorSnackbar),
          backgroundColor: Colors.orange.shade800,
        ));
      }
    } on AdbException catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_getLocalizedError(e, S)),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.errorSnackbar(e.toString())),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if(mounted) setState(() => _isApplying = false);
    }
  }
  
  void _selectSavedChannel(int frequency) {
    try {
      final channelToSelect = _visibleChannels.firstWhere((c) => c.frequency == frequency);
      setState(() => _selectedChannel = channelToSelect);
    } catch (e) {
      final S = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.channelNotFoundSnackbar(frequency)),
      ));
    }
  }

  String _getLocalizedError(AdbException e, AppLocalizations S) {
    switch (e.type) {
      case AdbErrorType.timeout: return S.adbError_timeout;
      case AdbErrorType.permissionDenied: return S.adbError_permissionDenied;
      case AdbErrorType.iwNotFound: return S.adbError_iwNotFound;
      case AdbErrorType.cmdWifiNotFound: return S.adbError_cmdWifiNotFound;
      case AdbErrorType.invalidFrequency:
        final freq = e.params?['frequency'] ?? 0;
        return S.adbError_invalidFrequency(freq);
      case AdbErrorType.noResult: return S.adbError_noResult;
      case AdbErrorType.badResult: return S.adbError_badResult;
      case AdbErrorType.generic:
      default: return S.adbError_generic;
    }
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
          onSelectionChanged: (Set<int> newSelection) => _onBandChanged(newSelection.first),
        ),
          const SizedBox(height: 20),

          DropdownButtonFormField2<WiFiChannel>(
            value: _selectedChannel,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: const OutlineInputBorder(),
              labelText: S.availableChannelsLabel,
            ),
            hint: Text(
              S.selectChannelHint,
              style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
            ),
            items: _visibleChannels.map((channel) {
              return DropdownMenuItem<WiFiChannel>(
                value: channel,
                child: Text(S.channelDropdownItem(channel.channelNumber, channel.frequency)),
              );
            }).toList(),
            onChanged: (channel) => setState(() => _selectedChannel = channel),
            
            buttonStyleData: const ButtonStyleData(
              height: 60,
              padding: EdgeInsets.only(left: 0, right: 10),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: MediaQuery.of(context).size.height * 0.4, 
              offset: const Offset(0, -5), 
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 10),
          
          _buildSavedChannelBadges(S),

          SwitchListTile(
            title: Text(S.showAllChannelsTitle),
            subtitle: Text(S.showAllChannelsSubtitle),
            value: _showAllChannels,
            onChanged: _onShowAllChannelsChanged,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedChannel == null || _isApplying ? null : _applyChannel,
            icon: _isApplying
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Icon(Icons.check_circle_outline),
            label: Text(_isApplying ? S.applyingButton : S.applyButton),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedChannelBadges(AppLocalizations S) {
    if (_savedChannelFreqBand1 == null && _savedChannelFreqBand2 == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.quickSelectLabel, 
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              if (_savedChannelFreqBand1 != null)
                ActionChip(
                  avatar: const Icon(Icons.network_wifi_3_bar, size: 18),
                  label: Text(S.quickSelectChipLabel(S.band2_4GHz, _savedChannelFreqBand1!)),
                  onPressed: () => _selectSavedChannel(_savedChannelFreqBand1!),
                ),
              if (_savedChannelFreqBand2 != null)
                ActionChip(
                  avatar: const Icon(Icons.network_wifi, size: 18),
                  label: Text(S.quickSelectChipLabel(S.band5GHz, _savedChannelFreqBand2!)),
                  onPressed: () => _selectSavedChannel(_savedChannelFreqBand2!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}