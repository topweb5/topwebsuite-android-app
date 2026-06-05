import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/file_service.dart';
import '../../../core/utils/api_shapes.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final billingBundleProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final results = await Future.wait([
    api.getMap('/api/billing/context/'),
    api.getList('/api/billing/plans/'),
    api.getMap('/api/billing/subscription/'),
    api.getList('/api/billing/invoices/'),
  ]);
  return {
    'context': results[0],
    'plans': results[1],
    'subscription': results[2],
    'invoices': results[3],
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(billingBundleProvider);

    return Scaffold(
      backgroundColor: TopwebsuiteTheme.surface,
      appBar: AppBar(
        title: const Text('Billing & Plans'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: TopwebsuiteTheme.border),
        ),
      ),
      body: bundle.when(
        data: (data) => RefreshIndicator(
          color: TopwebsuiteTheme.primary,
          onRefresh: () async => ref.invalidate(billingBundleProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SubscriptionPanel(
                subscription: _asMap(data['subscription']),
              ),
              const SizedBox(height: 16),
              _PlansSection(
                plans: _asList(data['plans']),
                subscription: _asMap(data['subscription']),
              ),
              const SizedBox(height: 16),
              _BillingHistoryPanel(
                invoices: _asList(data['invoices']),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 48, color: TopwebsuiteTheme.muted),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TopwebsuiteTheme.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(billingBundleProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  List<Map<String, dynamic>> _asList(Object? v) {
    if (v is! List) return [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

// ── Subscription panel ────────────────────────────────────────────────────────

class _SubscriptionPanel extends StatelessWidget {
  const _SubscriptionPanel({required this.subscription});
  final Map<String, dynamic> subscription;

  @override
  Widget build(BuildContext context) {
    final plan       = subscription['plan']?.toString() ?? 'Free';
    final status     = subscription['status']?.toString() ?? 'active';
    final renewal    = subscription['renewal_date']?.toString() ?? '';
    final usedRaw    = subscription['usage_used'];
    final limitRaw   = subscription['usage_limit'];
    final used       = (usedRaw as num?)?.toInt() ?? 0;
    final isUnlimited = limitRaw == null;
    final limit      = isUnlimited ? 0 : (limitRaw as num).toInt();
    final progress   = isUnlimited || limit == 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);

    final access = subscription['module_access'] is Map
        ? Map<String, dynamic>.from(subscription['module_access'] as Map)
        : <String, dynamic>{};

    return _BillingPanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PlanPill(plan: plan),
                const Spacer(),
                _StatusDot(status: status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              plan,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.03,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              renewal.isEmpty
                  ? 'No expiry date'
                  : 'Renews $renewal',
              style: const TextStyle(
                fontSize: 12,
                color: TopwebsuiteTheme.muted,
              ),
            ),
            const SizedBox(height: 16),

            // Usage bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Document usage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TopwebsuiteTheme.muted,
                  ),
                ),
                Text(
                  isUnlimited ? 'Unlimited' : '$used / $limit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TopwebsuiteTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFD6E2FB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.85
                      ? TopwebsuiteTheme.warning
                      : TopwebsuiteTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Module access grid
            const Text(
              'MODULE ACCESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModuleChip(
                    label: 'Documents',
                    enabled: access['documents'] == true),
                _ModuleChip(
                    label: 'CRM', enabled: access['crm'] == true),
                _ModuleChip(
                    label: 'ERP', enabled: access['erp'] == true),
                const _ModuleChip(
                    label: 'Business Profile', enabled: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan});
  final String plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TopwebsuiteTheme.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 12, color: TopwebsuiteTheme.primary),
          const SizedBox(width: 5),
          Text(
            plan,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive
                  ? TopwebsuiteTheme.success
                  : TopwebsuiteTheme.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? TopwebsuiteTheme.success
                  : TopwebsuiteTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label, required this.enabled});
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? const Color(0xFFBBF7D0)
              : TopwebsuiteTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 13,
            color: enabled
                ? TopwebsuiteTheme.success
                : TopwebsuiteTheme.muted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? TopwebsuiteTheme.success
                  : TopwebsuiteTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plans section ─────────────────────────────────────────────────────────────

class _PlansSection extends ConsumerWidget {
  const _PlansSection({required this.plans, required this.subscription});
  final List<Map<String, dynamic>> plans;
  final Map<String, dynamic> subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSlug = subscription['plan_slug']?.toString() ??
        subscription['plan']?.toString().toLowerCase() ??
        'free';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLANS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 10),
        if (plans.isEmpty)
          _BillingPanel(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No plans available at this time.',
                style: TextStyle(color: TopwebsuiteTheme.muted),
              ),
            ),
          )
        else
          for (final plan in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlanCard(
                plan: plan,
                isCurrent: _isCurrent(plan, currentSlug),
                onSelect: () => _checkout(context, ref, plan),
              ),
            ),
      ],
    );
  }

  bool _isCurrent(Map<String, dynamic> plan, String currentSlug) {
    final slug = plan['slug']?.toString().toLowerCase() ?? '';
    return slug == currentSlug || slug.contains(currentSlug);
  }

  Future<void> _checkout(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> plan,
  ) async {
    final slug = plan['slug']?.toString() ?? '';
    if (slug.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.postMap('/api/billing/checkout/', {
        'plan_slug': slug,
        'success_url': 'https://topwebsuite.online/pricing/?status=successful',
        'cancel_url': 'https://topwebsuite.online/pricing/?status=cancelled',
      });
      final url = stringValue(response, [
        'checkout_url',
        'authorization_url',
        'url',
      ]);
      if (url.isEmpty || !context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CheckoutWebView(url: url)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  final Map<String, dynamic> plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final name     = plan['name']?.toString() ?? plan['slug']?.toString() ?? 'Plan';
    final price    = plan['price']?.toString() ?? '0.00';
    final currency = plan['currency']?.toString() ?? '';
    final interval = plan['billing_interval']?.toString() ?? 'monthly';
    final docLimit = plan['document_limit'];
    final features = plan['features'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? TopwebsuiteTheme.primary : TopwebsuiteTheme.border,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? TopwebsuiteTheme.primary.withValues(alpha: 0.1)
                : const Color(0x05024EE0),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: TopwebsuiteTheme.ink,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TopwebsuiteTheme.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TopwebsuiteTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$currency $price',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TopwebsuiteTheme.ink,
                      letterSpacing: -0.02,
                    ),
                  ),
                  TextSpan(
                    text: ' / $interval',
                    style: const TextStyle(
                      fontSize: 13,
                      color: TopwebsuiteTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              docLimit == null
                  ? 'Unlimited documents'
                  : '$docLimit documents/month',
              style: const TextStyle(
                fontSize: 12,
                color: TopwebsuiteTheme.muted,
              ),
            ),
            if (features is List && features.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final f in features.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 14, color: TopwebsuiteTheme.success),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          f.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: TopwebsuiteTheme.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Active Plan'),
                    )
                  : ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: TopwebsuiteTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Select Plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Billing history ───────────────────────────────────────────────────────────

class _BillingHistoryPanel extends ConsumerWidget {
  const _BillingHistoryPanel({required this.invoices});
  final List<Map<String, dynamic>> invoices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BillingPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing History',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            if (invoices.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TopwebsuiteTheme.border),
                ),
                child: const Text(
                  'No billing history yet.',
                  style: TextStyle(
                    color: TopwebsuiteTheme.muted,
                    fontSize: 13,
                  ),
                ),
              )
            else
              for (final inv in invoices)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: TopwebsuiteTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAF0F7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: TopwebsuiteTheme.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_outlined,
                            size: 16, color: TopwebsuiteTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${inv['reference'] ?? inv['id'] ?? '—'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TopwebsuiteTheme.ink,
                              ),
                            ),
                            Text(
                              '${inv['currency'] ?? ''} ${inv['amount'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: TopwebsuiteTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 18),
                        color: TopwebsuiteTheme.primary,
                        onPressed: () => ref
                            .read(fileServiceProvider)
                            .openPdf(
                              '/api/billing/invoices/${inv['id']}/download/',
                              'billing-${inv['id']}.pdf',
                            ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _BillingPanel extends StatelessWidget {
  const _BillingPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06024EE0),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Checkout webview ───────────────────────────────────────────────────────────

class CheckoutWebView extends StatefulWidget {
  const CheckoutWebView({super.key, required this.url});
  final String url;

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
