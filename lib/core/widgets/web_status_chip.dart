import 'package:flutter/material.dart';

import '../../app/theme.dart';

class WebStatusChip extends StatelessWidget {
  const WebStatusChip({
    super.key,
    required this.label,
    this.tone = WebStatusTone.draft,
  });

  final String label;
  final WebStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      WebStatusTone.success => TopwebsuiteTheme.success,
      WebStatusTone.warning => TopwebsuiteTheme.warning,
      WebStatusTone.danger => TopwebsuiteTheme.danger,
      WebStatusTone.draft => TopwebsuiteTheme.primary,
    };
    final background = switch (tone) {
      WebStatusTone.success => const Color(0xFFF0FDF4),
      WebStatusTone.warning => const Color(0xFFFFFBEB),
      WebStatusTone.danger => const Color(0xFFFEF2F2),
      WebStatusTone.draft => TopwebsuiteTheme.primarySoft,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

enum WebStatusTone { success, warning, danger, draft }
