enum AdbErrorType {
  generic,
  timeout,
  permissionDenied,
  iwNotFound,
  cmdWifiNotFound,
  invalidFrequency,
  noResult,
  badResult,
}

class AdbException implements Exception {
  final AdbErrorType type;
  final Map<String, dynamic>? params;

  AdbException(this.type, {this.params});

  @override
  String toString() {
    return 'AdbException: ${type.name}, params: $params';
  }
}