import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_mesh/models/sos_model.dart';
import 'package:disaster_mesh/utils/helpers.dart';

void main() {
  group('SosModel & Dynamic Update Tests', () {
    test('Generate unique readable SOS ID format', () {
      final sosId = Helpers.generateSosId(sequentialNumber: 1);
      expect(sosId.startsWith('SOS-001-'), isTrue);
    });

    test('Dynamic update preserves original SOS ID and increments version', () {
      final initialSos = SosModel(
        sosId: "SOS002",
        userId: "USER123",
        victimName: "Praveena",
        message: "Food Required",
        category: "Food / Water",
        priority: "MEDIUM",
        latitude: 11.02345,
        longitude: 76.96231,
        timestamp: DateTime.now(),
        originDeviceId: "DEV1",
        version: 1,
      );

      final updatedSos = initialSos.copyWith(
        message: "Person has collapsed and is unconscious.",
        category: "Medical Emergency",
        priority: "HIGH",
        version: initialSos.version + 1,
      );

      expect(updatedSos.sosId, equals("SOS002"));
      expect(updatedSos.version, equals(2));
      expect(updatedSos.priority, equals("HIGH"));
      expect(updatedSos.category, equals("Medical Emergency"));
    });
  });
}
