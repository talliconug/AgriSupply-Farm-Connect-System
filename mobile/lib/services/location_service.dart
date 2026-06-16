import 'package:geolocator/geolocator.dart';

/// LocationService - Handles geolocation features
/// 
/// Note: For delivery addresses, it's recommended to use district-based
/// region detection instead of GPS, as users might be traveling or
/// temporarily in a different location. GPS is useful for:
/// - "Products near me" distance calculations
/// - Delivery tracking
/// - Finding nearby farmers/buyers
class LocationService {
  factory LocationService() => _instance;
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Get current position with permission handling
  Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check permission
    var permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    }

    // Get position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
      return position;
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  /// Get region from coordinates (simplified - in production use reverse geocoding API)
  String getRegionFromCoordinates(final double latitude, final double longitude) {
    // Approximate boundaries for Uganda regions
    // Central: 0.0° to 1.5°N, 31.5° to 33.5°E
    // Eastern: -1.0° to 2.0°N, 33.0° to 35.0°E
    // Northern: 2.0° to 4.0°N, 30.0° to 35.0°E
    // Western: -1.5° to 2.0°N, 29.5° to 31.5°E
    
    if (latitude >= 2.0 && latitude <= 4.0) {
      return 'Northern';
    } else if (longitude >= 33.0 && longitude <= 35.0) {
      return 'Eastern';
    } else if (longitude >= 29.5 && longitude <= 31.5) {
      return 'Western';
    } else {
      return 'Central';
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    final double startLat,
    final double startLng,
    final double endLat,
    final double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }
}
