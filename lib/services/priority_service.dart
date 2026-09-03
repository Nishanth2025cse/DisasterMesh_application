import '../utils/constants.dart';

class PriorityService {
  static final PriorityService _instance = PriorityService._internal();
  factory PriorityService() => _instance;
  PriorityService._internal();

  /// Calculates Priority (HIGH, MEDIUM, LOW) based on category & message text
  String calculatePriority(String category, String text) {
    final lower = text.toLowerCase();

    // High Priority Critical Keywords
    final highKeywords = [
      'trapped', 'injured', 'unconscious', 'bleeding', 'drowning', 'fire',
      'dying', 'cannot breathe', 'heart attack', 'collapsed', 'severe', 'child trapped',
      'electric shock', 'burning', 'immediate'
    ];

    // Medium Priority Keywords
    final mediumKeywords = [
      'food', 'water', 'medicine', 'shelter', 'blanket', 'infant food',
      'diabetic', 'dry food', 'place to stay'
    ];

    // Category overrides
    if (category == AppCategories.medical || category == AppCategories.fire || category == AppCategories.flood) {
      // Check if message mentions non-critical or minor info
      if (highKeywords.any((kw) => lower.contains(kw))) {
        return AppPriorities.high;
      }
      // If medical or fire or flood, default to HIGH unless explicitly specified low
      return AppPriorities.high;
    }

    if (category == AppCategories.foodWater || category == AppCategories.shelter) {
      if (highKeywords.any((kw) => lower.contains(kw))) {
        return AppPriorities.high;
      }
      return AppPriorities.medium;
    }

    if (highKeywords.any((kw) => lower.contains(kw))) {
      return AppPriorities.high;
    }

    if (mediumKeywords.any((kw) => lower.contains(kw))) {
      return AppPriorities.medium;
    }

    return AppPriorities.low;
  }
}
