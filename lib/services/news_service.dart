import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/story_card.dart';
import '../models/stats_response.dart';
import '../core/constants.dart';

/// Low-level HTTP client for the news_feed backend.
/// Provider layer lives in NewsProvider — do not store state here.
class NewsService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  // SSE
  StreamController<List<StoryCard>>? _sseController;
  http.Client? _sseClient;

  NewsService({
    String? baseUrl,
    String? apiKey,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? AppConstants.baseUrl,
        _apiKey = apiKey ?? AppConstants.apiKey,
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'X-API-Key': _apiKey,
        'Content-Type': 'application/json',
      };

  // ── Stories ────────────────────────────────────────────────────

  /// Fetches today's stories, filtered by user timezone and selected topics.
  Future<Map<String, dynamic>> fetchToday({
    int page = 1,
    int perPage = 20,
    String tz = 'UTC',
    List<String> topics = const [],
  }) async {
    final queryParams = {
      'page': '$page',
      'per_page': '$perPage',
      'tz': tz,
      if (topics.isNotEmpty) 'topics': topics.join(','),
    };
    final uri = Uri.parse('$_baseUrl/v1/today').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('fetchToday failed: ${response.statusCode}');
  }

  /// GET /v1/today/stats — read/unread/total counts for today.
  Future<StatsResponse> fetchStats({String tz = 'UTC'}) async {
    final uri = Uri.parse('$_baseUrl/v1/today/stats')
        .replace(queryParameters: {'tz': tz});
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return StatsResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('fetchStats failed: ${response.statusCode}');
  }

  // ── SSE: /v1/today/updates ─────────────────────────────────────

  /// Returns a broadcast stream of new story lists from the SSE endpoint.
  /// The caller (NewsProvider) subscribes on foreground resume and
  /// cancels on background pause.
  Stream<List<StoryCard>> subscribeToUpdates({
    required DateTime since,
    String tz = 'UTC',
  }) {
    _sseController?.close();
    _sseController = StreamController<List<StoryCard>>.broadcast();

    final uri = Uri.parse('$_baseUrl/v1/today/updates').replace(
      queryParameters: {
        'since': since.toUtc().toIso8601String(),
        'tz': tz,
      },
    );

    _sseClient = http.Client();
    final request = http.Request('GET', uri);
    request.headers.addAll(_headers);

    _sseClient!.send(request).then((streamedResponse) {
      streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            try {
              final payload =
                  json.decode(line.substring(6)) as Map<String, dynamic>;
              final rawStories = payload['stories'] as List<dynamic>? ?? [];
              final stories = rawStories
                  .map((s) => StoryCard.fromJson(s as Map<String, dynamic>))
                  .toList();
              if (stories.isNotEmpty) {
                _sseController?.add(stories);
              }
            } catch (e) {
              debugPrint('SSE parse error: $e');
            }
          }
        },
        onError: (e) => debugPrint('SSE stream error: $e'),
        onDone: () => debugPrint('SSE stream closed'),
        cancelOnError: false,
      );
    }).catchError((e) {
      debugPrint('SSE connect error: $e');
    });

    return _sseController!.stream;
  }

  void cancelSseSubscription() {
    _sseClient?.close();
    _sseController?.close();
    _sseClient = null;
    _sseController = null;
  }

  // ── Story interactions ─────────────────────────────────────────

  Future<void> markRead(String storyId) async {
    await _client.post(
      Uri.parse('$_baseUrl/v1/stories/$storyId/read'),
      headers: _headers,
    );
  }

  Future<void> toggleLike(String storyId) async {
    await _client.post(
      Uri.parse('$_baseUrl/v1/stories/$storyId/like'),
      headers: _headers,
    );
  }

  Future<void> toggleBookmark(String storyId) async {
    await _client.post(
      Uri.parse('$_baseUrl/v1/stories/$storyId/bookmark'),
      headers: _headers,
    );
  }

  Future<List<StoryCard>> fetchBookmarked() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/v1/stories/bookmarked'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => StoryCard.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('fetchBookmarked failed: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> searchStories(String query) async {
    final uri = Uri.parse('$_baseUrl/v1/today/search')
        .replace(queryParameters: {'q': query});
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(body['stories'] ?? []);
    }
    return [];
  }

  void dispose() {
    cancelSseSubscription();
    _client.close();
  }
}
