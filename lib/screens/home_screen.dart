import 'package:flutter/material.dart';
import 'package:wifi_channel_setter/l10n/app_localizations.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/wifi_channel.dart';
import '../services/access_method.dart';
import '../services/channel_list.dart';
import '../services/settings_service.dart';
import '../services/soft_ap_state_parser.dart';
import '../services/wifi_command_exception.dart';
import '../services/wifi_command_service.dart';
import 'settings_screen.dart';

enum _ErrorAction { connect, requestRoot, retry }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final WiFiCommandService _commandService = WiFiCommandService();
  final SettingsService _settingsService = SettingsService();

  bool _isLoading = true;
  String? _errorMessage;
  WiFiCommandErrorType? _errorType;
  bool _isApplying = false;

  int _selectedBand = 1;
  bool _showAllChannels = false;
  Map<int, List<WiFiChannel>> _allChannels = {};
  List<WiFiChannel> _visibleChannels = [];
  WiFiChannel? _selectedChannel;
  int? _savedChannelFreqBand1;
  int? _savedChannelFreqBand2;
  AccessMode _accessMode = AccessMode.root;
  AccessBackend? _activeBackend;
  ChannelListSource? _channelListSource;
  SoftApState? _softApState;
  bool _persistChannel = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentChannel();
    }
  }

  /// Re-reads the channel stored in the hotspot settings.
  Future<void> _refreshCurrentChannel() async {
    final softApState = await _commandService.getSoftApState();
    if (!mounted) return;

    setState(() => _softApState = softApState);
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadSettings();
    await _fetchChannels();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    _selectedBand = await _settingsService.getLastBand();
    _savedChannelFreqBand1 = await _settingsService.getChannelForBand(1);
    _savedChannelFreqBand2 = await _settingsService.getChannelForBand(2);
    _accessMode = await _settingsService.getAccessMode();
    _persistChannel = await _settingsService.getPersistChannel();
  }

  Future<void> _fetchChannels() async {
    try {
      final channelList = await _commandService.loadChannels(_accessMode);
      _allChannels = channelList.channels;
      _channelListSource = channelList.source;
      _activeBackend = _commandService.activeBackend;
      _softApState = await _commandService.getSoftApState();
      _updateVisibleChannels();
    } on WiFiCommandException catch (e) {
      if (mounted) {
        final S = AppLocalizations.of(context)!;
        setState(() {
          _errorType = e.type;
          _errorMessage = _getLocalizedError(e, S);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorType = null;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _onAccessModeChanged(AccessMode mode) async {
    if (mode == _accessMode) return;
    await _settingsService.saveAccessMode(mode);
    if (!mounted) return;
    setState(() {
      _accessMode = mode;
      _activeBackend = null;
    });

    if (mode == AccessMode.shizuku) {
      final S = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.shizukuPersistHint)));
    }

    await _initializeScreen();
  }

  Future<void> _connect() async {
    if (_accessMode == AccessMode.shizuku) {
      try {
        await _commandService.requestShizukuPermission();
      } on WiFiCommandException {
        // The reload below reports what is still missing.
      }
      if (!mounted) return;
    }

    await _initializeScreen();
  }

  bool get _canChooseApplyFormat =>
      _accessMode == AccessMode.root || _commandService.shizukuUid == 0;

  bool get _shouldPersistChannel =>
      _canChooseApplyFormat ? _persistChannel : true;

  Future<void> _togglePersistChannel(bool value) async {
    await _settingsService.savePersistChannel(value);
    if (!mounted) return;
    setState(() => _persistChannel = value);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          accessMode: _accessMode,
          onAccessModeChanged: _onAccessModeChanged,
          onResetChannel: _resetChannel,
        ),
      ),
    );
  }

  Future<void> _resetChannel() async {
    final S = AppLocalizations.of(context)!;

    try {
      await _commandService.resetChannel(_accessMode);
      await _initializeScreen();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.resetChannelDone),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on WiFiCommandException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedError(e, S)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _updateVisibleChannels() {
    List<WiFiChannel> channelsForBand = _allChannels[_selectedBand] ?? [];
    _visibleChannels = _showAllChannels
        ? channelsForBand
        : channelsForBand.where((c) => c.isAllowedByDefault).toList();

    _selectedChannel = null;

    int? savedFreq = _selectedBand == 1
        ? _savedChannelFreqBand1
        : _savedChannelFreqBand2;

    if (savedFreq != null) {
      try {
        _selectedChannel = _visibleChannels.firstWhere(
          (c) => c.frequency == savedFreq,
        );
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
      final persistent = _shouldPersistChannel;
      final success = await _commandService.setChannel(
        _selectedChannel!.frequency,
        persistent: persistent,
      );

      if (success && mounted) {
        await _settingsService.saveChannelForBand(
          _selectedBand,
          _selectedChannel!.frequency,
        );
        await _settingsService.saveLastBand(_selectedBand);
        await _loadSettings();
        _softApState = await _commandService.getSoftApState();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              persistent
                  ? S.applySuccessPersistent(
                      _selectedChannel!.channelNumber,
                      _selectedChannel!.frequency,
                    )
                  : S.applySuccessSession(
                      _selectedChannel!.channelNumber,
                      _selectedChannel!.frequency,
                    ),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.applyFailedButNoErrorSnackbar),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } on WiFiCommandException catch (e) {
      if (mounted) {
        final canSwitchFormat =
            e.type == WiFiCommandErrorType.channelNotStored &&
            _shouldPersistChannel &&
            _canChooseApplyFormat;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedError(e, S)),
            backgroundColor: Colors.red.shade700,
            action: canSwitchFormat
                ? SnackBarAction(
                    label: S.applyUntilRebootAction,
                    onPressed: () => _togglePersistChannel(false),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.errorSnackbar(e.toString())),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _selectSavedChannel(int frequency) {
    try {
      final channelToSelect = _visibleChannels.firstWhere(
        (c) => c.frequency == frequency,
      );
      setState(() => _selectedChannel = channelToSelect);
    } catch (e) {
      final S = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.channelNotFoundSnackbar(frequency))),
      );
    }
  }

  String _getLocalizedError(WiFiCommandException e, AppLocalizations S) {
    switch (e.type) {
      case WiFiCommandErrorType.timeout:
        return S.commandErrorTimeout;
      case WiFiCommandErrorType.permissionDenied:
        return S.commandErrorPermissionDenied;
      case WiFiCommandErrorType.noPrivilegedAccess:
        return S.commandErrorNoPrivilegedAccess;
      case WiFiCommandErrorType.rootUnavailable:
        return S.commandErrorRootUnavailable;
      case WiFiCommandErrorType.shizukuNotInstalled:
        return S.commandErrorShizukuNotInstalled;
      case WiFiCommandErrorType.shizukuNotRunning:
        return S.commandErrorShizukuNotRunning;
      case WiFiCommandErrorType.shizukuPermissionDenied:
        return S.commandErrorShizukuPermissionDenied;
      case WiFiCommandErrorType.shizukuUnsupported:
        return S.commandErrorShizukuUnsupported;
      case WiFiCommandErrorType.shizukuServiceUnavailable:
        return S.commandErrorShizukuServiceUnavailable;
      case WiFiCommandErrorType.iwNotFound:
        return S.commandErrorIwNotFound;
      case WiFiCommandErrorType.cmdWifiNotFound:
        return S.commandErrorCmdWifiNotFound;
      case WiFiCommandErrorType.invalidFrequency:
        final freq = e.params?['frequency'] ?? 0;
        return S.commandErrorInvalidFrequency(freq);
      case WiFiCommandErrorType.noResult:
        return S.commandErrorNoResult;
      case WiFiCommandErrorType.badResult:
        return S.commandErrorBadResult;
      case WiFiCommandErrorType.channelListUnavailable:
        final reason = e.params?['reason'] ?? 'unknown';
        return S.commandErrorChannelListUnavailable(reason);
      case WiFiCommandErrorType.commandNeedsRoot:
        return S.commandErrorCommandNeedsRoot;
      case WiFiCommandErrorType.channelNotStored:
        return S.commandErrorChannelNotStored(
          _storeReason(S, e.params?['reason']),
        );
      case WiFiCommandErrorType.generic:
        return S.commandErrorGeneric;
    }
  }

  _ErrorAction get _errorAction => switch (_errorType) {
    WiFiCommandErrorType.shizukuNotInstalled ||
    WiFiCommandErrorType.shizukuNotRunning ||
    WiFiCommandErrorType.shizukuPermissionDenied ||
    WiFiCommandErrorType.shizukuUnsupported ||
    WiFiCommandErrorType.shizukuServiceUnavailable => _ErrorAction.connect,
    WiFiCommandErrorType.rootUnavailable ||
    WiFiCommandErrorType.noPrivilegedAccess => _ErrorAction.requestRoot,
    _ => _ErrorAction.retry,
  };

  IconData _errorIcon(_ErrorAction action) => switch (action) {
    _ErrorAction.connect => Icons.cable_outlined,
    _ErrorAction.requestRoot => Icons.gpp_maybe_outlined,
    _ErrorAction.retry => Icons.error_outline,
  };

  String _errorTitle(AppLocalizations S, _ErrorAction action) =>
      switch (action) {
        _ErrorAction.connect => S.errorNeedsConnectionTitle,
        _ErrorAction.requestRoot => S.errorNeedsRootTitle,
        _ErrorAction.retry => S.errorOccurred,
      };

  String _errorButtonLabel(AppLocalizations S, _ErrorAction action) {
    return switch (action) {
      _ErrorAction.connect =>
        _errorType == WiFiCommandErrorType.shizukuNotInstalled
            ? S.checkAgainButton
            : S.connectButton,
      _ErrorAction.requestRoot => S.requestRootButton,
      _ErrorAction.retry => S.tryAgain,
    };
  }

  String _currentChannelLabel(AppLocalizations S) {
    final channelNumber = _softApState?.channelNumber;
    if (channelNumber == null) return S.currentChannelAuto;

    return S.currentChannelLabel(channelNumber, _softApState?.frequency ?? 0);
  }

  String _storeReason(AppLocalizations S, Object? raw) {
    final reason = raw?.toString() ?? '';
    if (reason.contains('rejected')) return S.storeReasonRejected;
    if (reason.contains('unavailable')) return S.storeReasonUnavailable;
    if (reason.contains('requires android 11')) {
      return S.storeReasonUnsupportedAndroid;
    }
    return reason.isEmpty ? S.storeReasonUnknown : reason;
  }

  String _backendLabel(AppLocalizations S, AccessBackend backend) {
    return switch (backend) {
      AccessBackend.shizuku => S.accessBackendShizuku,
      AccessBackend.root => S.accessBackendRoot,
    };
  }

  String _channelSourceLabel(AppLocalizations S, ChannelListSource source) {
    return switch (source) {
      ChannelListSource.iw => S.channelSourceIw,
      ChannelListSource.system => S.channelSourceSystem,
      ChannelListSource.softApCapability => S.channelSourceSoftApCapability,
      ChannelListSource.standard => S.channelSourceStandard,
    };
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: S.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
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
    final action = _errorAction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorIcon(action),
              color: action == _ErrorAction.retry
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorTitle(S, action),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: action == _ErrorAction.retry
                  ? _initializeScreen
                  : _connect,
              icon: Icon(_errorIcon(action), size: 18),
              label: Text(_errorButtonLabel(S, action)),
            ),
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
          if (_activeBackend != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(
                    S.activeAccessBackend(_backendLabel(S, _activeBackend!)),
                  ),
                ),
                if (_channelListSource != null)
                  Chip(
                    avatar: const Icon(Icons.list_alt_outlined, size: 18),
                    label: Text(
                      S.channelSourceLabel(
                        _channelSourceLabel(S, _channelListSource!),
                      ),
                    ),
                  ),
                if (_softApState != null)
                  Chip(
                    avatar: const Icon(
                      Icons.settings_input_antenna_outlined,
                      size: 18,
                    ),
                    label: Text(_currentChannelLabel(S)),
                  ),
                IconButton(
                  tooltip: S.refreshTooltip,
                  icon: const Icon(Icons.refresh, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: _refreshCurrentChannel,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 1,
                label: Text(S.band2_4GHz),
                icon: const Icon(Icons.network_wifi_3_bar),
              ),
              ButtonSegment(
                value: 2,
                label: Text(S.band5GHz),
                icon: const Icon(Icons.network_wifi),
              ),
            ],
            selected: {_selectedBand},
            onSelectionChanged: (Set<int> newSelection) =>
                _onBandChanged(newSelection.first),
          ),
          const SizedBox(height: 20),

          if (_channelListSource == ChannelListSource.standard)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                S.channelListStandardWarning,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          DropdownButtonFormField2<WiFiChannel>(
            value: _selectedChannel,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: const OutlineInputBorder(),
              labelText: S.availableChannelsLabel,
            ),
            hint: Text(
              S.selectChannelHint,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
            items: _visibleChannels.map((channel) {
              return DropdownMenuItem<WiFiChannel>(
                value: channel,
                child: Text(
                  S.channelDropdownItem(
                    channel.channelNumber,
                    channel.frequency,
                  ),
                ),
              );
            }).toList(),
            onChanged: (channel) => setState(() => _selectedChannel = channel),

            buttonStyleData: const ButtonStyleData(
              height: 44,
              padding: EdgeInsets.only(left: 0, right: 10),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
              offset: const Offset(0, -5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
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
          if (_canChooseApplyFormat)
            SwitchListTile(
              title: Text(S.applyFormatPersist),
              value: _persistChannel,
              onChanged: _togglePersistChannel,
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedChannel == null || _isApplying
                ? null
                : _applyChannel,
            icon: _isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
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
                  label: Text(
                    S.quickSelectChipLabel(
                      S.band2_4GHz,
                      _savedChannelFreqBand1!,
                    ),
                  ),
                  onPressed: () => _selectSavedChannel(_savedChannelFreqBand1!),
                ),
              if (_savedChannelFreqBand2 != null)
                ActionChip(
                  avatar: const Icon(Icons.network_wifi, size: 18),
                  label: Text(
                    S.quickSelectChipLabel(S.band5GHz, _savedChannelFreqBand2!),
                  ),
                  onPressed: () => _selectSavedChannel(_savedChannelFreqBand2!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
