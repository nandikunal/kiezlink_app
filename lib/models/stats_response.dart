class StatsResponse {
  final int read;
  final int unread;
  final int total;
  final int deduplicatedTotal;

  const StatsResponse({
    required this.read,
    required this.unread,
    required this.total,
    required this.deduplicatedTotal,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      read: (json['read'] as num).toInt(),
      unread: (json['unread'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      deduplicatedTotal: (json['deduplicated_total'] as num).toInt(),
    );
  }
}
