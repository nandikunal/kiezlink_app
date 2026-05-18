import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/rss_service.dart';
import '../services/stats_service.dart';
import '../services/prefs_service.dart';
import '../config/constants.dart';
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

  // ── Stats from /v1/today/stats ────────────────────────────────────────────
  FeedStats _stats = FeedStats.empty();
  FeedStats get stats => _stats;

  // ── Topic filter ──────────────────────────────────────────────────────────
  List<String> _selectedTopics = [];
  List<String> get selectedTopics => _selectedTopics;

  // ── New-story banner ───────────────────────────────────────────────────────
  int _newStoriesCount = 0;
  int get newStoriesCount => _newStoriesCount;
  void clearNewStoriesCount() {
    _newStoriesCount = 0;
    notifyListeners();
  }

  void setNewStoriesCount(int count) {
    _newStoriesCount = count;
    notifyListeners();
  }

  FeedState get state => _state;
  String get errorMessage => _errorMessage;
  List<NewsItem> get allItems => _allItems;
  int get currentIndex => _currentIndex;
  bool get isSearchActive => _isSearchActive;
  String get searchQuery => _searchQuery;

  // Local counts (used as fallback before stats API responds)
  int get readCount => _stats.read > 0 ? _stats.read : _allItems.where((i) => i.isRead).length;
  int get unreadCount => _stats.unread > 0 ? _stats.unread : _allItems.where((i) => !i.isRead).length;
  int get totalCount => _stats.total > 0 ? _stats.total : _allItems.length;

  /// Items after applying topic filter and search query
  List<NewsItem> get filteredItems {
    List<NewsItem> base = _allItems;

    // Apply topic filter
    if (_selectedTopics.isNotEmpty &&
        _selectedTopics.length < AppConfig.defaultTopics.length) {
      final matchTags = _selectedTopics
          .expand((t) => AppConfig.topicTagMap[t] ?? [t.toLowerCase()])
          .toSet();
      base = base
          .where((i) => matchTags.contains(i.tag.toLowerCase()))
          .toList();
    }

    // Apply search
    if (_searchQuery.isEmpty) return base;
    final q = StringUtils.normalizeSearchQuery(_searchQuery);
    if (!StringUtils.isValidSearchQuery(_searchQuery)) return base;
    return base.where((i) {
      return i.title.toLowerCase().contains(q) ||
          i.summary.toLowerCase().contains(q) ||
          i.tag.toLowerCase().contains(q) ||
          i.source.toLowerCase().contains(q);
    }).toList();
  }

  /// Initialize topics from prefs (call once at app start)
  void initTopics() {
    _selectedTopics = PrefsService.getSelectedTopics(AppConfig.activeTopicsByDefault);
  }

  /// Update selected topics and persist
  void setSelectedTopics(List<String> topics) {
    _selectedTopics = topics;
    PrefsService.setSelectedTopics(topics);
    // Reset index when filter changes
    _currentIndex = 0;
    notifyListeners();
  }

  /// Load feeds from API, detect new stories vs cached list
  Future<void> loadFeeds({bool fromResume = false}) async {
    if (_state == FeedState.loading) return;

    _state = FeedState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      developer.log('Loading feeds (fromResume=$fromResume)...', name: 'NewsProvider');
      final items = await RssService.fetchAll();

      if (items.isEmpty) {
        _state = FeedState.error;
        _errorMessage = 'No articles found. Check if the API server is running.';
        developer.log('No items loaded', name: 'NewsProvider');
      } else {
        final prevIds = PrefsService.getCachedStoryIds().toSet();
        final newIds = items.map((i) => i.id).toList();
        final newSet = newIds.toSet();

        if (fromResume && prevIds.isNotEmpty) {
          final fresh = newSet.difference(prevIds);
          if (fresh.isNotEmpty) {
            // New stories detected — reset index to 0, show banner
            _newStoriesCount = fresh.length;
            _currentIndex = 0;
          } else {
            // No new stories — restore saved index
            final savedIndex = PrefsService.getLastIndex();
            _currentIndex = savedIndex.clamp(0, items.length - 1);
          }
        } else if (!fromResume) {
          // First load: restore last index
          final savedIndex = PrefsService.getLastIndex();
          _currentIndex = savedIndex.clamp(0, items.length - 1);
        }

        _allItems = items;
        _state = FeedState.loaded;

        // Persist new ID snapshot
        await PrefsService.setCachedStoryIds(newIds);
        await PrefsService.setCachedAt(DateTime.now().toUtc().toIso8601String());

        developer.log('Loaded ${items.length} items, index=$_currentIndex', name: 'NewsProvider');
      }
    } catch (e) {
      _state = FeedState.error;
      _errorMessage = 'Failed to load news: $e';
      developer.log('Error loading feeds: $e', name: 'NewsProvider');
    }
    notifyListeners();

    // Fetch stats in parallel (non-blocking)
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    try {
      _stats = await StatsService.fetch();
      notifyListeners();
    } catch (_) {}
  }

  /// Set search query with debouncing
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentIndex = 0;
    _searchDebounceTimer?.cancel();
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

  /// Set current index and persist it
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      PrefsService.setLastIndex(index);
      notifyListeners();
    }
  }

  /// Mark item as read
  void markAsRead(String id) {
    try {
      final idx = _allItems.indexWhere((i) => i.id == id);
      if (idx != -1 && !_allItems[idx].isRead) {
        _allItems[idx].isRead = true;
        notifyListeners();
        _refreshStats();
      }
    } catch (e) {
      developer.log('Error marking as read: $e', name: 'NewsProvider');
    }
  }

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

  Future<void> refresh() async {
    _currentIndex = 0;
    _searchQuery = '';
    _isSearchActive = false;
    _searchDebounceTimer?.cancel();
    _newStoriesCount = 0;
    await loadFeeds();
  }

  void clearCache() => RssService.clearCache();
  Map<String, dynamic> getCacheStats() => RssService.getCacheStats();

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
