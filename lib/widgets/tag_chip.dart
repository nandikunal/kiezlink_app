import 'package:flutter/material.dart';
import '../config/constants.dart';

class TagChip extends StatelessWidget {
  final String tag;

  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    if (tag.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingSmall,
        vertical: AppConfig.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(AppOpacity.low),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontSize: AppConfig.fontSizeXSmall,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
