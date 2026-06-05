import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          child: Image.asset(
            'assets/images/topwebsuite-favicon.png',
            width: compact ? 34 : 44,
            height: compact ? 34 : 44,
            fit: BoxFit.contain,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Text(
            'Topwebsuite',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
        ],
      ],
    );
  }
}
