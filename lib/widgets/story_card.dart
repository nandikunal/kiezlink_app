import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../models/news_item.dart';
import '../data/news_provider.dart';
import '../utils/utils.dart';
import 'tag_chip.dart';

class StoryCard extends StatefulWidget {
  final NewsItem item;
  final int index;
  final int total;

  const StoryCard({
    super.key,
    required this.item,
    required this.index,
    required this.total,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final item = widget.item;
    // Respect system bottom padding (nav bar) so text is never hidden.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // ── TOP: image section (fills ~60% of screen) ─────────────────────
        Expanded(
          flex: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero image
              if (ValidationUtils.isValidImageUrl(item.imageUrl))
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF1C1917)),
                  errorWidget: (_, __, ___) => _imageFallback(),
                )
              else
                _imageFallback(),

              // Subtle bottom fade so image bleeds into text panel
              Positioned(
                left: 0, right: 0, bottom: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppConfig.backgroundColor.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Source badge + counter row (top-left / top-right) ────────
              Positioned(
                top: MediaQuery.of(context).padding.top +
                    AppConfig.paddingMedium,
                left: AppConfig.paddingLarge,
                right: AppConfig.paddingLarge,
                child: Row(
                  children: [
                    // Source pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConfig.paddingSmall,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: AppOpacity.medium),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.source,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppConfig.fontSizeXSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Story counter  e.g.  7 / 20
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConfig.paddingMedium,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: AppOpacity.medium),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.index + 1} / ${widget.total}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppConfig.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right side action buttons ────────────────────────────────
              Positioned(
                right: AppConfig.paddingMedium,
                bottom: AppConfig.paddingXLarge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sideBtn(
                      item.isLiked ? Icons.favorite : Icons.favorite_border,
                      item.isLiked ? Colors.red : Colors.white,
                      () => provider.toggleLike(item.id),
                    ),
                    const SizedBox(height: AppConfig.paddingLarge),
                    _sideBtn(
                      item.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      item.isBookmarked
                          ? AppConfig.primaryColor
                          : Colors.white,
                      () => provider.toggleBookmark(item.id),
                    ),
                    const SizedBox(height: AppConfig.paddingLarge),
                    _sideBtn(Icons.share, Colors.white, () {}),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── BOTTOM: solid text panel (~40% of screen) ─────────────────────
        // This section has a fixed dark background — nav bar will never
        // overlap content because we add bottomInset padding at the very end.
        Expanded(
          flex: 40,
          child: Container(
            width: double.infinity,
            color: AppConfig.backgroundColor,
            padding: EdgeInsets.fromLTRB(
              AppConfig.paddingLarge,
              AppConfig.paddingMedium,
              AppConfig.paddingLarge,
              AppConfig.paddingMedium + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Meta row: feed label + topic tag + time ──────────────
                Row(
                  children: [
                    // Feed source label  e.g.  • NYT > Top S...
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(
                          right: AppConfig.paddingSmall),
                      decoration: const BoxDecoration(
                        color: AppConfig.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        item.source,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white
                              .withValues(alpha: AppOpacity.medium),
                          fontSize: AppConfig.fontSizeSmall,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConfig.paddingSmall),
                    TagChip(tag: item.tag),
                    const Spacer(),
                    // Bookmark / read badge
                    if (item.isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConfig.successColor
                              .withValues(alpha: AppOpacity.low),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          AppConfig.textRead,
                          style: TextStyle(
                            color: AppConfig.successColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppConfig.paddingSmall),

                // ── Headline ─────────────────────────────────────────────
                Expanded(
                  child: AnimatedCrossFade(
                    duration: AppConfig.animationDurationNormal,
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppConfig.fontSizeXXLarge,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppConfig.paddingSmall),
                        Text(
                          item.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: AppOpacity.medium),
                            fontSize: AppConfig.fontSizeMedium,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    secondChild: SingleChildScrollView(
                      child: Text(
                        item.content,
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: AppOpacity.high),
                          fontSize: AppConfig.fontSizeMedium,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConfig.paddingSmall),

                // ── Bottom action row ─────────────────────────────────────
                Row(
                  children: [
                    // Time ago
                    Text(
                      DateTimeUtils.timeAgo(item.publishedAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: AppOpacity.low),
                        fontSize: AppConfig.fontSizeSmall,
                      ),
                    ),
                    const Spacer(),
                    _actionBtn(
                      _expanded ? Icons.unfold_less : Icons.unfold_more,
                      _expanded ? AppConfig.textLess : AppConfig.textMore,
                      () => setState(() => _expanded = !_expanded),
                    ),
                    const SizedBox(width: AppConfig.paddingSmall),
                    // "Tap to know more" styled button
                    _actionBtn(
                      Icons.open_in_browser,
                      AppConfig.textFullStory,
                      () => _launch(item.sourceUrl),
                      color: AppConfig.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Widget _imageFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1917), Color(0xFF292524)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.article,
            color: Colors.white24,
            size: AppConfig.iconSizeGiant,
          ),
        ),
      );

  Widget _sideBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppOpacity.medium),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: AppOpacity.veryLow),
            ),
          ),
          child: Icon(icon, color: color, size: AppConfig.iconSizeLarge),
        ),
      );

  Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingMedium,
            vertical: AppConfig.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: (color ?? Colors.white)
                .withValues(alpha: AppOpacity.veryLow),
            borderRadius:
                BorderRadius.circular(AppConfig.borderRadiusSmall),
            border: Border.all(
              color: (color ?? Colors.white)
                  .withValues(alpha: AppOpacity.veryLow),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: color ?? Colors.white,
                size: AppConfig.iconSizeSmall),
            const SizedBox(width: AppConfig.paddingSmall),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: AppConfig.fontSizeMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
      );

  Future<void> _launch(String url) async {
    try {
      if (url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(AppConfig.errorUrlNotAvailable)),
          );
        }
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(AppConfig.errorCouldNotOpenUrl)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppConfig.errorFailedToOpenUrl)),
        );
      }
    }
  }
}
