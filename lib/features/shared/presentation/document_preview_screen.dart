import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/file_service.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../../core/widgets/pdf_preview_webview.dart';
import 'print_service.dart';

// ── Document Preview Screen ───────────────────────────────────────────────────
//
// Shows the backend HTML preview in a WebView with a bottom action bar:
//   Download PDF | Share | Edit | Delete
//
// Call DocumentPreviewScreen.push(context, ...) after a successful save.

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.title,
    required this.previewPath,
    required this.downloadPath,
    required this.docId,
    required this.docType,
  });

  final String title;
  final String previewPath;
  final String downloadPath;
  final String docId;
  final String docType;

  static void push(
    BuildContext context, {
    required String title,
    required String previewPath,
    required String downloadPath,
    required String docId,
    required String docType,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DocumentPreviewScreen(
          title: title,
          previewPath: previewPath,
          downloadPath: downloadPath,
          docId: docId,
          docType: docType,
        ),
      ),
    );
  }

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  Uri? _url;
  String? _token;
  bool _loading = true;
  bool _printing = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initWebView);
  }

  Future<void> _initWebView() async {
    if (!mounted) return;
    final token = await ref.read(secureTokenStoreProvider).readAccessToken();
    final baseUrl = ref
        .read(dioProvider)
        .options
        .baseUrl
        .replaceAll(RegExp(r'/$'), '');
    if (!mounted) return;
    setState(() {
      _token = token;
      _url = Uri.parse('$baseUrl${widget.previewPath}');
    });
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await ref
          .read(fileServiceProvider)
          .openPdf(
            widget.downloadPath,
            '${widget.docType}-${widget.docId}.pdf',
          );
    } catch (e) {
      _snack('Download failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share() async {
    try {
      final file = await ref
          .read(fileServiceProvider)
          .downloadPdf(
            widget.downloadPath,
            '${widget.docType}-${widget.docId}.pdf',
          );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: widget.title),
      );
    } catch (e) {
      _snack('Share failed: $e', error: true);
    }
  }

  Future<void> _print() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PrintChooserSheet(),
    );
    if (choice == null || !mounted) return;

    setState(() => _printing = true);
    try {
      final svc = ref.read(printServiceProvider);
      if (choice == 'thermal') {
        await svc.printThermal(docType: widget.docType, docId: widget.docId);
      } else {
        await svc.printStandard(
          widget.downloadPath,
          '${widget.docType}-${widget.docId}.pdf',
        );
      }
    } catch (e) {
      _snack('Print failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error
            ? TopwebsuiteTheme.danger
            : TopwebsuiteTheme.success,
      ),
    );
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
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: TopwebsuiteTheme.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
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
      body: _url == null
          ? const Center(
              child: CircularProgressIndicator(color: TopwebsuiteTheme.primary),
            )
          : PdfPreviewWebView(
              url: _url!,
              token: _token,
              onLoadingChanged: (v) {
                if (mounted) setState(() => _loading = v);
              },
            ),
      bottomNavigationBar: _ActionBar(
        downloading: _downloading,
        printing: _printing,
        onDownload: _download,
        onShare: _share,
        onPrint: _print,
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.downloading,
    required this.printing,
    required this.onDownload,
    required this.onShare,
    required this.onPrint,
  });

  final bool downloading;
  final bool printing;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TopwebsuiteTheme.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: downloading ? null : Icons.download_rounded,
              loading: downloading,
              label: 'Download PDF',
              primary: true,
              onTap: downloading ? null : onDownload,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: onShare,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: printing ? null : Icons.print_rounded,
              loading: printing,
              label: 'Print',
              onTap: printing ? null : onPrint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Print chooser sheet ───────────────────────────────────────────────────────

class _PrintChooserSheet extends StatelessWidget {
  const _PrintChooserSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TopwebsuiteTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Print options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose how you want to print this document.',
            style: TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted),
          ),
          const SizedBox(height: 16),
          _PrintOptionTile(
            icon: Icons.description_outlined,
            title: 'Standard',
            subtitle: 'Full layout, prints as designed.',
            onTap: () => Navigator.pop(context, 'standard'),
          ),
          const SizedBox(height: 10),
          _PrintOptionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Thermal',
            subtitle: '80mm black & white roll receipt.',
            onTap: () => Navigator.pop(context, 'thermal'),
          ),
        ],
      ),
    );
  }
}

class _PrintOptionTile extends StatelessWidget {
  const _PrintOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TopwebsuiteTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TopwebsuiteTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TopwebsuiteTheme.primarySoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: TopwebsuiteTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TopwebsuiteTheme.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TopwebsuiteTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: TopwebsuiteTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    if (primary) {
      bg = TopwebsuiteTheme.primary;
      fg = Colors.white;
      border = TopwebsuiteTheme.primary;
    } else {
      bg = Colors.white;
      fg = TopwebsuiteTheme.ink;
      border = TopwebsuiteTheme.border;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: fg),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
