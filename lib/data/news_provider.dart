import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/rss_service.dart';
import '../services/session_service.dart';

enum FeedState { idle, loading, loaded, error }

/// Central state manager for the news feed.
///
/// Key behaviours:
/// - [loadFeeds(resume: true)]: Restores last viewed index on app reopen.
///   If the server returns new story IDs not in the previous list, resets
///   to index 0 and shows a "new stories" banner.
/// - [markAsRead]: Updates local session + calls server, then refreshes stats.
/// - [toggleTopic] / [setTopicFilter]: Persists selected tags to session,
///   triggers a reload via [loadFeeds]. An empty filter = show all topics.
/// - [notifyNewStoriesAvailable]: Called by the TodayScreen SSE poll when
///   /v1/today/updates fires; shows a non-intrusive banner.
class NewsProvider extends ChangeNotifier {
  List<NewsItem> _allItems = [];
  List<String> _previousStoryIds = [];
  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isSearchActive = false;
  FeedState _state = FeedState.idle;
  String _errorMessage = '';
  Timer? _searchDebounceTimer;
  Timer? _sessionSyncTimer;

  // Server-side stats (device-scoped, fetched from /v1/today/stats)
  int _serverRead = 0;
  int _serverUnread = 0;
  int _serverTotal = 0;

  // Active topic filter — empty list means "show all"
  List<String> _selectedTopics = [];

  // Whether the SSE poll detected new stories the user has not yet loaded
  bool _hasNewStories = false;

  // ---------------------------------------------------------------- getters

  FeedState get state => _state;
  String get errorMessage => _errorMessage;
  List<NewsItem> get allItems => _allItems;
  int get currentIndex => _currentIndex;
  bool get isSearchActive => _isSearchActive;
  String get searchQuery => _searchQuery;
  bool get hasNewStories => _hasNewStories;
  List<String> get selectedTopics => List.unmodifiable(_selectedTopics);

  /// Prefer server stats (device-scoped); fall back to local counts.
  int get readCount =>
      _serverRead > 0 ? _serverRead : _allItems.where((i) => i.isRead).length;
  int get unreadCount =>
      _serverUnread > 0
          ? _serverUnread
          : _allItems.where((i) => !i.isRead).length;
  int get totalCount =>
      _serverTotal > 0 ? _serverTotal : _allItems.length;

  /// Items after applying search AND topic filter (client-side).
  List<NewsItem> get filteredItems {
    var items = _allItems;

    // Topic filter (client-side safety net — server already filters via topics param)
    if (_selectedTopics.isNotEmpty) {
      final lowerTopics =
          _selectedTopics.map((t) => t.toLowerCase()).toSet();
      items = items
          .where((i) => lowerTopics.contains(i.tag.toLowerCase()))
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      items = items
          .where((i) =>
              i.title.toLowerCase().contains(q) ||
              i.summary.toLowerCase().contains(q) ||
              i.tag.toLowerCase().contains(q) ||
              i.source.toLowerCase().contains(q))
          .toList();
    }

    return items;
  }

  // ---------------------------------------------------------------- load

