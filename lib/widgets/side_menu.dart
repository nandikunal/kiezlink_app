import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../data/news_provider.dart';
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
  final List<String> _activeTopics = AppConfig.activeTopicsByDefault.toList();
  final List<String> _allTopics = AppConfig.defaultTopics;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    return Container(
      width: MediaQuery.of(context).size.width * LayoutConstants.tabletBreakpoint / 600,
      decoration: const BoxDecoration(
        color: AppConfig.surfaceColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppConfig.borderRadiusLarge),
          bottomRight: Radius.circular(AppConfig.borderRadiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppConfig.paddingXLarge),
            child: Column(children: [
              Row(children: [
                Container(
                  width: AppConfig.imagePreviewWidth,
                  height: AppConfig.imagePreviewHeight,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppConfig.primaryColor, AppConfig.errorColor]),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: AppConfig.iconSizeLarge),
                ),
                const SizedBox(width: AppConfig.paddingMedium),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(AppConfig.textBerlinReader,
                      style: TextStyle(color: Colors.white, fontSize: AppConfig.fontSizeXLarge, fontWeight: FontWeight.w700)),
                  Text(AppConfig.textBerlinLocation, style: TextStyle(color: Colors.white.withOpacity(AppOpacity.medium), fontSize: AppConfig.fontSizeSmall)),
                ]),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: AppConfig.paddingLarge),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat(AppConfig.textReadCount,   provider.readCount.toString(),   AppConfig.successColor),
                  Container(width: 1, height: 32, color: Colors.white.withOpacity(AppOpacity.trace)),
                  _stat(AppConfig.textUnreadCount, provider.unreadCount.toString(), AppConfig.primaryColor),
                  Container(width: 1, height: 32, color: Colors.white.withOpacity(AppOpacity.trace)),
                  _stat(AppConfig.textTotalCount,  provider.totalCount.toString(),  Colors.white),
                ]),
              ),
            ]),
          ),
          Divider(color: Colors.white.withOpacity(AppOpacity.minimal), height: 1),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: AppConfig.paddingSmall), children: [
            _sectionHeader(AppConfig.textMyFeed, Icons.tune, _myFeedExpanded,
                () => setState(() => _myFeedExpanded = !_myFeedExpanded)),
            if (_myFeedExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingLarge, vertical: AppConfig.paddingSmall),
                child: Wrap(
                  spacing: AppConfig.paddingSmall, runSpacing: AppConfig.paddingSmall,
                  children: _allTopics.map((t) {
                    final active = _activeTopics.contains(t);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (active) _activeTopics.remove(t); else _activeTopics.add(t);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingMedium, vertical: AppConfig.paddingSmall),
                        decoration: BoxDecoration(
                          color: active ? AppConfig.primaryColor.withOpacity(AppOpacity.low) : Colors.white.withOpacity(AppOpacity.trace),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppConfig.primaryColor : Colors.white.withOpacity(AppOpacity.veryLow),
                          ),
                        ),
                        child: Text(t,
                          style: TextStyle(
                            color: active ? AppConfig.primaryColor : Colors.white.withOpacity(AppOpacity.medium),
                            fontSize: AppConfig.fontSizeMedium, fontWeight: FontWeight.w600,
                          )),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: AppConfig.paddingSmall),
            _sectionHeader(AppConfig.textTrendingNow, Icons.local_fire_department, _trendingExpanded,
                () => setState(() => _trendingExpanded = !_trendingExpanded)),
            if (_trendingExpanded)
              ...provider.allItems.take(AppConfig.trendingItemsCount).map((item) => _newsRow(context, item, provider)),
            const SizedBox(height: AppConfig.paddingSmall),
            _sectionHeader(AppConfig.textTopStories, Icons.star, _topStoriesExpanded,
                () => setState(() => _topStoriesExpanded = !_topStoriesExpanded)),
            if (_topStoriesExpanded)
              ...provider.allItems.skip(AppConfig.trendingItemsCount).take(AppConfig.topStoriesItemsCount).map((item) => _newsRow(context, item, provider)),
          ])),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: AppConfig.fontSizeHuge, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppConfig.paddingSmall / 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(AppOpacity.low), fontSize: AppConfig.fontSizeSmall)),
      ]);

  Widget _sectionHeader(String title, IconData icon, bool expanded, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingLarge, vertical: AppConfig.paddingMedium),
          child: Row(children: [
            Icon(icon, color: AppConfig.primaryColor, size: AppConfig.iconSizeSmall),
            const SizedBox(width: AppConfig.paddingSmall),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: AppConfig.fontSizeLarge, fontWeight: FontWeight.w700)),
            const Spacer(),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(AppOpacity.low), size: AppConfig.iconSizeMedium),
          ]),
        ),
      );

  Widget _newsRow(BuildContext context, item, NewsProvider provider) => GestureDetector(
        onTap: () {
          final idx = provider.allItems.indexOf(item);
          if (idx != -1) provider.setCurrentIndex(idx);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingLarge, vertical: AppConfig.paddingSmall),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConfig.borderRadiusSmall),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: AppConfig.imagePreviewWidth, height: AppConfig.imagePreviewHeight, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: AppConfig.imagePreviewWidth, height: AppConfig.imagePreviewHeight,
                  color: Colors.white.withOpacity(AppOpacity.trace),
                  child: const Icon(Icons.image, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: AppConfig.paddingMedium),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.isRead ? Colors.white.withOpacity(AppOpacity.low) : Colors.white,
                    fontSize: AppConfig.fontSizeSmall, fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: AppConfig.paddingSmall / 2),
              TagChip(tag: item.tag),
            ])),
            Icon(Icons.open_in_new, color: Colors.white.withOpacity(AppOpacity.low), size: AppConfig.iconSizeSmall),
          ]),
        ),
      );
}