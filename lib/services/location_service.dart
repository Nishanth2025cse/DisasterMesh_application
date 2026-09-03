import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final bool isSuccess;
  final String? errorMessage;

  LocationResult({
    this.latitude,
    this.longitude,
    required this.isSuccess,
    this.errorMessage,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Gets current GPS coordinates offline without internet.
  Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          isSuccess: false,
          errorMessage: "GPS is disabled. Please enable Location Services on your phone.",
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            isSuccess: false,
            errorMessage: "Location permission denied. GPS coordinates cannot be captured.",
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          isSuccess: false,
          errorMessage: "Location permissions are permanently denied. Please grant permission in app settings.",
        );
      }

      // Capture GPS Position with high accuracy and timeout fallback
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).catchError((_) async {
        // Fallback to last known position if timeout occurs
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) return lastPos;
        throw Exception("GPS location query timed out.");
      });

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isSuccess: true,
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        errorMessage: "Unable to obtain current GPS location: ${e.toString().replaceAll('Exception: ', '')}",
      );
    }
  }

  /// Default fallback mock location (Coimbatore Disaster Center area coordinates for offline testing)
  LocationResult getFallbackLocation() {
    return LocationResult(
      latitude: 11.02345,
      longitude: 76.96231,
      isSuccess: true,
    );
  }
}
