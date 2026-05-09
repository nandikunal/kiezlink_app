import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/news_item.dart';
import '../utils/utils.dart';
import 'http_client_service.dart';

class RssService {
  static final HttpClientService _httpClient = HttpClientService(cacheDuration: const Duration(minutes: 5));
  
  // Use this URL for physical devices - update with your actual server IP
  // For Android emulator: 10.0.2.2
  // For iOS simulator: localhost or 127.0.0.1
  // For physical devices: your-machine-ip:8000
  static String _getApiUrl() {
    // You can implement platform detection here if needed
    return AppConfig.apiUrlAndroid;
  }

  static Future<List<NewsItem>> fetchAll() async {
    try {
      final url = _getApiUrl();
      developer.log('Fetching news from: $url', name: 'RssService');

      final response = await _httpClient.getCached(
        url,
        headers: {
          'accept': 'application/json',
          'X-API-Key': AppConfig.apiKey,
        },
      );

      developer.log('API Response Status: ${response.statusCode}', name: 'RssService');

      if (response.statusCode != AppConfig.httpStatusOk) {
        developer.log('API Error: ${response.statusCode} - ${response.body}', name: 'RssService');
        return [];
      }

      if (response.body.isEmpty) {
        developer.log('Empty API response', name: 'RssService');
        return [];
      }

      // Log first 200 chars of response
      final bodyPreview = response.body.length > 200 
          ? response.body.substring(0, 200) 
          : response.body;
      developer.log('Response body: $bodyPreview', name: 'RssService');

      final Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        developer.log('JSON decode error: $e', name: 'RssService');
        return [];
      }

      if (!ValidationUtils.isValidApiResponse(data)) {
        developer.log('Invalid API response structure', name: 'RssService');
        return [];
      }

      final List<dynamic> stories = data['stories'] ?? [];
      developer.log('Found ${stories.length} stories', name: 'RssService');

      final items = <NewsItem>[];

      for (final story in stories) {
        try {
          if (!ValidationUtils.isValidNewsItem(story as Map<String, dynamic>)) {
            developer.log('Skipping invalid story item', name: 'RssService');
            continue;
          }

          // Safe DateTime parsing with fallback
          final publishedAt = DateTimeUtils.parseDateTime(story['published_at']);

          final newsItem = NewsItem(
            id: (story['id'] ?? '').toString(),
            title: (story['title'] ?? 'No Title').toString().trim(),
            summary: (story['short_content'] ?? '').toString().trim(),
            content: (story['short_content'] ?? '').toString().trim(),
            imageUrl: (story['image_url'] ?? '').toString().trim(),
            source: (story['source'] ?? 'Unknown').toString().trim(),
            sourceUrl: (story['link'] ?? '').toString().trim(),
            publishedAt: publishedAt,
            category: (story['category'] ?? 'today').toString().trim(),
            tag: (story['topic'] ?? 'general').toString().trim(),
            eventDate: null,
            isRead: story['read'] as bool? ?? false,
            isLiked: story['liked'] as bool? ?? false,
            isBookmarked: story['bookmarked'] as bool? ?? false,
          );
          items.add(newsItem);
        } catch (e) {
          developer.log('Error parsing story: $e', name: 'RssService');
          continue;
        }
      }

      // Sort by date descending
      try {
        items.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      } catch (e) {
        developer.log('Error sorting items: $e', name: 'RssService');
      }

      developer.log('Successfully parsed ${items.length} items', name: 'RssService');
      return items;
    } on http.ClientException catch (e) {
      developer.log('Network error: $e', name: 'RssService');
      return [];
    } catch (e) {
      developer.log('Unexpected error in fetchAll: $e', name: 'RssService');
      return [];
    }
  }

  /// Clear HTTP cache
  static void clearCache() {
    _httpClient.clearCache();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return _httpClient.getCacheStats();
  }
}
