// lib/services/location_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationDataResult {
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final bool isAvailable;

  const LocationDataResult({
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    required this.isAvailable,
  });

  const LocationDataResult.unavailable()
      : latitude = null,
        longitude = null,
        city = null,
        state = null,
        isAvailable = false;
}

class LocationService {
  const LocationService();

  Future<LocationDataResult> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on device
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS is disabled on device.');
        return const LocationDataResult.unavailable();
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied.');
          return const LocationDataResult.unavailable();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission permanently denied.');
        return const LocationDataResult.unavailable();
      }

      // 3. Acquire real hardware GPS coordinates (timeout after 4s)
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      String? city;
      String? state;

      // 4. Lightweight reverse-geocoding (Pure HTTP, no native plugin dependency)
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10',
        );
        final response = await http.get(
          url,
          headers: {'User-Agent': 'ForensIQ-FieldCompanion/1.0'},
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final address = data['address'];
          if (address != null) {
            city = address['city'] ?? address['town'] ?? address['county'] ?? address['state_district'];
            state = address['state'];
          }
        }
      } catch (e) {
        debugPrint('[LocationService] Reverse-geocoding network note: $e');
        // If offline, city/state will be null and the app cleanly displays coordinates
      }

      return LocationDataResult(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        state: state,
        isAvailable: true,
      );
    } catch (e) {
      debugPrint('[LocationService] Location error: $e');
      return const LocationDataResult.unavailable();
    }
  }
}