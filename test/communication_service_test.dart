import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_mesh/models/message_model.dart';

void main() {
  group('Mesh Relay Protocol Unit Tests', () {
    test('Copy for forward decrements TTL and increments hops count', () {
      final initialMessage = MeshMessage(
        messageId: "MSG001",
        sosId: "SOS001",
        payloadType: "SOS_ALERT",
        payloadJson: "{}",
        senderDeviceId: "Phone-A",
        timestamp: DateTime.now(),
        ttl: 5,
        hopsCount: 0,
      );

      final forwardedMessage = initialMessage.copyForForward(currentDeviceId: "Phone-B");

      expect(forwardedMessage.ttl, equals(4));
      expect(forwardedMessage.hopsCount, equals(1));
      expect(forwardedMessage.senderDeviceId, equals("Phone-B"));
      expect(forwardedMessage.sosId, equals("SOS001"));
    });
  });
}
