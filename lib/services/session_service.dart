import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Manages all per-device session state that must survive app restarts.
///
/// - [deviceId]: Stable UUID generated once on first launch, used as
///   X-Device-ID header so the backend tracks read history per device.
/// - [readStoryIds]: Set of story IDs already read; used to filter the feed
///   client-side in addition to the server-side filter.
/// - [lastStoryIndex]: The PageView index when the user last closed the app;
///   restored on next launch so they land on the same card.
/// - [selectedTopics]: Active topic filter tags from the drawer's My Feed
///   section; empty list means "show all".
/// - [displayName]: Funny auto-generated username shown in the drawer.
/// - [locationLabel]: Human-readable city label shown under the name.
class SessionService {
  static const _keyDeviceId = 'device_id';
  static const _keyReadIds = 'read_story_ids';
  static const _keyLastIndex = 'last_story_index';
  static const _keyTopics = 'selected_topics';
  static const _keyDisplayName = 'display_name';
  static const _keyLocation = 'location_label';
  static const _keyLocationAsked = 'location_permission_asked';

  static SharedPreferences? _prefs;

  /// Must be called once in main() before runApp().
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs!.getString(_keyDeviceId) == null) {
      final id = const Uuid().v4();
      await _prefs!.setString(_keyDeviceId, id);
      // Seed funny name on first launch
      _generateFunnyName(id);
    }
  }

  // ------------------------------------------------------------------ identity

  static String get deviceId =>
      _prefs?.getString(_keyDeviceId) ?? 'anonymous';

  static String get displayName {
    final stored = _prefs?.getString(_keyDisplayName);
    if (stored != null && stored.isNotEmpty) return stored;
    return _generateFunnyName(deviceId);
  }

  static Future<void> saveDisplayName(String name) async {
    await _prefs?.setString(_keyDisplayName, name);
  }

  static String _generateFunnyName(String seed) {
    const names = [
      'D\u00f6ner Detective',
      'Kaffeekraken Klaus',
      'Sp\u00e4tzle Sherlock',
      'Pretzel Picasso',
      'Bratwurst Brainiac',
      'Schnitzel Scholar',
      'Berliner B\u00e4renj\u00e4ger',
      'U-Bahn \u00dcbermensch',
      'Currywurst Kapit\u00e4n',
      'Kiezlink Kobold',
      'Tempelhof Taktiker',
      'Mauer Meister',
    ];
    final idx = seed.isEmpty ? 0 : seed.codeUnits.first % names.length;
    final name = names[idx];
    _prefs?.setString(_keyDisplayName, name);
    return name;
  }

  // ---------------------------------------------------------------- location

  static String get locationLabel =>
      _prefs?.getString(_keyLocation) ?? 'Berlin, DE';

  static Future<void> saveLocation(String label) async {
    await _prefs?.setString(_keyLocation, label);
  }

  static bool get locationPermissionAsked =>
      _prefs?.getBool(_keyLocationAsked) ?? false;

  static Future<void> setLocationPermissionAsked() async {
    await _prefs?.setBool(_keyLocationAsked, true);
  }

  // --------------------------------------------------------- read history

  static Set<String> get readStoryIds {
    final raw = _prefs?.getString(_keyReadIds) ?? '[]';
    final list = (jsonDecode(raw) as List).cast<String>();
    return list.toSet();
  }

  static Future<void> markRead(String storyId) async {
    final ids = readStoryIds..add(storyId);
    await _prefs?.setString(_keyReadIds, jsonEncode(ids.toList()));
  }

  static bool isRead(String storyId) => readStoryIds.contains(storyId);

  static Future<void> clearReadHistory() async {
    await _prefs?.setString(_keyReadIds, '[]');
  }

  // -------------------------------------------------------- last index

  static int get lastStoryIndex => _prefs?.getInt(_keyLastIndex) ?? 0;

  static Future<void> saveLastIndex(int index) async {
    await _prefs?.setInt(_keyLastIndex, index);
  }

  // ------------------------------------------------------ topic filters

  static List<String> get selectedTopics {
    final raw = _prefs?.getString(_keyTopics);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> saveTopics(List<String> topics) async {
    await _prefs?.setString(_keyTopics, jsonEncode(topics));
  }
}
