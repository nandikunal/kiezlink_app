import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/rss_service.dart';
import '../utils/utils.dart';

enum FeedState { idle, loading, loaded, error }

class NewsProvider extends ChangeNotifier {
  List<NewsItem> _allItems = [];
  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isSearchActive = false;
  FeedState _state = FeedState.idle;
  String _errorMessage = '';
  Timer? _searchDebounceTimer;

  FeedState get state => _state;
  String get errorMessage => _errorMessage;
  List<NewsItem> get allItems => _allItems;
  int get currentIndex => _currentIndex;
  bool get isSearchActive => _isSearchActive;
  String get searchQuery => _searchQuery;
  int get readCount => _allItems.where((i) => i.isRead).length;
  int get unreadCount => _allItems.where((i) => !i.isRead).length;
  int get totalCount => _allItems.length;

  /// Filtered items based on search query
  List<NewsItem> get filteredItems {
    if (_searchQuery.isEmpty) return _allItems;
    final q = StringUtils.normalizeSearchQuery(_searchQuery);
    if (!StringUtils.isValidSearchQuery(_searchQuery)) return _allItems;

    return _allItems.where((i) {
      final titleMatch = i.title.toLowerCase().contains(q);
      final summaryMatch = i.summary.toLowerCase().contains(q);
      final tagMatch = i.tag.toLowerCase().contains(q);
      final sourceMatch = i.source.toLowerCase().contains(q);
      return titleMatch || summaryMatch || tagMatch || sourceMatch;
    }).toList();
  }

  /// Load feeds from API
  Future<void> loadFeeds() async {
    if (_state == FeedState.loading) return; // Prevent duplicate requests
    
    _state = FeedState.loading;
    _errorMessage = '';
    _currentIndex = 0;
    notifyListeners();

    try {
      developer.log('Loading feeds...', name: 'NewsProvider');
      final items = await RssService.fetchAll();
      
      if (items.isEmpty) {
        _state = FeedState.error;
        _errorMessage = 'No articles found. Check if the API server is running.';
        developer.log('No items loaded', name: 'NewsProvider');
      } else {
        _allItems = items;
        _state = FeedState.loaded;
        developer.log('Loaded ${items.length} items', name: 'NewsProvider');
      }
    } catch (e) {
      _state = FeedState.error;
      _errorMessage = 'Failed to load news: $e';
      developer.log('Error loading feeds: $e', name: 'NewsProvider');
    }
    notifyListeners();
  }

  /// Set search query with debouncing to avoid excessive filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentIndex = 0;

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Only notify after user stops typing (300ms)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  /// Toggle search mode
  void toggleSearch() {
    _isSearchActive = !_isSearchActive;
    if (!_isSearchActive) {
      _searchQuery = '';
      _searchDebounceTimer?.cancel();
      _currentIndex = 0;
    }
    notifyListeners();
  }

  /// Set current index for pagination
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Mark item as read (optimized with early return)
  void markAsRead(String id) {
    try {
      final idx = _allItems.indexWhere((i) => i.id == id);
      if (idx != -1 && !_allItems[idx].isRead) {
        _allItems[idx].isRead = true;
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error marking as read: $e', name: 'NewsProvider');
    }
  }

  /// Toggle like status
  void toggleLike(String id) {
    try {
      final idx = _allItems.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _allItems[idx].isLiked = !_allItems[idx].isLiked;
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error toggling like: $e', name: 'NewsProvider');
    }
  }

  /// Toggle bookmark status
  void toggleBookmark(String id) {
    try {
      final idx = _allItems.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _allItems[idx].isBookmarked = !_allItems[idx].isBookmarked;
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error toggling bookmark: $e', name: 'NewsProvider');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    _currentIndex = 0;
    _searchQuery = '';
    _isSearchActive = false;
    _searchDebounceTimer?.cancel();
    await loadFeeds();
  }

  /// Clear cache
  void clearCache() {
    RssService.clearCache();
  }

  /// Get cache stats
  Map<String, dynamic> getCacheStats() {
    return RssService.getCacheStats();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
