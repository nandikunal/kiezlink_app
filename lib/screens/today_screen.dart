import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/news_provider.dart';
import '../models/story_card.dart';
import '../widgets/story_card_widget.dart';
import '../widgets/side_menu.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // PageController is created after the first build when we know the resumeIndex
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      final resumeIndex =
          context.read<NewsProvider>().resumeIndex;
      _pageController = PageController(initialPage: resumeIndex);
      _controllerInitialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  // ── Lifecycle: pause/resume SSE ────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final news = context.read<NewsProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        news.resumeSse();
        // Check for new stories on resume
        news.loadStories(refresh: true).then((_) {
          final provider = context.read<NewsProvider>();
          if (!provider.hasNewStoriesBanner) {
            // No new banner = same content, restore last index
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(provider.resumeIndex);
              }
            });
          }
        });
        break;
      case AppLifecycleState.paused:
        news.pauseSse();
        break;
      default:
        break;
    }
  }

  // ── Page change: auto mark-read + persist index ────────────────
  void _onPageChanged(int index) {
    final news = context.read<NewsProvider>();
    news.saveCurrentIndex(index);
    final stories = news.stories;
    if (index < stories.length) {
      news.markRead(stories[index].id);
    }
    // Load more when nearing the end
    if (index >= stories.length - 3) {
      news.loadMoreStories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = context.watch<NewsProvider>();
    final stories = news.stories;
    final stats = news.stats;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Main feed ──────────────────────────────────────────
          if (news.isLoading && stories.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFFE8960A))),
            )
          else if (stories.isEmpty)
            _emptyState()
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                return StoryCardWidget(
                  story: stories[index],
                  index: index,
                  total: stats?.deduplicatedTotal ?? stories.length,
                );
              },
            ),

          // ── Hamburger + title bar ──────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu,
                          color: Colors.white, size: 26),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const Text(
                    'Kiez',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'link',
                    style: TextStyle(
                        color: Color(0xFFE8960A),
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  // Notification bell
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                      if (news.hasNewStoriesBanner)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8960A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── New stories banner ────────────────────────────────
          if (news.hasNewStoriesBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 64, 16, 0),
                  child: GestureDetector(
                    onTap: () {
                      news.reloadFreshStories().then((_) {
                        if (_pageController.hasClients) {
                          _pageController.animateToPage(
                            0,
                            duration:
                                const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8960A),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_upward,
                              color: Colors.black, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${news.newStoriesCount} new ${news.newStoriesCount == 1 ? 'story' : 'stories'} — tap to refresh',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: const SideMenu(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.newspaper, color: Colors.white24, size: 56),
          const SizedBox(height: 16),
          const Text(
            'No stories yet',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull to refresh or check back later',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE8960A))),
            onPressed: () => context.read<NewsProvider>().loadStories(refresh: true),
            child: const Text('Refresh',
                style: TextStyle(color: Color(0xFFE8960A))),
          ),
        ],
      ),
    );
  }
}
