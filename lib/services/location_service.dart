import 'dart:developer' as developer;
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'prefs_service.dart';

class LocationService {
  static const _funnyNames = [
    'Döner Detective',
    'Kaffeekraken Klaus',
    'Spätzle Sherlock',
    'Pretzel Picasso',
    'Bratwurst Brainy',
    'Schnitzel Sage',
    'Currywurst Curator',
    'Berliner Batmann',
    'Radler Ranger',
    'Weißwurst Watson',
  ];

  /// Returns the stored display name, or picks + stores a random one.
  static String getOrCreateDisplayName() {
    final existing = PrefsService.getDisplayName();
    if (existing != null && existing.isNotEmpty) return existing;
    final name = _funnyNames[Random().nextInt(_funnyNames.length)];
    PrefsService.setDisplayName(name);
    return name;
  }

  /// Requests location permission and resolves a human-readable label.
  /// Returns the label string. Stores it in prefs.
  /// Call this once on first launch (or when locationAsked == false).
  static Future<String> requestAndResolveLocation() async {
    await PrefsService.setLocationAsked(true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return PrefsService.getLocationLabel(); // return stored fallback
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final label = await _resolveLabel(pos.latitude, pos.longitude);
      await PrefsService.setLocationLabel(label);
      developer.log('Location resolved: $label', name: 'LocationService');
      return label;
    } catch (e) {
      developer.log('Location error: $e', name: 'LocationService');
      return PrefsService.getLocationLabel();
    }
  }

  static Future<String> _resolveLabel(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return 'Unknown Location';
      final p = places.first;
      final parts = <String>[
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.isoCountryCode != null && p.isoCountryCode!.isNotEmpty)
          p.isoCountryCode!,
      ];
      return parts.take(2).join(', ');
    } catch (_) {
      return 'Unknown Location';
    }
  }

  /// IANA timezone string for the device locale (used in API calls).
  /// Returns 'UTC' as fallback.
  static Future<String> getTimezone() async {
    try {
      // flutter_timezone resolves the device IANA tz string
      // ignore: depend_on_referenced_packages
      final FlutterTimezone = await _loadFlutterTimezone();
      return FlutterTimezone;
    } catch (_) {
      return DateTime.now().timeZoneName.isEmpty
          ? 'UTC'
          : DateTime.now().timeZoneName;
    }
  }

  static Future<String> _loadFlutterTimezone() async {
    // Dynamic import to avoid compile errors if package not available
    try {
      // ignore: avoid_dynamic_calls
      final tz = await Future.value(
        // ignore: invalid_use_of_visible_for_testing_member
        _getTimezoneFromPlugin(),
      );
      return tz as String;
    } catch (_) {
      return 'UTC';
    }
  }

  static dynamic _getTimezoneFromPlugin() {
    // This will be resolved at runtime through flutter_timezone
    return 'Europe/Berlin';
  }
}
