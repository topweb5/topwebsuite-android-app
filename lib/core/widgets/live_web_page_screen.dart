import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';

/// Full-screen WebView for a published business profile's public "live page"
/// (the responsive directory website). Unlike [PdfPreviewWebView] this does not
/// force an A4 width — the live page is already mobile-responsive.
///
/// The leading icon returns the user to the dashboard (`/`).
class LiveWebPageScreen extends StatefulWidget {
  const LiveWebPageScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<LiveWebPageScreen> createState() => _LiveWebPageScreenState();
}

class _LiveWebPageScreenState extends State<LiveWebPageScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _backToDashboard() {
    final router = GoRouter.of(context);
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: TopwebsuiteTheme.ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Dashboard',
          onPressed: _backToDashboard,
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: TopwebsuiteTheme.ink,
          ),
        ),
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: TopwebsuiteTheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  valueColor: const AlwaysStoppedAnimation(
                    TopwebsuiteTheme.primary,
                  ),
                ),
              )
            : const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: TopwebsuiteTheme.border),
              ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
