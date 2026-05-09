import 'package:intl/intl.dart';

/// Utility class for date and time operations
class DateTimeUtils {
  /// Format DateTime to human-readable "time ago" format
  /// e.g., "2 hours ago", "just now", "yesterday"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      if (days == 1) return 'yesterday';
      return '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }

  /// Format DateTime to readable date format
  /// e.g., "Jan 15, 2024"
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Format DateTime to readable date and time format
  /// e.g., "Jan 15, 2024 at 2:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
  }

  /// Format DateTime to time only
  /// e.g., "2:30 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Check if a DateTime is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if a DateTime is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Safe DateTime parsing with fallback to current time
  static DateTime parseDateTime(dynamic dateStr, {DateTime? fallback}) {
    if (dateStr == null || dateStr.toString().isEmpty) {
      return fallback ?? DateTime.now();
    }
    try {
      if (dateStr is DateTime) return dateStr;
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return fallback ?? DateTime.now();
    }
  }
}

/// String utility class
class StringUtils {
  /// Safely truncate string to max length with ellipsis
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Check if string is valid URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  /// Safely extract domain from URL
  static String getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Normalize search query
  static String normalizeSearchQuery(String query) {
    return query.trim().toLowerCase();
  }

  /// Check if search query is valid
  static bool isValidSearchQuery(String query) {
    final normalized = normalizeSearchQuery(query);
    return normalized.isNotEmpty && normalized.length >= 1;
  }
}

/// Validation utility class
class ValidationUtils {
  /// Validate if news item has required fields
  static bool isValidNewsItem(Map<String, dynamic> item) {
    return item.containsKey('id') &&
        item['id'] != null &&
        item['id'].toString().isNotEmpty &&
        item.containsKey('title') &&
        item['title'] != null &&
        item['title'].toString().isNotEmpty;
  }

  /// Validate API response structure
  static bool isValidApiResponse(Map<String, dynamic> data) {
    return data.containsKey('stories') && data['stories'] is List;
  }

  /// Validate image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return StringUtils.isValidUrl(url);
  }
}
