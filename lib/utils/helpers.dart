import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Helpers {
  static const Uuid _uuid = Uuid();

  /// Format timestamp into readable time string (e.g. 10:25 AM)
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format timestamp into full date & time (e.g. Oct 24, 2026 10:25 AM)
  static String formatFullDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  /// Format coordinates to readable string
  static String formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return "Location Unavailable";
    return "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
  }

  /// Generate globally unique ID, with short human-readable representation
  static String generateSosId({int sequentialNumber = 1}) {
    // Generate a unique 4-digit code combined with sequential prefix
    final String uniquePart = _uuid.v4().substring(0, 4).toUpperCase();
    final String seqStr = sequentialNumber.toString().padLeft(3, '0');
    return "SOS-$seqStr-$uniquePart";
  }

  /// Format short readable display ID (e.g. SOS001)
  static String formatDisplayId(String fullSosId, int index) {
    if (fullSosId.startsWith("SOS-")) {
      final parts = fullSosId.split("-");
      if (parts.length >= 2) {
        return "SOS${parts[1]}";
      }
    }
    return "SOS${(index + 1).toString().padLeft(3, '0')}";
  }
}
