import 'package:flutter_test/flutter_test.dart';
import 'package:kiezlink_app/data/news_provider.dart';
import 'package:kiezlink_app/models/news_item.dart';

void main() {
  group('NewsProvider Tests', () {
    late NewsProvider provider;

    setUp(() {
      provider = NewsProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial state is idle', () {
      expect(provider.state, FeedState.idle);
      expect(provider.allItems, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.isSearchActive, false);
    });

    test('Read/Unread counts initialize to zero', () {
      expect(provider.readCount, 0);
      expect(provider.unreadCount, 0);
      expect(provider.totalCount, 0);
    });

    test('Setting search query updates filtered items', () {
      // Add test items
      final items = [
        NewsItem(
          id: '1',
          title: 'Flutter News',
          summary: 'New Flutter release',
          content: 'Content about Flutter',
          imageUrl: '',
          source: 'Test Source',
          sourceUrl: '',
          publishedAt: DateTime.now(),
          category: 'tech',
          tag: 'flutter',
        ),
        NewsItem(
          id: '2',
          title: 'Dart Updates',
          summary: 'Dart language improvements',
          content: 'Content about Dart',
          imageUrl: '',
          source: 'Test Source',
          sourceUrl: '',
          publishedAt: DateTime.now(),
          category: 'tech',
          tag: 'dart',
        ),
      ];
      
      // Mock setting items (normally done by loadFeeds)
      provider._allItems = items;
      
      provider.setSearchQuery('flutter');
      expect(provider.searchQuery, 'flutter');
    });

    test('Marking item as read updates read count', () {
      final item = NewsItem(
        id: '1',
        title: 'Test',
        summary: 'Test',
        content: 'Test',
        imageUrl: '',
        source: 'Test',
        sourceUrl: '',
        publishedAt: DateTime.now(),
        category: 'test',
        tag: 'test',
      );
      
      provider._allItems = [item];
      
      expect(provider.readCount, 0);
      expect(provider.unreadCount, 1);
      
      provider.markAsRead('1');
      
      expect(provider.readCount, 1);
      expect(provider.unreadCount, 0);
    });

    test('Toggling like updates isLiked status', () {
      final item = NewsItem(
        id: '1',
        title: 'Test',
        summary: 'Test',
        content: 'Test',
        imageUrl: '',
        source: 'Test',
        sourceUrl: '',
        publishedAt: DateTime.now(),
        category: 'test',
        tag: 'test',
        isLiked: false,
      );
      
      provider._allItems = [item];
      
      expect(item.isLiked, false);
      
      provider.toggleLike('1');
      
      expect(item.isLiked, true);
      
      provider.toggleLike('1');
      
      expect(item.isLiked, false);
    });

    test('Toggling bookmark updates isBookmarked status', () {
      final item = NewsItem(
        id: '1',
        title: 'Test',
        summary: 'Test',
        content: 'Test',
        imageUrl: '',
        source: 'Test',
        sourceUrl: '',
        publishedAt: DateTime.now(),
        category: 'test',
        tag: 'test',
        isBookmarked: false,
      );
      
      provider._allItems = [item];
      
      expect(item.isBookmarked, false);
      
      provider.toggleBookmark('1');
      
      expect(item.isBookmarked, true);
    });

    test('Setting current index updates index', () {
      expect(provider.currentIndex, 0);
      
      provider.setCurrentIndex(5);
      
      expect(provider.currentIndex, 5);
    });

    test('Toggle search toggles search active state', () {
      expect(provider.isSearchActive, false);
      
      provider.toggleSearch();
      
      expect(provider.isSearchActive, true);
      
      provider.toggleSearch();
      
      expect(provider.isSearchActive, false);
    });

    test('Refresh resets search and loads feeds', () {
      provider._searchQuery = 'test';
      provider._currentIndex = 5;
      provider._isSearchActive = true;
      
      // Since API call will fail, we just verify the state reset
      // In a real test, we'd mock the RssService
      provider.refresh();
      
      // These are reset before API call
      expect(provider.searchQuery, isEmpty);
      expect(provider.currentIndex, 0);
      expect(provider.isSearchActive, false);
    });

    test('Filtered items empty when no items', () {
      provider._allItems = [];
      expect(provider.filteredItems, isEmpty);
    });

    test('Filtered items returns all when search empty', () {
      final items = [
        NewsItem(
          id: '1',
          title: 'Test 1',
          summary: 'Test',
          content: 'Test',
          imageUrl: '',
          source: 'Test',
          sourceUrl: '',
          publishedAt: DateTime.now(),
          category: 'test',
          tag: 'test',
        ),
        NewsItem(
          id: '2',
          title: 'Test 2',
          summary: 'Test',
          content: 'Test',
          imageUrl: '',
          source: 'Test',
          sourceUrl: '',
          publishedAt: DateTime.now(),
          category: 'test',
          tag: 'test',
        ),
      ];
      
      provider._allItems = items;
      provider._searchQuery = '';
      
      expect(provider.filteredItems.length, 2);
    });
  });
}
