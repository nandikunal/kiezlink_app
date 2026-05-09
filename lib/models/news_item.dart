class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final String source;
  final String sourceUrl;
  final DateTime publishedAt;
  final String category;
  final String tag;
  final DateTime? eventDate;
  bool isRead;
  bool isLiked;
  bool isBookmarked;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.source,
    required this.sourceUrl,
    required this.publishedAt,
    required this.category,
    required this.tag,
    this.eventDate,
    this.isRead = false,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}