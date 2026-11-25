import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_mesh/services/priority_service.dart';
import 'package:disaster_mesh/utils/constants.dart';

void main() {
  late PriorityService prioritizer;

  setUp(() {
    prioritizer = PriorityService();
  });

  group('PriorityService Unit Tests', () {
    test('Assigns HIGH priority to trapped/injured medical emergencies', () {
      expect(prioritizer.calculatePriority(AppCategories.medical, "Trapped and unconscious"), AppPriorities.high);
    });

    test('Assigns MEDIUM priority to food/water requests', () {
      expect(prioritizer.calculatePriority(AppCategories.foodWater, "We need drinking water"), AppPriorities.medium);
    });

    test('Assigns LOW priority to general info', () {
      expect(prioritizer.calculatePriority(AppCategories.general, "Assembly point at school ground"), AppPriorities.low);
    });
  });
}
