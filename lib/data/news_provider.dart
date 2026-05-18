import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_card.dart';
import '../models/stats_response.dart';
import '../services/news_service.dart';
import '../services/location_service.dart';

const _keyLastIndex = 'last_story_index';
const _keySelectedTopics = 'selected_topics';

/// All selectable topic labels (mirrors backend TopicLabel enum).
const kAllTopics = [
  'technology',
  'sports',
  'health',
  'economy',
  'culture',
  'environment',
  'transport',
  'politics',
  'berlin',
  'germany',
  'news',
];

class NewsProvider extends ChangeNotifier {
  final NewsService _service;
  final LocationService _location;

  // ── Story state ────────────────────────────────────────────────
  List<StoryCard> _allStories = [];
  List<StoryCard> get stories => _filteredStories;

  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';

  // ── Stats ──────────────────────────────────────────────────────
  StatsResponse? stats;

  // ── Pagination ─────────────────────────────────────────────────
  int currentPage = 1;
  bool hasMore = true;

  // ── Last-viewed index (persist across sessions) ────────────────
  int resumeIndex = 0;

  // ── Topic filter ───────────────────────────────────────────────
  /// Null = all topics selected (no filter applied)
  Set<String>? _selectedTopics;

  Set<String> get selectedTopics =>
      _selectedTopics ?? Set.from(kAllTopics);

  bool get allTopicsSelected =>
      _selectedTopics == null || _selectedTopics!.length == kAllTopics.length;

  List<StoryCard> get _filteredStories {
    if (_selectedTopics == null || _selectedTopics!.isEmpty) {
      return _allStories;
    }
    return _allStories
        .where((s) => _selectedTopics!.contains(s.topic.toLowerCase()))
        .toList();
  }

  // ── SSE ────────────────────────────────────────────────────────
  StreamSubscription<List<StoryCard>>? _sseSubscription;
  bool hasNewStoriesBanner = false;
  int newStoriesCount = 0;

  // ── Cache tracking for SSE since= param ───────────────────────
  DateTime _lastCachedAt = DateTime.now().toUtc();

  NewsProvider({required NewsService service, required LocationService location})
      : _service = service,
        _location = location;

  // ── Init ───────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadPersistedState();
    await Future.wait([
      loadStories(refresh: true),
      loadStats(),
    ]);
    _subscribeSse();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    resumeIndex = prefs.getInt(_keyLastIndex) ?? 0;
    final saved = prefs.getStringList(_keySelectedTopics);
    if (saved != null && saved.isNotEmpty) {
      _selectedTopics = Set.from(saved);
    }
  }

  // ── Stories ────────────────────────────────────────────────────

  Future<void> loadStories({bool refresh = false}) async {
    if (isLoading) return;
    if (refresh) {
      currentPage = 1;
      hasMore = true;
      _allStories = [];
    }
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final response = await _service.fetchToday(
        page: currentPage,
        perPage: 20,
        tz: _location.timezone,
        topics: _selectedTopics?.toList() ?? [],
      );

      final List<dynamic> rawStories = response['stories'] ?? [];
      final newStories =
          rawStories.map((s) => StoryCard.fromJson(s)).toList();

      // Detect fresh content: if server total > local count, something new arrived
      final serverTotal = (response['total'] as num?)?.toInt() ?? 0;
      final cachedAt = response['cached_at'] != null
          ? DateTime.tryParse(response['cached_at'] as String)
          : null;
      if (cachedAt != null) _lastCachedAt = cachedAt.toUtc();

      if (refresh && serverTotal > _allStories.length + newStories.length) {
        // New content detected — reset to top
        resumeIndex = 0;
        await _persistIndex(0);
      }

      _allStories = refresh ? newStories : [..._allStories, ...newStories];
      hasMore = newStories.length == 20;
      if (hasMore) currentPage++;
    } catch (e) {
      hasError = true;
      errorMessage = 'Could not load stories. Please try again.';
      debugPrint('loadStories error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreStories() async {
    if (!hasMore || isLoading) return;
    await loadStories();
  }

  // ── Stats ──────────────────────────────────────────────────────

  Future<void> loadStats() async {
    try {
      stats = await _service.fetchStats(tz: _location.timezone);
      notifyListeners();
    } catch (e) {
      debugPrint('loadStats error: $e');
    }
  }

  // ── Mark read ──────────────────────────────────────────────────

  Future<void> markRead(String storyId) async {
    try {
      await _service.markRead(storyId);
      final idx = _allStories.indexWhere((s) => s.id == storyId);
      if (idx != -1) {
        _allStories[idx] = _allStories[idx].copyWith(read: true);
        notifyListeners();
      }
      // Refresh stats counter after marking read
      await loadStats();
    } catch (e) {
      debugPrint('markRead error: $e');
    }
  }

  // ── Index persistence ──────────────────────────────────────────

  Future<void> saveCurrentIndex(int index) async {
    resumeIndex = index;
    await _persistIndex(index);
  }

  Future<void> _persistIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastIndex, index);
  }

  // ── Topic filter ───────────────────────────────────────────────

  Future<void> toggleTopic(String topic) async {
    _selectedTopics ??= Set.from(kAllTopics);
    if (_selectedTopics!.contains(topic)) {
      _selectedTopics!.remove(topic);
    } else {
      _selectedTopics!.add(topic);
    }
    // Reset to page 1 with new filter (client-side first pass)
    notifyListeners();
    // Also re-fetch from server with topic param for a clean server-filtered result
    await loadStories(refresh: true);
    // Persist selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _keySelectedTopics, _selectedTopics!.toList());
  }

  Future<void> selectAllTopics() async {
    _selectedTopics = null;
    notifyListeners();
    await loadStories(refresh: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedTopics);
  }

  // ── SSE subscription ───────────────────────────────────────────

  void _subscribeSse() {
    _sseSubscription?.cancel();
    _sseSubscription = _service
        .subscribeToUpdates(
          since: _lastCachedAt,
          tz: _location.timezone,
        )
        .listen((newStories) {
      newStoriesCount = newStories.length;
      hasNewStoriesBanner = true;
      notifyListeners();
    });
  }

  /// Call from AppLifecycleState.resumed
  void resumeSse() {
    _subscribeSse();
  }

  /// Call from AppLifecycleState.paused
  void pauseSse() {
    _sseSubscription?.cancel();
    _service.cancelSseSubscription();
  }

  void dismissNewStoriesBanner() {
    hasNewStoriesBanner = false;
    newStoriesCount = 0;
    notifyListeners();
  }

  /// Called when user taps the new-stories banner — reloads and scrolls to top.
  Future<void> reloadFreshStories() async {
    dismissNewStoriesBanner();
    await loadStories(refresh: true);
    resumeIndex = 0;
    await _persistIndex(0);
  }

  @override
  void dispose() {
    pauseSse();
    _service.dispose();
    super.dispose();
  }
}
