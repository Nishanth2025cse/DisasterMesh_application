import 'dart:convert';

class SosUpdateEntry {
  final String message;
  final String category;
  final String priority;
  final DateTime timestamp;

  SosUpdateEntry({
    required this.message,
    required this.category,
    required this.priority,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'category': category,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SosUpdateEntry.fromMap(Map<String, dynamic> map) {
    return SosUpdateEntry(
      message: map['message'] ?? '',
      category: map['category'] ?? 'General Emergency',
      priority: map['priority'] ?? 'HIGH',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}

class SosModel {
  final String sosId;
  final String userId;
  final String victimName;
  final String? victimPhone;
  final String message;
  final String category;
  final String priority;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status; // Pending, Accepted, Responding, Rescued
  final int ttl;
  final String originDeviceId;
  final int version; // Increments on dynamic updates
  final List<SosUpdateEntry> updateHistory;

  SosModel({
    required this.sosId,
    required this.userId,
    required this.victimName,
    this.victimPhone,
    required this.message,
    required this.category,
    required this.priority,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.status = 'Pending',
    this.ttl = 5,
    required this.originDeviceId,
    this.version = 1,
    List<SosUpdateEntry>? updateHistory,
  }) : updateHistory = updateHistory ?? [];

  SosModel copyWith({
    String? message,
    String? category,
    String? priority,
    double? latitude,
    double? longitude,
    String? status,
    int? ttl,
    int? version,
    List<SosUpdateEntry>? updateHistory,
  }) {
    return SosModel(
      sosId: this.sosId,
      userId: this.userId,
      victimName: this.victimName,
      victimPhone: this.victimPhone,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: DateTime.now(), // timestamp of update
      status: status ?? this.status,
      ttl: ttl ?? this.ttl,
      originDeviceId: this.originDeviceId,
      version: version ?? (this.version + 1),
      updateHistory: updateHistory ?? this.updateHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sosId': sosId,
      'userId': userId,
      'victimName': victimName,
      'victimPhone': victimPhone ?? '',
      'message': message,
      'category': category,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'ttl': ttl,
      'originDeviceId': originDeviceId,
      'version': version,
      'updateHistory': jsonEncode(updateHistory.map((e) => e.toMap()).toList()),
    };
  }

  factory SosModel.fromMap(Map<String, dynamic> map) {
    List<SosUpdateEntry> history = [];
    if (map['updateHistory'] != null && map['updateHistory'].toString().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(map['updateHistory']);
        history = decoded.map((e) => SosUpdateEntry.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return SosModel(
      sosId: map['sosId'] ?? '',
      userId: map['userId'] ?? '',
      victimName: map['victimName'] ?? 'Unknown Victim',
      victimPhone: map['victimPhone'],
      message: map['message'] ?? '',
      category: map['category'] ?? 'General Emergency',
      priority: map['priority'] ?? 'HIGH',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      status: map['status'] ?? 'Pending',
      ttl: map['ttl'] != null ? map['ttl'] as int : 5,
      originDeviceId: map['originDeviceId'] ?? 'unknown_device',
      version: map['version'] != null ? map['version'] as int : 1,
      updateHistory: history,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory SosModel.fromJson(String source) => SosModel.fromMap(jsonDecode(source));
}
