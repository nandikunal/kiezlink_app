import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/news_provider.dart';
import '../services/location_service.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final news = context.watch<NewsProvider>();
    final loc = context.watch<LocationService>();
    final stats = news.stats;

    return Drawer(
      backgroundColor: const Color(0xFF1C1B19),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE8960A),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFE8960A), size: 13),
                            const SizedBox(width: 3),
                            Text(
                              loc.displayCity,
                              style: const TextStyle(
                                color: Color(0xFFE8960A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats row (Read / Unread / Total) ─────────────────
            if (stats != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262523),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                          label: 'Read',
                          count: stats.read,
                          color: const Color(0xFF4F98A3)),
                      _divider(),
                      _StatChip(
                          label: 'Unread',
                          count: stats.unread,
                          color: const Color(0xFFE8960A)),
                      _divider(),
                      _StatChip(
                          label: 'Total',
                          count: stats.deduplicatedTotal,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // ── My Feed label ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'My Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Spacer(),
                  if (!news.allTopicsSelected)
                    GestureDetector(
                      onTap: () => news.selectAllTopics(),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                            color: Color(0xFF4F98A3), fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Topic filter chips ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllTopics.map((topic) {
                  final isSelected = news.selectedTopics.contains(topic);
                  return GestureDetector(
                    onTap: () => news.toggleTopic(topic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8960A)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE8960A)
                              : Colors.white30,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _capitalize(topic),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                news.allTopicsSelected
                    ? 'All topics are loaded. Pull to refresh for new stories.'
                    : '${news.selectedTopics.length} of ${kAllTopics.length} topics selected.',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ),

            const Spacer(),

            // ── Settings link ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined,
                    color: Colors.white38, size: 20),
                title: const Text('Settings',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 32,
        width: 1,
        color: Colors.white12,
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style:
              const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
