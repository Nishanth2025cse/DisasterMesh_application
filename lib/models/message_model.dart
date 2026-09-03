import 'dart:convert';

class MeshMessage {
  final String messageId;
  final String sosId;
  final String payloadType; // SOS_ALERT, SOS_UPDATE, SOS_ACK
  final String payloadJson;
  final String senderDeviceId;
  final String recipientDeviceId;
  final DateTime timestamp;
  final int ttl;
  final int hopsCount;

  MeshMessage({
    required this.messageId,
    required this.sosId,
    required this.payloadType,
    required this.payloadJson,
    required this.senderDeviceId,
    this.recipientDeviceId = 'BROADCAST',
    required this.timestamp,
    this.ttl = 5,
    this.hopsCount = 0,
  });

  MeshMessage copyForForward({required String currentDeviceId}) {
    return MeshMessage(
      messageId: messageId,
      sosId: sosId,
      payloadType: payloadType,
      payloadJson: payloadJson,
      senderDeviceId: currentDeviceId,
      recipientDeviceId: 'BROADCAST',
      timestamp: DateTime.now(),
      ttl: ttl - 1,
      hopsCount: hopsCount + 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'sosId': sosId,
      'payloadType': payloadType,
      'payloadJson': payloadJson,
      'senderDeviceId': senderDeviceId,
      'recipientDeviceId': recipientDeviceId,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl,
      'hopsCount': hopsCount,
    };
  }

  factory MeshMessage.fromMap(Map<String, dynamic> map) {
    return MeshMessage(
      messageId: map['messageId'] ?? '',
      sosId: map['sosId'] ?? '',
      payloadType: map['payloadType'] ?? 'SOS_ALERT',
      payloadJson: map['payloadJson'] ?? '',
      senderDeviceId: map['senderDeviceId'] ?? 'unknown_sender',
      recipientDeviceId: map['recipientDeviceId'] ?? 'BROADCAST',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      ttl: map['ttl'] != null ? map['ttl'] as int : 5,
      hopsCount: map['hopsCount'] != null ? map['hopsCount'] as int : 0,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory MeshMessage.fromJson(String source) => MeshMessage.fromMap(jsonDecode(source));
}
