import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/constants.dart';

typedef OnNewStories = void Function(int count);

/// Lightweight SSE / long-poll listener for /v1/today/updates.
/// Reconnects automatically on error while the app is in the foreground.
/// Call [stop] when the app goes to background.
class SseService {
  StreamSubscription? _sub;
  Timer? _pollTimer;
  bool _running = false;
  DateTime? _lastCheckedAt;
  final OnNewStories onNewStories;

  SseService({required this.onNewStories});

  void start() {
    if (_running) return;
    _running = true;
    _lastCheckedAt = DateTime.now().toUtc();
    // Poll every 30 seconds
    _pollTimer = Timer.periodic(
      const Duration(seconds: AppConfig.ssePollingIntervalSeconds),
      (_) => _poll(),
    );
    developer.log('SSE polling started', name: 'SseService');
  }

  void stop() {
    _running = false;
    _pollTimer?.cancel();
    _sub?.cancel();
    developer.log('SSE polling stopped', name: 'SseService');
  }

  Future<void> _poll() async {
    if (!_running) return;
    final since = _lastCheckedAt ?? DateTime.now().toUtc();
    try {
      final uri = Uri.parse(
        '${AppConfig.apiUpdatesUrl}?since=${Uri.encodeComponent(since.toIso8601String())}',
      );
      final response = await http
          .get(uri, headers: {
            'accept': 'application/json',
            'X-API-Key': AppConfig.apiKey,
          })
          .timeout(const Duration(seconds: 10));

      _lastCheckedAt = DateTime.now().toUtc();

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final count = (data['total_new'] as int?) ?? 0;
        if (count > 0) {
          developer.log('SSE: $count new stories', name: 'SseService');
          onNewStories(count);
        }
      }
    } catch (e) {
      developer.log('SSE poll error: $e', name: 'SseService');
    }
  }
}
