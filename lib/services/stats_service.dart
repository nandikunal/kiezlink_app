import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class FeedStats {
  final int read;
  final int unread;
  final int total;

  const FeedStats({required this.read, required this.unread, required this.total});

  factory FeedStats.fromJson(Map<String, dynamic> j) => FeedStats(
        read: (j['read'] as int?) ?? 0,
        unread: (j['unread'] as int?) ?? 0,
        total: (j['deduplicated_total'] as int?) ??
            (j['total'] as int?) ??
            0,
      );

  factory FeedStats.empty() =>
      const FeedStats(read: 0, unread: 0, total: 0);
}

class StatsService {
  static Future<FeedStats> fetch() async {
    try {
      final uri = Uri.parse(AppConfig.apiStatsUrl);
      final response = await http
          .get(uri, headers: {
            'accept': 'application/json',
            'X-API-Key': AppConfig.apiKey,
          })
          .timeout(const Duration(seconds: AppConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FeedStats.fromJson(data);
      }
      developer.log('Stats API ${response.statusCode}', name: 'StatsService');
      return FeedStats.empty();
    } catch (e) {
      developer.log('Stats fetch error: $e', name: 'StatsService');
      return FeedStats.empty();
    }
  }
}
