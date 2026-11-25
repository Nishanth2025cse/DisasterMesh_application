import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_mesh/services/classification_service.dart';
import 'package:disaster_mesh/utils/constants.dart';

void main() {
  late ClassificationService classifier;

  setUp(() {
    classifier = ClassificationService();
  });

  group('ClassificationService Unit Tests', () {
    test('Classifies medical emergency keywords correctly', () {
      expect(classifier.classifyMessage("I am trapped and injured"), AppCategories.medical);
      expect(classifier.classifyMessage("Person is bleeding and unconscious"), AppCategories.medical);
    });

    test('Classifies flood rescue keywords correctly', () {
      expect(classifier.classifyMessage("Flood water entering house, drowning risk"), AppCategories.flood);
      expect(classifier.classifyMessage("Water level is increasing rapidly"), AppCategories.flood);
    });

    test('Classifies fire emergency keywords correctly', () {
      expect(classifier.classifyMessage("Building on fire and smoke everywhere"), AppCategories.fire);
    });

    test('Classifies food / water requests correctly', () {
      expect(classifier.classifyMessage("We need drinking water and dry food"), AppCategories.foodWater);
    });

    test('Classifies shelter requests correctly', () {
      expect(classifier.classifyMessage("Roof fallen down, need a place to stay"), AppCategories.shelter);
    });

    test('Defaults to General Emergency when no keywords match', () {
      expect(classifier.classifyMessage("Sending emergency signal from sector 4"), AppCategories.general);
    });
  });
}
