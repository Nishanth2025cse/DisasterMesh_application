import '../utils/constants.dart';

class ClassificationService {
  static final ClassificationService _instance = ClassificationService._internal();
  factory ClassificationService() => _instance;
  ClassificationService._internal();

  /// Classifies emergency text into standardized category based on keywords
  String classifyMessage(String text) {
    if (text.trim().isEmpty) {
      return AppCategories.general;
    }

    final lower = text.toLowerCase();

    // 1. Medical Emergency Keywords
    final medicalKeywords = [
      'bleeding', 'injured', 'injury', 'unconscious', 'trapped', 'heart attack',
      'stroke', 'fracture', 'headache', 'wound', 'pain', 'doctor', 'hospital',
      'breath', 'breathing', 'collapsed', 'blood', 'medic', 'medicine', 'ambulance'
    ];

    // 2. Flood Rescue Keywords
    final floodKeywords = [
      'flood', 'flooding', 'water entering', 'drowning', 'water level', 'overflow',
      'submerged', 'river overflowing', 'heavy rain', 'cyclone', 'tsunami', 'inundated'
    ];

    // 3. Fire Keywords
    final fireKeywords = [
      'fire', 'burning', 'smoke', 'explosion', 'flames', 'blaze', 'gas leak', 'burn'
    ];

    // 4. Food / Water Keywords
    final foodKeywords = [
      'food', 'hungry', 'starving', 'drinking water', 'clean water', 'ration', 'supplies', 'groceries', 'milk'
    ];

    // 5. Shelter Keywords
    final shelterKeywords = [
      'shelter', 'place to stay', 'roof fallen', 'house collapsed', 'blanket', 'tent', 'refuge', 'homeless'
    ];

    // Prioritized keyword checking logic
    if (medicalKeywords.any((kw) => lower.contains(kw))) {
      return AppCategories.medical;
    }
    if (floodKeywords.any((kw) => lower.contains(kw))) {
      return AppCategories.flood;
    }
    if (fireKeywords.any((kw) => lower.contains(kw))) {
      return AppCategories.fire;
    }
    if (foodKeywords.any((kw) => lower.contains(kw))) {
      return AppCategories.foodWater;
    }
    if (shelterKeywords.any((kw) => lower.contains(kw))) {
      return AppCategories.shelter;
    }

    return AppCategories.general;
  }
}
