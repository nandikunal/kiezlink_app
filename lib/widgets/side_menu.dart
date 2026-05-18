import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../data/news_provider.dart';
import '../services/session_service.dart';
import '../services/location_service.dart';
import '../utils/utils.dart';
import 'tag_chip.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});
  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _trendingExpanded = true;
  bool _topStoriesExpanded = false;
  bool _myFeedExpanded = true;

  // Location refresh state
  bool _refreshingLocation = false;

  late String _displayName;
  late String _locationLabel;

  @override
  void initState() {
    super.initState();
    _displayName = SessionService.displayName;
    _locationLabel = SessionService.locationLabel;
  }

  Future<void> _refreshLocation() async {
    setState(() => _refreshingLocation = true);
    final label = await LocationService.requestAndResolve();
    if (mounted) {
      setState(() {
        _locationLabel = label;
        _refreshingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    // Sync selected topics from provider into local display
    final selectedTopics = provider.selectedTopics;
    final allTopics = AppConfig.allTopics;

    return Container(
      width: MediaQuery.of(context).size.width * AppConfig.sideMenuWidthFraction,
      decoration: const BoxDecoration(
        color: AppConfig.surfaceColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppConfig.borderRadiusLarge),
          bottomRight: Radius.circular(AppConfig.borderRadiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          // ── Header: avatar + name + location ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppConfig.paddingXLarge),
            child: Column(children: [
              Row(children: [
                Container(
                  width: AppConfig.imagePreviewWidth,
                  height: AppConfig.imagePreviewHeight,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppConfig.primaryColor, AppConfig.errorColor],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: AppConfig.iconSizeLarge,
                  ),
                ),
                const SizedBox(width: AppConfig.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppConfig.fontSizeXLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: _refreshingLocation ? null : _refreshLocation,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_refreshingLocation)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppConfig.primaryColor),
                              )
                            else
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.white.withValues(alpha: AppOpacity.medium),
                              ),
                            const SizedBox(width: 3),
                            Text(
                              _locationLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: AppOpacity.medium),
                                fontSize: AppConfig.fontSizeSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.5)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: AppConfig.paddingLarge),
              // ── Stats row: Read | Unread | Total ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat(
                      AppConfig.textReadCount,
                      provider.readCount.toString(),
                      AppConfig.successColor,
                    ),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: AppOpacity.trace)),
                    _stat(
                      AppConfig.textUnreadCount,
                      provider.unreadCount.toString(),
                      AppConfig.primaryColor,
                    ),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: AppOpacity.trace)),
                    _stat(
                      AppConfig.textTotalCount,
                      provider.totalCount.toString(),
                      Colors.white,
                    ),
                  ],
                ),
              ),
              // Hint: tap location to refresh
              const SizedBox(height: 6),
              Text(
                'Tap location to refresh',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                ),
              ),
            ]),
          ),
          Divider(
            color: Colors.white.withValues(alpha: AppOpacity.minimal),
            height: 1,
          ),
          // ── Scrollable body ───────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppConfig.paddingSmall),
              children: [
                // ── My Feed topic filter ─────────────────────────────────
                _sectionHeader(
                  AppConfig.textMyFeed,
                  Icons.tune,
                  _myFeedExpanded,
                  () => setState(() => _myFeedExpanded = !_myFeedExpanded),
                ),
                if (_myFeedExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingLarge,
                      vertical: AppConfig.paddingSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "All" quick-toggle
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              if (selectedTopics.isEmpty) {
                                // already showing all — no-op
                              } else {
                                provider.setTopicFilter([]);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: selectedTopics.isEmpty
                                    ? AppConfig.primaryColor
                                    : Colors.white
                                        .withValues(alpha: AppOpacity.trace),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedTopics.isEmpty
                                      ? AppConfig.primaryColor
                                      : Colors.white.withValues(
                                          alpha: AppOpacity.veryLow),
                                ),
                              ),
                              child: Text(
                                'All topics',
                                style: TextStyle(
                                  color: selectedTopics.isEmpty
                                      ? Colors.black
                                      : Colors.white
                                          .withValues(alpha: AppOpacity.medium),
                                  fontSize: AppConfig.fontSizeMedium,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: AppConfig.paddingSmall,
                          runSpacing: AppConfig.paddingSmall,
                          children: allTopics.map((t) {
                            final active = selectedTopics.isEmpty ||
                                selectedTopics.contains(t);
                            final explicitlySelected =
                                selectedTopics.contains(t);
                            return GestureDetector(
                              onTap: () => provider.toggleTopic(t),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConfig.paddingMedium,
                                  vertical: AppConfig.paddingSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: explicitlySelected
                                      ? AppConfig.primaryColor
                                          .withValues(alpha: AppOpacity.low)
                                      : Colors.white
                                          .withValues(alpha: AppOpacity.trace),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: explicitlySelected
                                        ? AppConfig.primaryColor
                                        : Colors.white.withValues(
                                            alpha: AppOpacity.veryLow),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: active
                                        ? (explicitlySelected
                                            ? AppConfig.primaryColor
                                            : Colors.white.withValues(
                                                alpha: AppOpacity.medium))
                                        : Colors.white
                                            .withValues(alpha: 0.25),
                                    fontSize: AppConfig.fontSizeMedium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (selectedTopics.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Showing ${selectedTopics.length} topic${selectedTopics.length == 1 ? '' : 's'} — tap All to reset',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppConfig.paddingSmall),
                // ── Trending Now ─────────────────────────────────────────
                _sectionHeader(
                  AppConfig.textTrendingNow,
                  Icons.local_fire_department,
                  _trendingExpanded,
                  () => setState(
                      () => _trendingExpanded = !_trendingExpanded),
                ),
                if (_trendingExpanded)
                  ...provider.allItems
                      .take(AppConfig.trendingItemsCount)
                      .map((item) => _newsRow(context, item, provider)),
                const SizedBox(height: AppConfig.paddingSmall),
                // ── Top Stories ──────────────────────────────────────────
                _sectionHeader(
                  AppConfig.textTopStories,
                  Icons.star,
                  _topStoriesExpanded,
                  () => setState(
                      () => _topStoriesExpanded = !_topStoriesExpanded),
                ),
                if (_topStoriesExpanded)
                  ...provider.allItems
                      .skip(AppConfig.trendingItemsCount)
                      .take(AppConfig.topStoriesItemsCount)
                      .map((item) => _newsRow(context, item, provider)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: AppConfig.fontSizeHuge,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppConfig.paddingSmall / 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: AppOpacity.low),
            fontSize: AppConfig.fontSizeSmall,
          ),
        ),
      ]);

  Widget _sectionHeader(
    String title,
    IconData icon,
    bool expanded,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingLarge,
            vertical: AppConfig.paddingMedium,
          ),
          child: Row(children: [
            Icon(icon,
                color: AppConfig.primaryColor, size: AppConfig.iconSizeSmall),
            const SizedBox(width: AppConfig.paddingSmall),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppConfig.fontSizeLarge,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: AppOpacity.low),
              size: AppConfig.iconSizeMedium,
            ),
          ]),
        ),
      );

  Widget _newsRow(
    BuildContext context,
    dynamic item,
    NewsProvider provider,
  ) =>
      GestureDetector(
        onTap: () {
          final idx = provider.allItems.indexOf(item);
          if (idx != -1) provider.setCurrentIndex(idx);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingLarge,
            vertical: AppConfig.paddingSmall,
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppConfig.borderRadiusSmall),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: AppConfig.imagePreviewWidth,
                height: AppConfig.imagePreviewHeight,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: AppConfig.imagePreviewWidth,
                  height: AppConfig.imagePreviewHeight,
                  color: Colors.white.withValues(alpha: AppOpacity.trace),
                  child: const Icon(Icons.image, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: AppConfig.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.isRead
                          ? Colors.white.withValues(alpha: AppOpacity.low)
                          : Colors.white,
                      fontSize: AppConfig.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConfig.paddingSmall / 2),
                  TagChip(tag: item.tag),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.white.withValues(alpha: AppOpacity.low),
              size: AppConfig.iconSizeSmall,
            ),
          ]),
        ),
      );
}
