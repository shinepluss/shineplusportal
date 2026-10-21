import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Encapsulates the result of a GPS verification fetch
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final bool isMock;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isMock = false,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°';
}

/// Service to handle GPS location fetching and reverse geocoding with robust mock fallbacks.
class LocationService {
  /// Default mock fallback location when GPS/permissions are unavailable or on emulators
  static const LocationResult mockFallback = LocationResult(
    latitude: 31.5204,
    longitude: 74.3587,
    address: 'Shine Plus Headquarters, Gulberg III, Lahore, Punjab',
    isMock: true,
  );

  /// Captures current GPS coordinates and reverse-geocodes them into a human-readable address
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return mockFallback;
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return mockFallback;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return mockFallback;
      }

      // 3. Get accurate device position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // 4. Reverse-geocode coordinates into readable address
      String readableAddress = 'Lat: ${position.latitude}, Lng: ${position.longitude}';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final street = place.street ?? place.subLocality ?? '';
          final locality = place.locality ?? place.subAdministrativeArea ?? '';
          final adminArea = place.administrativeArea ?? '';
          final country = place.country ?? '';

          final parts = <String>[];
          if (street.trim().isNotEmpty) parts.add(street.trim());
          if (locality.trim().isNotEmpty) parts.add(locality.trim());
          if (adminArea.trim().isNotEmpty) parts.add(adminArea.trim());
          if (country.trim().isNotEmpty) parts.add(country.trim());

          if (parts.isNotEmpty) {
            readableAddress = parts.join(', ');
          }
        }
      } catch (_) {
        // Fall back to coordinate string if geocoding server is unreachable
        readableAddress =
            'Location (${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°)';
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: readableAddress,
        isMock: false,
      );
    } catch (_) {
      // Return seamless fallback on emulator, platform exception, or timeout
      return mockFallback;
    }
  }
}
