class DeviceModel {
  final String endpointId;
  final String endpointName;
  final bool isConnected;
  final int rssi;
  final DateTime lastSeen;
  final String deviceType; // Relay, Rescue, Victim

  DeviceModel({
    required this.endpointId,
    required this.endpointName,
    this.isConnected = false,
    this.rssi = -60,
    required this.lastSeen,
    this.deviceType = 'Relay',
  });

  DeviceModel copyWith({
    bool? isConnected,
    int? rssi,
    DateTime? lastSeen,
    String? deviceType,
  }) {
    return DeviceModel(
      endpointId: endpointId,
      endpointName: endpointName,
      isConnected: isConnected ?? this.isConnected,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}
