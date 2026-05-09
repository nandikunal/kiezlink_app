import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// HTTP Client wrapper with caching and request handling
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  
  final Map<String, CachedResponse> _cache = {};
  
  Duration _cacheDuration = const Duration(minutes: 5);
  
  factory HttpClientService({Duration cacheDuration = const Duration(minutes: 5)}) {
    _instance._cacheDuration = cacheDuration;
    return _instance;
  }

  HttpClientService._internal() : _cacheDuration = const Duration(minutes: 5);

  /// Get with caching support
  Future<http.Response> getCached(
    String url, {
    Map<String, String>? headers,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache && _cache.containsKey(url)) {
      final cached = _cache[url];
      if (cached != null && !cached.isExpired) {
        developer.log('Using cached response for: $url', name: 'HttpClient');
        return cached.response;
      } else {
        _cache.remove(url);
      }
    }

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 12));

      // Cache successful responses
      if (response.statusCode == 200 && useCache) {
        _cache[url] = CachedResponse(response, DateTime.now());
        developer.log('Cached response for: $url', name: 'HttpClient');
      }

      return response;
    } catch (e) {
      developer.log('HTTP Error: $e', name: 'HttpClient');
      rethrow;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    developer.log('Cache cleared', name: 'HttpClient');
  }

  /// Clear specific URL from cache
  void clearCacheFor(String url) {
    _cache.remove(url);
  }

  /// Get cache stats
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedUrls': _cache.length,
      'totalSize': _cache.values.fold(0, (sum, item) => sum + item.response.bodyBytes.length),
    };
  }
}

/// Cached response wrapper
class CachedResponse {
  final http.Response response;
  final DateTime cachedAt;
  final Duration ttl;

  CachedResponse(
    this.response,
    this.cachedAt, {
    this.ttl = const Duration(minutes: 5),
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
}
