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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero image
        if (ValidationUtils.isValidImageUrl(item.imageUrl))
          CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF1C1917)),
            errorWidget: (_, __, ___) => _imageFallback(),
          )
        else
          _imageFallback(),

        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.97),
              ],
              stops: GradientStops.cardGradient,
            ),
          ),
        ),

        // Main content bottom-left
        Positioned(
          left: 0,
          right: 60,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConfig.paddingXLarge,
              0,
              AppConfig.paddingXLarge,
              AppConfig.paddingXLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingSmall,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: AppOpacity.veryLow),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: AppOpacity.veryLow),
                      ),
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
                  const SizedBox(width: AppConfig.paddingSmall),
                  Text(
                    DateTimeUtils.timeAgo(item.publishedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: AppOpacity.medium),
                      fontSize: AppConfig.fontSizeXSmall,
                    ),
                  ),
                  const Spacer(),
                  if (item.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConfig.paddingSmall / 2,
                        vertical: 2,
                      ),
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
                ]),
                const SizedBox(height: AppConfig.paddingMedium),
                TagChip(tag: item.tag),
                const SizedBox(height: AppConfig.paddingMedium),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppConfig.fontSizeGiant,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                AnimatedCrossFade(
                  duration: AppConfig.animationDurationNormal,
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    item.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: AppOpacity.high),
                      fontSize: AppConfig.fontSizeLarge,
                      height: 1.5,
                    ),
                  ),
                  secondChild: Text(
                    item.content,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: AppOpacity.high),
                      fontSize: AppConfig.fontSizeLarge,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                Row(children: [
                  _actionBtn(
                    _expanded ? Icons.unfold_less : Icons.unfold_more,
                    _expanded ? AppConfig.textLess : AppConfig.textMore,
                    () => setState(() => _expanded = !_expanded),
                  ),
                  const SizedBox(width: AppConfig.paddingSmall),
                  _actionBtn(
                    Icons.open_in_browser,
                    AppConfig.textFullStory,
                    () => _launch(item.sourceUrl),
                    color: AppConfig.primaryColor,
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Right side action buttons
        Positioned(
          right: AppConfig.paddingMedium,
          bottom: 120,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sideBtn(
              item.isLiked ? Icons.favorite : Icons.favorite_border,
              item.isLiked ? Colors.red : Colors.white,
              () => provider.toggleLike(item.id),
            ),
            const SizedBox(height: AppConfig.paddingXLarge),
            _sideBtn(
              item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              item.isBookmarked ? AppConfig.primaryColor : Colors.white,
              () => provider.toggleBookmark(item.id),
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            // ── Deduplicated total counter next to bookmark ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: AppOpacity.low),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.index + 1}/${provider.totalCount > 0 ? provider.totalCount : widget.total}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: AppOpacity.medium),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppConfig.paddingXLarge),
            _sideBtn(Icons.share, Colors.white, () {}),
          ]),
        ),

        // Story counter pill (top-left)
        Positioned(
          top: 104,
          left: AppConfig.paddingLarge,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.paddingMedium,
              vertical: AppConfig.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: AppOpacity.medium),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: AppOpacity.veryLow),
              ),
            ),
            child: Text(
              '${widget.index + 1} / ${provider.totalCount > 0 ? provider.totalCount : widget.total}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppConfig.fontSizeMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
            color: Colors.black.withValues(alpha: AppOpacity.low),
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
            color: (color ?? Colors.white).withValues(alpha: AppOpacity.veryLow),
            borderRadius: BorderRadius.circular(AppConfig.borderRadiusSmall),
            border: Border.all(
              color: (color ?? Colors.white).withValues(alpha: AppOpacity.veryLow),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color ?? Colors.white, size: AppConfig.iconSizeSmall),
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
            const SnackBar(content: Text(AppConfig.errorUrlNotAvailable)),
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
            const SnackBar(content: Text(AppConfig.errorCouldNotOpenUrl)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConfig.errorFailedToOpenUrl)),
        );
      }
    }
  }
}
