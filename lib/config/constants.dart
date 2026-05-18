import 'package:flutter/material.dart';

/// Application Configuration Constants
class AppConfig {
  // API Configuration
  static const String _apiBase = 'https://news-feed-yip1.onrender.com';
  static const String apiUrlAndroid = '$_apiBase/v1/today?page=1&per_page=20';
  static const String apiUrlDevices = '$_apiBase/v1/today?page=1&per_page=20';
  static const String apiStatsUrl = '$_apiBase/v1/today/stats';
  static const String apiUpdatesUrl = '$_apiBase/v1/today/updates';
  static const String apiKey = 'VJvcqEmReRu4cIUq4CKBUeDD0fK6u7l5qKBQDmbho8w';
  static const int requestTimeout = 12; // seconds
  static const int readDelayMs = 1500; // milliseconds
  static const int swipeHintDelayMs = 3000; // milliseconds
  static const int ssePollingIntervalSeconds = 30;

  // UI Constants - Colors
  static const Color primaryColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color backgroundColor = Colors.black;
  static const Color surfaceColor = Color(0xFF0F0F0F);
  static const Color shimmerBaseColor = Color(0xFF1C1C1E);
  static const Color shimmerHighlightColor = Color(0xFF2C2C2E);

  // UI Constants - Dimensions
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 24.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;

  // UI Constants - Icon Sizes
  static const double iconSizeSmall = 14.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 22.0;
  static const double iconSizeXLarge = 32.0;
  static const double iconSizeHuge = 64.0;
  static const double iconSizeGiant = 80.0;

  // UI Constants - Font Sizes
  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 11.0;
  static const double fontSizeMedium = 12.0;
  static const double fontSizeLarge = 14.0;
  static const double fontSizeXLarge = 16.0;
  static const double fontSizeXXLarge = 18.0;
  static const double fontSizeHuge = 20.0;
  static const double fontSizeGiant = 21.0;

  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 800);

  // News List Configuration
  static const int maxDots = 8;
  static const int trendingItemsCount = 4;
  static const int topStoriesItemsCount = 4;

  // Topics Configuration
  static const List<String> defaultTopics = [
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

  static const List<String> activeTopicsByDefault = [
    'Technology',
    'Sports',
    'Berlin',
    'Germany',
  ];

  // Topic → API tag mapping (lowercased for matching story.tag)
  static const Map<String, List<String>> topicTagMap = {
    'Technology': ['tech', 'technology'],
    'Sports': ['sports', 'sport'],
    'Health': ['health'],
    'Economy': ['finance', 'economy', 'business'],
    'Culture': ['entertainment', 'culture', 'arts'],
    'Environment': ['environment', 'climate', 'science'],
    'Transport': ['transport', 'traffic'],
    'Politics': ['politics'],
    'Berlin': ['local', 'berlin'],
    'Germany': ['germany', 'general'],
    'News': ['general', 'news'],
  };

  // Error Messages
  static const String errorNoArticles =
      'No articles found. Check if the API server is running at http://127.0.0.1:8000';
  static const String errorFailedToLoad = 'Failed to load news';
  static const String errorCouldNotLoadNews = 'Could not load news';
  static const String errorUrlNotAvailable = 'URL not available';
  static const String errorCouldNotOpenUrl = 'Could not open URL';
  static const String errorFailedToOpenUrl = 'Error: Failed to open URL';
  static const String errorNoStoriesFound = 'No stories found';
  static const String errorTryDifferentSearch = 'Try a different search term';
  static const String errorTryAgain = 'Try Again';
  static const String errorCancel = 'Cancel';

  // Success Messages
  static const String messageSwipeForNext = 'Swipe up for next story';
  static const String messageNewStories = 'new stories available';

  // UI Text
  static const String textReadCount = 'Read';
  static const String textUnreadCount = 'Unread';
  static const String textTotalCount = 'Total';
  static const String textMyFeed = 'My Feed';
  static const String textTrendingNow = 'Trending Now';
  static const String textTopStories = 'Top Stories';
  static const String textSearchNews = 'Search news...';
  static const String textAppTitle = 'Kiezlink';
  static const String textBerlinReader = 'Berliner Leser';
  static const String textBerlinLocation = 'Berlin, DE';
  static const String textRead = 'READ';
  static const String textMore = 'More';
  static const String textLess = 'Less';
  static const String textFullStory = 'Full Story';
  static const String textAllTopicsLoaded =
      'All topics are loaded. Pull to refresh for new stories.';

  // Image Constants
  static const double imagePreviewWidth = 52.0;
  static const double imagePreviewHeight = 52.0;
  static const double imageThumbnailRadius = 8.0;

  // Menu Configuration
  static const double sideMenuWidthFraction = 0.82;
  static const double progressDotsTopFraction = 0.3;
  static const double progressDotsBottomFraction = 0.2;
  static const double swipeHintBottomPosition = 160.0;

  // HTTP Status Codes
  static const int httpStatusOk = 200;
}

/// AppOpacity Constants
class AppOpacity {
  static const double low = 0.4;
  static const double medium = 0.6;
  static const double high = 0.87;
  static const double veryLow = 0.2;
  static const double trace = 0.08;
  static const double minimal = 0.04;
}

/// Gradient Constants
class GradientStops {
  static const List<double> cardGradient = [0.0, 0.3, 0.6, 1.0];
  static const List<double> navGradient = [0.0, 1.0];
}

/// Layout Constants for responsive design
class LayoutConstants {
  static const double minScreenWidth = 320.0;
  static const double maxScreenWidth = 1200.0;
  static const double tabletBreakpoint = 600.0;
}
