import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../config/constants.dart';
import '../data/news_provider.dart';
import '../widgets/story_card.dart';
import '../widgets/side_menu.dart';
import '../services/rss_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  Timer? _readTimer;
  bool _showSwipeHint = true;
  late AnimationController _hintCtrl;
  late TextEditingController _searchCtrl;

  // SSE / updates polling
  Timer? _updatesPollTimer;
  DateTime? _lastCachedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _hintCtrl = AnimationController(
      vsync: this,
      duration: AppConfig.animationDurationSlow,
    )..repeat(reverse: true);
    _searchCtrl = TextEditingController();

    // Hide swipe hint after delay
    Future.delayed(const Duration(milliseconds: AppConfig.swipeHintDelayMs), () {
      if (mounted) setState(() => _showSwipeHint = false);
    });

    // Load feeds on launch — resume to last saved index
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<NewsProvider>();
      await provider.loadFeeds(resume: true);

      // After load, jump PageController to restored index without animation
      if (mounted && provider.state == FeedState.loaded) {
        final targetIdx = provider.currentIndex;
        if (targetIdx > 0) {
          _pageController.jumpToPage(targetIdx);
        }
        // Remember last_refresh_at for polling
        _lastCachedAt = DateTime.now();
        _startUpdatePolling();
      }
    });
  }

  // ---------------------------------------------------------------- lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground — check for new stories
      _checkForUpdates();
      _startUpdatePolling();
    } else if (state == AppLifecycleState.paused) {
      _stopUpdatePolling();
    }
  }

  void _startUpdatePolling() {
    _updatesPollTimer?.cancel();
    // Poll every 60 seconds for new stories
    _updatesPollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkForUpdates();
    });
  }

  void _stopUpdatePolling() {
    _updatesPollTimer?.cancel();
    _updatesPollTimer = null;
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    final since = _lastCachedAt ?? DateTime.now().subtract(const Duration(hours: 1));
    try {
      final newStories = await RssService.checkUpdates(since: since);
      if (newStories > 0 && mounted) {
        context.read<NewsProvider>().notifyNewStoriesAvailable();
      }
      _lastCachedAt = DateTime.now();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _readTimer?.cancel();
    _hintCtrl.dispose();
    _searchCtrl.dispose();
    _updatesPollTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- PageController

  // Build PageController lazily so we can set initialPage from the provider
  // after loadFeeds(resume:true) has resolved the currentIndex.
  PageController _buildPageController(int initialPage) {
    return PageController(initialPage: initialPage);
  }

  void _onPageChanged(int index) {
    final provider = context.read<NewsProvider>();
    provider.setCurrentIndex(index);
    _readTimer?.cancel();
    _readTimer = Timer(
      const Duration(milliseconds: AppConfig.readDelayMs),
      () {
        final items = provider.filteredItems;
        if (index < items.length && mounted) {
          provider.markAsRead(items[index].id);
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the PageController with initialPage=0; it will be jumped
    // to the correct resume index in initState's postFrameCallback.
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final provider = context.watch<NewsProvider>();
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: Stack(children: [
        _buildFeedArea(provider),
        Positioned(top: 0, left: 0, right: 0, child: _buildFloatingNav(provider)),
        if (provider.isSearchActive)
          Positioned(top: 0, left: 0, right: 0, child: _buildSearchBar(provider)),
        if (provider.state == FeedState.loaded &&
            provider.filteredItems.isNotEmpty &&
            !provider.isSearchActive)
          Positioned(
            right: AppConfig.paddingSmall,
            top: MediaQuery.of(context).size.height * AppConfig.progressDotsTopFraction,
            bottom: MediaQuery.of(context).size.height *
                AppConfig.progressDotsBottomFraction,
            child: _buildProgressDots(
              provider.filteredItems.length,
              provider.currentIndex,
            ),
          ),
        if (_showSwipeHint &&
            provider.state == FeedState.loaded &&
            provider.filteredItems.isNotEmpty)
          Positioned(
            bottom: AppConfig.swipeHintBottomPosition,
            left: 0,
            right: 0,
            child: _buildSwipeHint(),
          ),
        // New-stories banner
        if (provider.hasNewStories)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 16,
            right: 16,
            child: _buildNewStoriesBanner(provider),
          ),
      ]),
    );
  }

  // ---------------------------------------------------------------- banner

  Widget _buildNewStoriesBanner(NewsProvider provider) =>
      GestureDetector(
        onTap: () async {
          await provider.reloadAfterNewStories();
          if (mounted && provider.state == FeedState.loaded) {
            _pageController.jumpToPage(0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            const Icon(Icons.refresh_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'New stories available — tap to refresh',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: provider.dismissNewStoriesBanner,
              child: const Icon(Icons.close, color: Colors.black54, size: 16),
            ),
          ]),
        ),
      );

  // ---------------------------------------------------------------- feed area

  Widget _buildFeedArea(NewsProvider provider) {
    switch (provider.state) {
      case FeedState.idle:
      case FeedState.loading:
        return _buildShimmer();
      case FeedState.error:
        return _buildError(provider);
      case FeedState.loaded:
        final items = provider.filteredItems;
        if (items.isEmpty) return _buildEmpty();
        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppConfig.primaryColor,
          backgroundColor: AppConfig.backgroundColor,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: items.length,
            itemBuilder: (_, i) => StoryCard(
              item: items[i],
              index: i,
              total: items.length,
            ),
          ),
        );
    }
  }

  Widget _buildSwipeHint() => AnimatedBuilder(
        animation: _hintCtrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -8 * _hintCtrl.value),
          child: Opacity(
            opacity: (1 - _hintCtrl.value * AppOpacity.low).clamp(0.0, 1.0),
            child: Column(children: [
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white.withValues(alpha: AppOpacity.high),
                size: AppConfig.iconSizeXLarge,
              ),
              Text(
                AppConfig.messageSwipeForNext,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: AppOpacity.medium),
                  fontSize: AppConfig.fontSizeSmall,
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _buildShimmer() => Shimmer.fromColors(
        baseColor: AppConfig.shimmerBaseColor,
        highlightColor: AppConfig.shimmerHighlightColor,
        child: Container(
          color: AppConfig.shimmerBaseColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(AppConfig.paddingXLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 80, height: 20, color: Colors.white,
                        margin: const EdgeInsets.only(bottom: AppConfig.paddingMedium)),
                    Container(width: double.infinity, height: 28, color: Colors.white,
                        margin: const EdgeInsets.only(bottom: AppConfig.paddingSmall)),
                    Container(width: 260, height: 28, color: Colors.white,
                        margin: const EdgeInsets.only(bottom: AppConfig.paddingLarge)),
                    Container(width: double.infinity, height: 14, color: Colors.white,
                        margin: const EdgeInsets.only(bottom: AppConfig.paddingSmall)),
                    Container(width: double.infinity, height: 14, color: Colors.white,
                        margin: const EdgeInsets.only(bottom: AppConfig.paddingSmall)),
                    Container(width: 200, height: 14, color: Colors.white,
                        margin: const EdgeInsets.only(bottom: AppConfig.paddingXLarge)),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );

  Widget _buildError(NewsProvider provider) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingXLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  color: Colors.white.withValues(alpha: AppOpacity.low),
                  size: AppConfig.iconSizeHuge),
              const SizedBox(height: AppConfig.paddingXLarge),
              const Text(AppConfig.errorCouldNotLoadNews,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppConfig.fontSizeXLarge,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: AppConfig.paddingMedium),
              Text(provider.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: AppOpacity.medium),
                    fontSize: AppConfig.fontSizeLarge,
                  )),
              const SizedBox(height: AppConfig.paddingXLarge),
              GestureDetector(
                onTap: provider.refresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingXLarge,
                      vertical: AppConfig.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor,
                    borderRadius:
                        BorderRadius.circular(AppConfig.borderRadiusMedium),
                  ),
                  child: const Text(AppConfig.errorTryAgain,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: AppConfig.fontSizeXLarge,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: Colors.white.withValues(alpha: AppOpacity.low),
                size: AppConfig.iconSizeHuge),
            const SizedBox(height: AppConfig.paddingXLarge),
            const Text(AppConfig.errorNoStoriesFound,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppConfig.fontSizeXXLarge,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: AppConfig.paddingMedium),
            Text(AppConfig.errorTryDifferentSearch,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: AppOpacity.low),
                  fontSize: AppConfig.fontSizeLarge,
                )),
          ],
        ),
      );

  // ---------------------------------------------------------------- nav

  Widget _buildFloatingNav(NewsProvider provider) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: AppOpacity.high),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + AppConfig.paddingMedium,
          left: AppConfig.paddingLarge,
          right: AppConfig.paddingLarge,
          bottom: AppConfig.paddingMedium,
        ),
        child: Row(children: [
          GestureDetector(onTap: _openSideMenu, child: _navBtn(Icons.menu)),
          const SizedBox(width: AppConfig.paddingMedium),
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: 'Kiez',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppConfig.fontSizeHuge,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'link',
                style: TextStyle(
                  color: AppConfig.primaryColor,
                  fontSize: AppConfig.fontSizeHuge,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]),
          ),
          const Spacer(),
          // Total count badge next to save icon
          if (provider.state == FeedState.loaded)
            _buildTotalCountBadge(provider),
          if (provider.state == FeedState.loading)
            const SizedBox(
              width: AppConfig.iconSizeLarge,
              height: AppConfig.iconSizeLarge,
              child: CircularProgressIndicator(
                color: AppConfig.primaryColor,
                strokeWidth: 2,
              ),
            ),
          const SizedBox(width: AppConfig.paddingSmall),
          Stack(children: [
            _navBtn(Icons.notifications_none),
            if (provider.unreadCount > 0)
              Positioned(
                top: AppConfig.paddingSmall,
                right: AppConfig.paddingSmall,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppConfig.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ]),
          const SizedBox(width: AppConfig.paddingSmall),
          GestureDetector(
            onTap: () {
              provider.toggleSearch();
              if (!provider.isSearchActive) _searchCtrl.clear();
            },
            child: _navBtn(Icons.search),
          ),
        ]),
      );

  Widget _buildTotalCountBadge(NewsProvider provider) {
    final current = provider.currentIndex + 1;
    final total = provider.totalCount > 0
        ? provider.totalCount
        : provider.filteredItems.length;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bookmark_outline,
            color: Colors.white.withValues(alpha: 0.6), size: 14),
        const SizedBox(width: 4),
        Text(
          '$current / $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  Widget _navBtn(IconData icon) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: AppOpacity.low),
          borderRadius: BorderRadius.circular(AppConfig.borderRadiusMedium),
          border: Border.all(
              color: Colors.white.withValues(alpha: AppOpacity.veryLow)),
        ),
        child: Icon(icon, color: Colors.white, size: AppConfig.iconSizeMedium),
      );

  Widget _buildSearchBar(NewsProvider provider) => Container(
        color: Colors.black.withValues(alpha: AppOpacity.high),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + AppConfig.paddingMedium,
          left: AppConfig.paddingMedium,
          right: AppConfig.paddingMedium,
          bottom: AppConfig.paddingMedium,
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppConfig.textSearchNews,
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: AppOpacity.low)),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withValues(alpha: AppOpacity.low)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: AppOpacity.trace),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConfig.borderRadiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
          const SizedBox(width: AppConfig.paddingMedium),
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              provider.toggleSearch();
            },
            child: const Text(
              AppConfig.errorCancel,
              style: TextStyle(
                color: AppConfig.primaryColor,
                fontSize: AppConfig.fontSizeMedium,
              ),
            ),
          ),
        ]),
      );

  Widget _buildProgressDots(int total, int current) {
    final count = total.clamp(0, AppConfig.maxDots);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current.clamp(0, AppConfig.maxDots - 1);
        return AnimatedContainer(
          duration: AppConfig.animationDurationFast,
          margin: const EdgeInsets.symmetric(vertical: AppConfig.paddingSmall / 2),
          width: active ? 4 : 3,
          height: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: AppOpacity.low),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  void _openSideMenu() => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close',
        barrierColor: Colors.black.withValues(alpha: AppOpacity.medium),
        transitionDuration: AppConfig.animationDurationNormal,
        pageBuilder: (_, __, ___) => const Align(
          alignment: Alignment.centerLeft,
          child: SideMenu(),
        ),
        transitionBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
}
