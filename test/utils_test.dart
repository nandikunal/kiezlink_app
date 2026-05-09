import 'package:flutter_test/flutter_test.dart';
import 'package:kiezlink_app/utils/utils.dart';

void main() {
  group('DateTimeUtils Tests', () {
    test('timeAgo returns "just now" for recent times', () {
      final now = DateTime.now();
      final justNow = now.subtract(const Duration(seconds: 30));
      expect(DateTimeUtils.timeAgo(justNow), 'just now');
    });

    test('timeAgo returns correct minute format', () {
      final now = DateTime.now();
      final fifteenMinutesAgo = now.subtract(const Duration(minutes: 15));
      expect(DateTimeUtils.timeAgo(fifteenMinutesAgo), '15 minutes ago');
    });

    test('timeAgo returns correct hour format', () {
      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      expect(DateTimeUtils.timeAgo(twoHoursAgo), '2 hours ago');
    });

    test('timeAgo returns correct day format', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      expect(DateTimeUtils.timeAgo(threeDaysAgo), '3 days ago');
    });

    test('timeAgo returns "yesterday" for yesterday', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateTimeUtils.timeAgo(yesterday), 'yesterday');
    });

    test('formatDate formats correctly', () {
      final date = DateTime(2024, 1, 15);
      final formatted = DateTimeUtils.formatDate(date);
      expect(formatted.contains('15'), true);
      expect(formatted.contains('2024'), true);
    });

    test('isToday detects today correctly', () {
      final now = DateTime.now();
      expect(DateTimeUtils.isToday(now), true);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateTimeUtils.isToday(yesterday), false);
    });

    test('parseDateTime handles null safely', () {
      final result = DateTimeUtils.parseDateTime(null);
      expect(result.year, DateTime.now().year);
    });

    test('parseDateTime parses valid string', () {
      const dateStr = '2024-01-15T10:30:00Z';
      final result = DateTimeUtils.parseDateTime(dateStr);
      expect(result.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });
  });

  group('StringUtils Tests', () {
    test('truncate shortens long strings', () {
      const longText = 'This is a very long string that needs truncation';
      final truncated = StringUtils.truncate(longText, 20);
      expect(truncated.length, lessThanOrEqualTo(20));
      expect(truncated.endsWith('...'), true);
    });

    test('truncate does not truncate short strings', () {
      const shortText = 'Short';
      const maxLength = 20;
      final result = StringUtils.truncate(shortText, maxLength);
      expect(result, shortText);
    });

    test('isValidUrl returns true for valid URLs', () {
      expect(StringUtils.isValidUrl('https://example.com'), true);
      expect(StringUtils.isValidUrl('http://example.com'), true);
    });

    test('isValidUrl returns false for invalid URLs', () {
      expect(StringUtils.isValidUrl('not a url'), false);
      expect(StringUtils.isValidUrl('example.com'), false);
      expect(StringUtils.isValidUrl(''), false);
    });

    test('getDomainFromUrl extracts domain correctly', () {
      const url = 'https://www.example.com/path';
      final domain = StringUtils.getDomainFromUrl(url);
      expect(domain.contains('example.com'), true);
    });

    test('normalizeSearchQuery trims and lowercases', () {
      const query = '  TeSt QuErY  ';
      final normalized = StringUtils.normalizeSearchQuery(query);
      expect(normalized, 'test query');
    });

    test('isValidSearchQuery returns false for empty', () {
      expect(StringUtils.isValidSearchQuery(''), false);
      expect(StringUtils.isValidSearchQuery('   '), false);
    });

    test('isValidSearchQuery returns true for valid queries', () {
      expect(StringUtils.isValidSearchQuery('a'), true);
      expect(StringUtils.isValidSearchQuery('test'), true);
    });
  });

  group('ValidationUtils Tests', () {
    test('isValidNewsItem returns true for valid item', () {
      final validItem = {
        'id': '123',
        'title': 'Test Title',
      };
      expect(ValidationUtils.isValidNewsItem(validItem), true);
    });

    test('isValidNewsItem returns false for missing id', () {
      final invalidItem = {
        'title': 'Test Title',
      };
      expect(ValidationUtils.isValidNewsItem(invalidItem), false);
    });

    test('isValidNewsItem returns false for empty id', () {
      final invalidItem = {
        'id': '',
        'title': 'Test Title',
      };
      expect(ValidationUtils.isValidNewsItem(invalidItem), false);
    });

    test('isValidApiResponse returns true for valid response', () {
      final validResponse = {
        'stories': [
          {'id': '1', 'title': 'Story 1'},
        ],
      };
      expect(ValidationUtils.isValidApiResponse(validResponse), true);
    });

    test('isValidApiResponse returns false for missing stories', () {
      final invalidResponse = {'data': []};
      expect(ValidationUtils.isValidApiResponse(invalidResponse), false);
    });

    test('isValidImageUrl returns false for empty URL', () {
      expect(ValidationUtils.isValidImageUrl(''), false);
      expect(ValidationUtils.isValidImageUrl(null), false);
    });

    test('isValidImageUrl returns true for valid image URLs', () {
      expect(ValidationUtils.isValidImageUrl('https://example.com/image.jpg'), true);
      expect(ValidationUtils.isValidImageUrl('http://example.com/image.png'), true);
    });

    test('isValidImageUrl returns false for invalid URLs', () {
      expect(ValidationUtils.isValidImageUrl('not-a-url'), false);
      expect(ValidationUtils.isValidImageUrl('example.com/image.jpg'), false);
    });
  });
}
