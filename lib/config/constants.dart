import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppConfig — single source of truth for every constant used in the UI.
// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------- API
  static const String apiBaseUrl = 'https://news-feed-yip1.onrender.com';
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'kiezlink-dev-key-2024',
  );

  /// Legacy single-URL helpers kept for backward compatibility.
  static const String apiUrlAndroid =
      '$apiBaseUrl/v1/today?page=1&per_page=20';
  static const String apiUrlDevices =
      '$apiBaseUrl/v1/today?page=1&per_page=20';

  // ---------------------------------------------------------------- HTTP
  static const int httpStatusOk = 200;
  static const Duration cacheTTL = Duration(minutes: 5);
  static const Duration httpTimeout = Duration(seconds: 15);

  // ---------------------------------------------------------------- feed
  static const int defaultPerPage = 20;
  static const int maxSearchResults = 50;
  static const int maxDots = 20;

  // ---------------------------------------------------------------- timings (ms)
  static const int swipeHintDelayMs = 1500;
  static const int readDelayMs = 3000;

  // ---------------------------------------------------------------- animation durations
  static const Duration animationDurationFast   = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 350);
  static const Duration animationDurationSlow   = Duration(milliseconds: 600);

  // ---------------------------------------------------------------- colours
  static const Color primaryColor     = Color(0xFFFFC107); // amber / kiezlink gold
  static const Color backgroundColor  = Color(0xFF121212);
  static const Color surfaceColor     = Color(0xFF1E1E1E);
  static const Color errorColor       = Color(0xFFCF6679);
  static const Color successColor     = Color(0xFF66BB6A);

  // ---------------------------------------------------------------- shimmer
  static const Color shimmerBaseColor      = Color(0xFF2A2A2A);
  static const Color shimmerHighlightColor = Color(0xFF3D3D3D);

  // ---------------------------------------------------------------- font sizes
  static const double fontSizeXSmall  = 10.0;
  static const double fontSizeSmall   = 12.0;
  static const double fontSizeMedium  = 14.0;
  static const double fontSizeLarge   = 16.0;
  static const double fontSizeXLarge  = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeHuge    = 22.0;
  static const double fontSizeGiant   = 26.0;

  // ---------------------------------------------------------------- icon sizes
  static const double iconSizeSmall  = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge  = 24.0;
  static const double iconSizeXLarge = 32.0;
  static const double iconSizeHuge   = 48.0;
  static const double iconSizeGiant  = 64.0;

  // ---------------------------------------------------------------- padding / spacing
  static const double paddingSmall   = 8.0;
  static const double paddingMedium  = 12.0;
  static const double paddingLarge   = 16.0;
  static const double paddingXLarge  = 24.0;

  // ---------------------------------------------------------------- border radii
  static const double borderRadiusSmall  = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge  = 20.0;

  // ---------------------------------------------------------------- layout fractions / positions
  static const double sideMenuWidthFraction      = 0.80;
  static const double progressDotsTopFraction    = 0.04;
  static const double progressDotsBottomFraction = 0.04;
  static const double swipeHintBottomPosition    = 100.0;

  // ---------------------------------------------------------------- image preview (side menu avatar)
  static const double imagePreviewWidth  = 56.0;
  static const double imagePreviewHeight = 56.0;

  // ---------------------------------------------------------------- text / labels
  static const String textAppTitle            = 'Kiezlink';
  static const String textSearchNews          = 'Search news…';
  static const String textRead                = 'Read';
  static const String textMore                = 'More';
  static const String textLess                = 'Less';
  static const String textFullStory           = 'Full story';
  static const String messageSwipeForNext     = 'Swipe for next story';
  static const String errorCancel             = 'Cancel';
  static const String errorCouldNotLoadNews   = 'Could not load news';
  static const String errorTryAgain           = 'Try again';
  static const String errorNoStoriesFound     = 'No stories found';
  static const String errorTryDifferentSearch = 'Try a different search term';
  static const String errorUrlNotAvailable    = 'URL not available';
  static const String errorCouldNotOpenUrl    = 'Could not open URL';
  static const String errorFailedToOpenUrl    = 'Failed to open URL';

  // ---------------------------------------------------------------- stats labels
  static const String textReadCount   = 'Read';
  static const String textUnreadCount = 'Unread';
  static const String textTotalCount  = 'Total';

  // ---------------------------------------------------------------- side menu labels
  static const String textMyFeed        = 'My Feed';
  static const String textTrendingNow   = 'Trending Now';
  static const String textTopStories    = 'Top Stories';

  // ---------------------------------------------------------------- side menu limits
  static const int trendingItemsCount  = 3;
  static const int topStoriesItemsCount = 3;

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
  static String topicToApiValue(String displayLabel) =>
      displayLabel.toLowerCase();

  static const double minimal = 0.02;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppOpacity — named opacity constants to replace magic numbers.
// ─────────────────────────────────────────────────────────────────────────────
class AppOpacity {
  AppOpacity._();

  static const double trace   = 0.05;
  static const double veryLow = 0.10;
  static const double low     = 0.30;
  static const double medium  = 0.55;
  static const double high    = 0.80;
  static const double full    = 1.00;
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientStops — reusable gradient stop lists.
// ─────────────────────────────────────────────────────────────────────────────
class GradientStops {
  GradientStops._();

  /// Card overlay: transparent at top, opaque at the bottom text area.
  static const List<double> cardGradient = [0.0, 0.45, 1.0];
}
