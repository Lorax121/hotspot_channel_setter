enum WiFiCommandErrorType {
  generic,
  timeout,
  permissionDenied,
  noPrivilegedAccess,
  rootUnavailable,
  shizukuNotInstalled,
  shizukuNotRunning,
  shizukuPermissionDenied,
  shizukuUnsupported,
  shizukuServiceUnavailable,
  iwNotFound,
  cmdWifiNotFound,
  channelListUnavailable,
  commandNeedsRoot,
  channelNotStored,
  invalidFrequency,
  noResult,
  badResult,
}

class WiFiCommandException implements Exception {
  const WiFiCommandException(this.type, {this.params});

  final WiFiCommandErrorType type;
  final Map<String, dynamic>? params;

  @override
  String toString() => 'WiFiCommandException: ${type.name}, params: $params';
}
