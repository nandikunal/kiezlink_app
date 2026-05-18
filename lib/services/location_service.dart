import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A curated list of funny Berlin-flavored display names.
/// One is assigned randomly on first launch and stored permanently.
const _funnyNames = [
  'Döner Detective',
  'Pretzel Picasso',
  'Spätzle Sherlock',
  'Kaffeekraken Klaus',
  'Fahrrad Freya',
  'Berliner Barista',
  'S-Bahn Samurai',
  'Currywurst Cosmo',
  'Bauhaus Bruno',
  'Kiez Kapitän',
  'Tempelhofer Tilda',
  'Brezel Baron',
  'Mauer Maxi',
  'Schnitzel Sherpa',
  'Pfannkuchen Pablo',
];

class LocationService {
  static const _keyName = 'display_name';
  static const _keyCity = 'display_city';
  static const _keyTz = 'device_timezone';
  static const _keyPermissionAsked = 'location_permission_asked';

  // ── Public state ──────────────────────────────────────────────
  String displayName = 'Berliner Leser';
  String displayCity = 'Berlin, DE';
  String timezone = 'Europe/Berlin';

  /// Call once from main.dart (before runApp) or from app lifecycle.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Assign a funny name once and persist it
    if (!prefs.containsKey(_keyName)) {
      final name = _funnyNames[Random().nextInt(_funnyNames.length)];
      await prefs.setString(_keyName, name);
    }
    displayName = prefs.getString(_keyName) ?? displayName;
    displayCity = prefs.getString(_keyCity) ?? displayCity;
    timezone = prefs.getString(_keyTz) ?? await _resolveTimezone();

    // Resolve location (non-blocking — caller awaits but UI doesn't block)
    await _resolveLocation(prefs);
  }

  /// Called from AppLifecycleState.resumed when permission was previously denied
  /// but not permanently, to gently re-try.
  Future<void> retryIfNeeded() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      final prefs = await SharedPreferences.getInstance();
      await _resolveLocation(prefs);
    }
  }

  // ── Private ────────────────────────────────────────────────────

  Future<String> _resolveTimezone() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTz, tz);
      timezone = tz;
      return tz;
    } catch (_) {
      return 'Europe/Berlin';
    }
  }

  Future<void> _resolveLocation(SharedPreferences prefs) async {
    // Mark that we have asked at least once
    await prefs.setBool(_keyPermissionAsked, true);

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Silently fall back to stored / default city
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, // city-level is enough
            timeLimit: Duration(seconds: 8),
          ),
        );
        final placemarks = await placemarkFromCoordinates(
          pos.latitude, pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = p.locality ?? p.administrativeArea ?? 'Unknown';
          final country = p.isoCountryCode ?? '';
          displayCity = '$city, $country';
          await prefs.setString(_keyCity, displayCity);
        }
        // Also resolve timezone now that we have a real position
        await _resolveTimezone();
      } catch (e) {
        debugPrint('LocationService: geocoding failed: $e');
      }
    }
  }
}
