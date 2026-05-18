import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'session_service.dart';

/// Handles device location resolution and IANA timezone detection.
///
/// Call [requestAndResolve] on first app launch (or when the user
/// explicitly triggers it from the drawer). Falls back gracefully
/// to the previously saved label if permission is denied.
class LocationService {
  /// Request location permission (if needed) and resolve lat/lng to a
  /// human-readable city label such as "Berlin, DE".
  ///
  /// Saves the result via [SessionService.saveLocation] so it persists
  /// across restarts. Returns the resolved label (or the previously
  /// saved fallback on failure).
  static Future<String> requestAndResolve() async {
    try {
      await SessionService.setLocationPermissionAsked();

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        developer.log(
          'Location permission denied — using saved fallback',
          name: 'LocationService',
        );
        return SessionService.locationLabel;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.city,
        timeLimit: const Duration(seconds: 8),
      );

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city =
            p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
        final country = p.isoCountryCode ?? '';
        final label = '$city, $country'.trim();
        if (label.isNotEmpty && label != ', ') {
          await SessionService.saveLocation(label);
          developer.log('Location resolved: $label', name: 'LocationService');
          return label;
        }
      }
    } catch (e) {
      developer.log('LocationService error: $e', name: 'LocationService');
    }
    return SessionService.locationLabel;
  }

  /// Returns the device's IANA timezone string, e.g. "Europe/Berlin".
  /// Falls back to "UTC" if unavailable.
  static Future<String> getTimezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return 'UTC';
    }
  }

  /// Whether location permission has already been requested on this device.
  static bool get permissionAlreadyAsked =>
      SessionService.locationPermissionAsked;
}