  /// Loads today's feed.
  ///
  /// [resume]: if true (cold start / reopen), restores the last saved index.
  /// If new story IDs are detected vs the previous list, resets to index 0
  /// and flags [hasNewStories] so TodayScreen can show a banner.
  Future<void> loadFeeds({bool resume = false}) async {
    if (_state == FeedState.loading) return;
    _state = FeedState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Parallel: stats + stories
      final results = await Future.wait([
        RssService.fetchStats(),
        RssService.fetchAll(
          perPage: 20,
          topics: _selectedTopics.isEmpty ? null : _selectedTopics,
        ),
      ]);

      final stats = results[0] as Map<String, int>;
      final items = results[1] as List<NewsItem>;

      _serverRead = stats['read'] ?? 0;
      _serverUnread = stats['unread'] ?? 0;
      _serverTotal = stats['total'] ?? 0;

      if (items.isEmpty && _selectedTopics.isEmpty) {
        _state = FeedState.error;
        _errorMessage = 'No new stories today. All caught up! \u2615';
        notifyListeners();
        return;
      }

      final newIds = items.map((i) => i.id).toSet();
      final hasChanges = _previousStoryIds.isEmpty ||
          !newIds.containsAll(_previousStoryIds) ||
          newIds.length != _previousStoryIds.length;

      _allItems = items;
      _previousStoryIds = items.map((i) => i.id).toList();
      _state = FeedState.loaded;

      if (resume && !hasChanges && items.isNotEmpty) {
        // Restore exactly where the user left off
        final saved = SessionService.lastStoryIndex;
        _currentIndex = saved.clamp(0, items.length - 1);
        _hasNewStories = false;
      } else if (resume && hasChanges) {
        // New content available — go to top, show banner
        _currentIndex = 0;
        _hasNewStories = true;
      } else {
        // Manual refresh or first load
        _currentIndex = 0;
        _hasNewStories = false;
      }
    } catch (e) {
      _state = FeedState.error;
      _errorMessage = 'Failed to load news. Check your connection.';
      developer.log('NewsProvider.loadFeeds error: $e', name: 'NewsProvider');
    }
    notifyListeners();
  }

  Future<void> refresh() => loadFeeds();

  // ---------------------------------------------------------------- index

  void setCurrentIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    // Debounce write to 500 ms to avoid hammering storage on fast swipes
    _sessionSyncTimer?.cancel();
    _sessionSyncTimer = Timer(const Duration(milliseconds: 500), () {
      SessionService.saveLastIndex(index);
      _syncSessionToServer();
    });
    notifyListeners();
  }

  // ---------------------------------------------------------------- read

  Future<void> markAsRead(String id) async {
    try {
      final idx = _allItems.indexWhere((i) => i.id == id);
      if (idx == -1 || _allItems[idx].isRead) return;
      _allItems[idx].isRead = true;
      await SessionService.markRead(id);
      RssService.markReadOnServer(id);
      await _refreshStats();
      notifyListeners();
    } catch (e) {
      developer.log('markAsRead error: $e', name: 'NewsProvider');
    }
  }

  Future<void> _refreshStats() async {
    try {
      final stats = await RssService.fetchStats();
      _serverRead = stats['read'] ?? _serverRead;
      _serverUnread = stats['unread'] ?? _serverUnread;
      _serverTotal = stats['total'] ?? _serverTotal;
    } catch (_) {}
  }

  // ---------------------------------------------------------------- topic filter

  /// Toggle a single topic tag. Empty filter = show all.
  void toggleTopic(String topic) {
    final updated = List<String>.from(_selectedTopics);
    if (updated.contains(topic)) {
      updated.remove(topic);
    } else {
      updated.add(topic);
    }
    setTopicFilter(updated);
  }

  bool isTopicSelected(String topic) =>
      _selectedTopics.isEmpty || _selectedTopics.contains(topic);

  bool isTopicExplicitlySelected(String topic) =>
      _selectedTopics.contains(topic);

  /// Replace the topic filter entirely and reload the feed from the server.
  void setTopicFilter(List<String> topics) {
    _selectedTopics = List.from(topics);
    SessionService.saveTopics(topics);
    _currentIndex = 0;
    notifyListeners();
    loadFeeds();
  }

  // ------------------------------------------------------------- SSE callback

  /// Called when the polling timer in TodayScreen detects new stories.
  void notifyNewStoriesAvailable() {
    _hasNewStories = true;
    notifyListeners();
  }

  /// Called when the user taps the "new stories" banner.
  Future<void> reloadAfterNewStories() async {
    _hasNewStories = false;
    await loadFeeds();
  }

  void dismissNewStoriesBanner() {
    _hasNewStories = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- actions

  void toggleLike(String id) {
    final idx = _allItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _allItems[idx].isLiked = !_allItems[idx].isLiked;
      notifyListeners();
    }
  }

  void toggleBookmark(String id) {
    final idx = _allItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _allItems[idx].isBookmarked = !_allItems[idx].isBookmarked;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- search

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentIndex = 0;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer =
        Timer(const Duration(milliseconds: 300), notifyListeners);
  }

  void toggleSearch() {
    _isSearchActive = !_isSearchActive;
    if (!_isSearchActive) {
      _searchQuery = '';
      _searchDebounceTimer?.cancel();
      _currentIndex = 0;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- sync

  Future<void> _syncSessionToServer() async {
    try {
      await RssService.syncSession(
        lastIndex: _currentIndex,
        topics: _selectedTopics,
        displayName: SessionService.displayName,
        locationLabel: SessionService.locationLabel,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _sessionSyncTimer?.cancel();
    super.dispose();
  }
}
