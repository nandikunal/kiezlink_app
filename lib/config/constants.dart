class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------- API
  static const String apiBaseUrl = 'https://news-feed-yip1.onrender.com';
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'kiezlink-dev-key-2024',
  );

  // Legacy single-URL helpers kept for backward compatibility
  static const String apiUrlAndroid =
      '$apiBaseUrl/v1/today?page=1&per_page=20';
  static const String apiUrlDevices =
      '$apiBaseUrl/v1/today?page=1&per_page=20';

  // ---------------------------------------------------------------- timings
  static const int httpStatusOk = 200;
  static const Duration cacheTTL = Duration(minutes: 5);
  static const Duration httpTimeout = Duration(seconds: 15);

  // ---------------------------------------------------------------- feed
  static const int defaultPerPage = 20;
  static const int maxSearchResults = 50;

  // ---------------------------------------------------------------- topics
  /// All topic tags available in the My Feed drawer filter.
  static const List<String> allTopics = [
    'Technology',
    'Sports',
    'Health',
    'Economy',
    'Culture',
    'Environment',
    'Transport',
    'Politics',
    'Berlin',
    'Germany',
    'News',
  ];

  /// Maps display label to the backend TopicLabel enum value.
  static String topicToApiValue(String displayLabel) {
    return displayLabel.toLowerCase();
  }
}
