import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Renders a backend HTML document preview (invoice / receipt / waybill /
/// quotation) inside a WebView, laid out and scaled to match the downloaded
/// A4 PDF instead of reflowing responsively on the narrow phone screen.
///
/// The backend serves the same template for the HTML preview and the PDF. On
/// mobile the WebView would otherwise apply the responsive/device-width
/// viewport and stack the columns, so we force a fixed A4 page width and scale
/// the whole page down to fit — identical arrangement to the PDF, just smaller.
class PdfPreviewWebView extends StatefulWidget {
  const PdfPreviewWebView({
    super.key,
    required this.url,
    this.token,
    this.onLoadingChanged,
  });

  final Uri url;
  final String? token;
  final ValueChanged<bool>? onLoadingChanged;

  /// A4 portrait width at 96dpi — the canonical PDF page width.
  static const double pageWidth = 794;

  @override
  State<PdfPreviewWebView> createState() => _PdfPreviewWebViewState();
}

class _PdfPreviewWebViewState extends State<PdfPreviewWebView> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    if (!mounted) return;
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onLoadingChanged?.call(true),
          onPageFinished: (_) async {
            await _fitToWidth();
            widget.onLoadingChanged?.call(false);
          },
        ),
      );

    // Android ignores a fixed viewport width unless wide-viewport is enabled,
    // which is what makes the A4 template reflow instead of scaling.
    final platform = ctrl.platform;
    if (platform is AndroidWebViewController) {
      await platform.setUseWideViewPort(true);
      await platform.enableZoom(true);
    }

    if (!mounted) return;
    setState(() => _controller = ctrl);

    await ctrl.loadRequest(
      widget.url,
      headers: widget.token != null && widget.token!.isNotEmpty
          ? {'Authorization': 'Bearer ${widget.token}'}
          : const {},
    );
  }

  /// Injects a fixed-width viewport so the page lays out at A4 width and scales
  /// to fit the screen, mirroring the PDF layout exactly.
  Future<void> _fitToWidth() async {
    final ctrl = _controller;
    if (ctrl == null || !mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / PdfPreviewWebView.pageWidth)
        .clamp(0.1, 1.0)
        .toStringAsFixed(4);
    await ctrl.runJavaScript('''
      (function () {
        var v = document.querySelector('meta[name=viewport]');
        if (!v) {
          v = document.createElement('meta');
          v.setAttribute('name', 'viewport');
          (document.head || document.documentElement).appendChild(v);
        }
        v.setAttribute(
          'content',
          'width=${PdfPreviewWebView.pageWidth.toInt()}, initial-scale=$scale, minimum-scale=$scale, maximum-scale=5, user-scalable=yes'
        );
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    if (ctrl == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: ctrl);
  }
}
