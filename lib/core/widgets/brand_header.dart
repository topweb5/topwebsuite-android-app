import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// Shared brand-gradient screen header (back button + centred title) used by
/// pushed full screens such as Account & Settings and Billing & Plans so they
/// share the same chrome instead of a plain Material [AppBar].
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  /// Optional trailing widget (kept square so the title stays centred).
  final Widget? trailing;

  /// Pops when there is a route to pop (screen was pushed); otherwise falls
  /// back to the dashboard (e.g. when reached via the drawer with `context.go`,
  /// which leaves no back stack).
  void _defaultBack(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, topInset + 10, 8, 18),
      decoration: const BoxDecoration(
        gradient: TopwebsuiteTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => _defaultBack(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}
