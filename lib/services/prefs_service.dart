import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified SharedPreferences wrapper.
/// Keys are all namespaced under 'kl_' to avoid collisions.
class PrefsService {
  static const _keyLastIndex = 'kl_last_index';
  static const _keySelectedTopics = 'kl_selected_topics';
  static const _keyDisplayName = 'kl_display_name';
  static const _keyLocationLabel = 'kl_location_label';
  static const _keyLocationAsked = 'kl_location_asked';
  static const _keyCachedStoryIds = 'kl_cached_story_ids';
  static const _keyCachedAt = 'kl_cached_at';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw StateError('PrefsService.init() not called');
    return _prefs!;
  }

  // ── Last viewed index ──────────────────────────────────────────────────────
  static int getLastIndex() => _p.getInt(_keyLastIndex) ?? 0;
  static Future<void> setLastIndex(int i) => _p.setInt(_keyLastIndex, i);

  // ── Selected topics ────────────────────────────────────────────────────────
  static List<String> getSelectedTopics(List<String> defaults) {
    final raw = _p.getString(_keySelectedTopics);
    if (raw == null) return List.from(defaults);
    try {
      return List<String>.from(json.decode(raw) as List);
    } catch (_) {
      return List.from(defaults);
    }
  }

  static Future<void> setSelectedTopics(List<String> topics) =>
      _p.setString(_keySelectedTopics, json.encode(topics));

  // ── Display name ───────────────────────────────────────────────────────────
  static String? getDisplayName() => _p.getString(_keyDisplayName);
  static Future<void> setDisplayName(String name) =>
      _p.setString(_keyDisplayName, name);

  // ── Location label ─────────────────────────────────────────────────────────
  static String getLocationLabel() =>
      _p.getString(_keyLocationLabel) ?? 'Berlin, DE';
  static Future<void> setLocationLabel(String label) =>
      _p.setString(_keyLocationLabel, label);

  // ── Location permission flag ───────────────────────────────────────────────
  static bool getLocationAsked() => _p.getBool(_keyLocationAsked) ?? false;
  static Future<void> setLocationAsked(bool v) =>
      _p.setBool(_keyLocationAsked, v);

  // ── Cached story IDs (for new-story detection) ─────────────────────────────
  static List<String> getCachedStoryIds() {
    final raw = _p.getString(_keyCachedStoryIds);
    if (raw == null) return [];
    try {
      return List<String>.from(json.decode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> setCachedStoryIds(List<String> ids) =>
      _p.setString(_keyCachedStoryIds, json.encode(ids));

  // ── Cached-at ISO timestamp ────────────────────────────────────────────────
  static String? getCachedAt() => _p.getString(_keyCachedAt);
  static Future<void> setCachedAt(String iso) =>
      _p.setString(_keyCachedAt, iso);
}
