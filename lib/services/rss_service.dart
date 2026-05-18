import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/news_item.dart';
import '../utils/utils.dart';
import 'http_client_service.dart';
import 'session_service.dart';
import 'location_service.dart';

/// Handles all HTTP communication with the news_feed backend.
///
/// Every request includes:
///   X-API-Key      — from AppConfig.apiKey
///   X-Device-ID    — stable UUID from SessionService.deviceId
///
/// The device ID scopes read history, stats, and session state
/// to this specific installation.
class RssService {
  static final HttpClientService _httpClient =
      HttpClientService(cacheDuration: const Duration(minutes: 5));

  static String get _base => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> _headers() async => {
        'accept': 'application/json',
        'X-API-Key': AppConfig.apiKey,
        'X-Device-ID': SessionService.deviceId,
      };

  // ---------------------------------------------------------------- today feed

  /// Fetch today's unread stories for this device.
  ///
  /// Sends [?tz=] so the server can apply timezone-aware midnight filtering.
  /// Sends [?topics=] when a topic filter is active.
  /// Client-side also filters out locally known read IDs as a safety net.
  static Future<List<NewsItem>> fetchAll({
    int page = 1,
    int perPage = 20,
    List<String>? topics,
  }) async {
    try {
      final tz = await LocationService.getTimezone();
      final topicParam = (topics != null && topics.isNotEmpty)
          ? '&topics=${topics.map(Uri.encodeComponent).join(',')}'
          : '';
      final url =
          '$_base/v1/today?page=$page&per_page=$perPage'
          '&tz=${Uri.encodeComponent(tz)}$topicParam';

      developer.log('GET $url', name: 'RssService');
      final headers = await _headers();
      final response = await _httpClient.getCached(url, headers: headers);

      if (response.statusCode != 200) return [];
      if (response.body.isEmpty) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!ValidationUtils.isValidApiResponse(data)) return [];

      final stories = (data['stories'] as List? ?? []);
      final readIds = SessionService.readStoryIds;
      final items = <NewsItem>[];

      for (final s in stories) {
        try {
          final story = s as Map<String, dynamic>;
          if (!ValidationUtils.isValidNewsItem(story)) continue;
          final storyId = (story['id'] ?? '').toString();
          if (readIds.contains(storyId)) continue; // client-side safety net

          items.add(NewsItem(
            id: storyId,
            title: (story['title'] ?? 'No Title').toString().trim(),
            summary: (story['short_content'] ?? '').toString().trim(),
            content: (story['short_content'] ?? '').toString().trim(),
            imageUrl: (story['image_url'] ?? '').toString().trim(),
            source: (story['source'] ?? 'Unknown').toString().trim(),
            sourceUrl: (story['link'] ?? '').toString().trim(),
            publishedAt:
                DateTimeUtils.parseDateTime(story['published_at']),
            category: (story['category'] ?? 'today').toString().trim(),
            tag: (story['topic'] ?? 'general').toString().trim(),
            eventDate: null,
            isRead: story['read'] as bool? ?? false,
            isLiked: story['liked'] as bool? ?? false,
            isBookmarked: story['bookmarked'] as bool? ?? false,
          ));
        } catch (e) {
          developer.log('Story parse error: $e', name: 'RssService');
        }
      }

      items.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return items;
    } catch (e) {
      developer.log('fetchAll error: $e', name: 'RssService');
      return [];
    }
  }

  // ---------------------------------------------------------------- stats

  /// Fetch deduplicated read/unread/total counts for today (device-scoped).
  /// Call on app launch and after every markReadOnServer() to keep UI in sync.
  static Future<Map<String, int>> fetchStats() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$_base/v1/today/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'read': (data['read'] as num?)?.toInt() ?? 0,
          'unread': (data['unread'] as num?)?.toInt() ?? 0,
          'total': (data['deduplicated_total'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (e) {
      developer.log('fetchStats error: $e', name: 'RssService');
    }
    return {'read': 0, 'unread': 0, 'total': 0};
  }

  // ---------------------------------------------------------------- actions

  /// Mark a story read on the server for this device. Fire-and-forget.
  static Future<void> markReadOnServer(String storyId) async {
    try {
      final headers = await _headers();
      await http.post(
        Uri.parse('$_base/v1/stories/$storyId/read'),
        headers: headers,
      );
    } catch (_) {}
  }

  static Future<void> likeStory(String storyId) async {
    try {
      final headers = await _headers();
      await http.post(
        Uri.parse('$_base/v1/stories/$storyId/like'),
        headers: headers,
      );
    } catch (_) {}
  }

  static Future<void> bookmarkStory(String storyId) async {
    try {
      final headers = await _headers();
      await http.post(
        Uri.parse('$_base/v1/stories/$storyId/bookmark'),
        headers: headers,
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------- session

  /// Sync session state to server (debounced in NewsProvider to 500ms).
  static Future<void> syncSession({
    required int lastIndex,
    required List<String> topics,
    required String displayName,
    required String locationLabel,
  }) async {
    try {
      final headers = {
        ...await _headers(),
        'Content-Type': 'application/json',
      };
      await http.put(
        Uri.parse('$_base/v1/today/session'),
        headers: headers,
        body: json.encode({
          'last_story_index': lastIndex,
          'selected_topics': topics,
          'display_name': displayName,
          'location_label': locationLabel,
        }),
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------- cache
  static void clearCache() => _httpClient.clearCache();
  static Map<String, dynamic> getCacheStats() => _httpClient.getCacheStats();
}
