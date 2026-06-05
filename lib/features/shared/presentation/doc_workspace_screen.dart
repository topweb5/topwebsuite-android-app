import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/services/file_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../../core/utils/api_shapes.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/application/auth_controller.dart';
import '../data/resource_repository.dart';
import '../domain/field_config.dart';
import '../domain/resource_config.dart';
import 'resource_workspace_screen.dart'
    show BackendPreviewScreen, resourceListProvider;

// ── Document workspace screen ─────────────────────────────────────────────────

class DocWorkspaceScreen extends ConsumerStatefulWidget {
  const DocWorkspaceScreen({
    super.key,
    required this.config,
    this.letterheadConfig,
  });

  /// Main resource config (invoices / receipts / waybills / quotations / letters)
  final ResourceConfig config;

  /// Extra config used only for letterhead screen to load letterhead count
  final ResourceConfig? letterheadConfig;

  @override
  ConsumerState<DocWorkspaceScreen> createState() => _DocWorkspaceScreenState();
}

class _DocWorkspaceScreenState extends ConsumerState<DocWorkspaceScreen> {
  String _statusFilter = 'all';
  String _sortOrder   = 'newest';
  String _search      = '';

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(resourceListProvider(widget.config));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF024EE0), Color(0xFF024EE0), Color(0xFFFFFFFF)],
          stops: [0.0, 0.15, 0.55],
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const _WorkspaceDrawer(),
      bottomNavigationBar: _CreateBar(
        label: _createLabel,
        onTap: () => _openForm(context, null),
        extra: widget.letterheadConfig != null
            ? _ExtraCreateBtn(
                label: 'Create Letterhead',
                onTap: () => _openForm(context, null, secondary: true),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: TopwebsuiteTheme.primary,
        onRefresh: () async {
          ref.invalidate(resourceListProvider(widget.config));
          if (widget.letterheadConfig != null) {
            ref.invalidate(resourceListProvider(widget.letterheadConfig!));
          }
        },
        child: CustomScrollView(
          slivers: [
            // ── Top bar
            SliverToBoxAdapter(
              child: Builder(builder: (ctx) => _WorkspaceTopBar(
                placeholder: _searchPlaceholder,
                onSearch: (v) => setState(() => _search = v),
              )),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 1, color: TopwebsuiteTheme.border),
            ),

            // ── Stats grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: rows.when(
                  data: (items) {
                    final lhCount = widget.letterheadConfig != null
                        ? (ref.watch(resourceListProvider(widget.letterheadConfig!)).value?.length ?? 0)
                        : 0;
                    return _StatsGrid(
                      docKey: widget.config.key,
                      items: items,
                      letterheadCount: lhCount,
                    );
                  },
                  loading: () => _shimmer(160),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Management card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _ManagementCard(
                  title: _managementTitle,
                  subtitle: _managementSubtitle,
                  createLabel: _createLabel,
                  showLetterheadBtn: widget.letterheadConfig != null,
                  onFilter: _showFilterSheet,
                  onCreate: () => _openForm(context, null),
                  onCreateLetterhead: () => _openForm(context, null, secondary: true),
                ),
              ),
            ),

            // ── Filter bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _FilterBar(
                  statusOptions: _statusOptions,
                  selectedStatus: _statusFilter,
                  sortOrder: _sortOrder,
                  search: _search,
                  onStatusChanged: (v) => setState(() => _statusFilter = v),
                  onSortChanged: (v) => setState(() => _sortOrder = v),
                  onSearchChanged: (v) => setState(() => _search = v),
                  searchPlaceholder: _searchPlaceholder,
                ),
              ),
            ),

            // ── Document list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: rows.when(
                  data: (items) {
                    final filtered = _applyFilters(items);
                    if (filtered.isEmpty) return _emptyState;
                    return Column(
                      children: [
                        for (final row in filtered)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DocCard(
                              config: widget.config,
                              row: row,
                              numberKey: _numberKey,
                              nameKey: _nameKey,
                              onEdit: () => _openForm(context, row),
                              onRefresh: () => ref.invalidate(resourceListProvider(widget.config)),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => _shimmer(280),
                  error: (e, _) => _errorState(e.toString()),
                ),
              ),
            ),

            // ── Tips section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TipsCard(docKey: widget.config.key),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      ),   // closes Scaffold
    );     // closes Container gradient wrapper
  }

  // ── Per-type config ─────────────────────────────────────────────────────────

  String get _managementTitle => _kManagementTitles[widget.config.key]?.$1
      ?? '${widget.config.title} Management';

  String get _managementSubtitle => _kManagementTitles[widget.config.key]?.$2
      ?? 'View, filter and manage your ${widget.config.title.toLowerCase()}.';

  String get _createLabel => _kCreateLabels[widget.config.key]
      ?? 'Create ${widget.config.title}';

  String get _searchPlaceholder => _kSearchPlaceholders[widget.config.key]
      ?? 'Search ${widget.config.title.toLowerCase()}...';

  List<String> get _statusOptions =>
      _kStatusOptions[widget.config.key] ?? const ['all'];

  String get _numberKey => _kNumberKeys[widget.config.key] ?? 'title';
  String get _nameKey   => _kNameKeys[widget.config.key]   ?? 'client_name';

  // ── Filtering ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    var result = items.whereType<Map<String, dynamic>>().toList();

    if (_statusFilter != 'all') {
      result = result.where((r) =>
          r['status']?.toString().toLowerCase() == _statusFilter ||
          r['payment_method']?.toString().toLowerCase() == _statusFilter ||
          r['delivery_status']?.toString().toLowerCase() == _statusFilter
      ).toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((r) {
        for (final key in [...widget.config.titleKeys, _nameKey]) {
          if (r[key]?.toString().toLowerCase().contains(q) == true) return true;
        }
        return false;
      }).toList();
    }

    if (_sortOrder == 'oldest') {
      result = result.reversed.toList();
    }

    return result;
  }

  // ── Form bottom sheet ───────────────────────────────────────────────────────

  Future<void> _openForm(
    BuildContext context,
    Map<String, dynamic>? row, {
    bool secondary = false,
  }) async {
    final cfg = secondary ? widget.letterheadConfig! : widget.config;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DocForm(config: cfg, row: row),
    );
    if (saved == true) {
      ref.invalidate(resourceListProvider(cfg));
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        statusOptions: _statusOptions,
        selectedStatus: _statusFilter,
        sortOrder: _sortOrder,
        onApply: (status, sort) {
          setState(() {
            _statusFilter = status;
            _sortOrder    = sort;
          });
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget get _emptyState => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TopwebsuiteTheme.border),
    ),
    child: Column(
      children: [
        Icon(Icons.folder_open_outlined,
            size: 44, color: TopwebsuiteTheme.primary.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('No records yet',
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: TopwebsuiteTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text('Create your first record or check from the web app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted),
        ),
      ],
    ),
  );

  Widget _errorState(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFCA5A5)),
    ),
    child: Text(msg,
      style: const TextStyle(fontSize: 12, color: TopwebsuiteTheme.danger)),
  );

  Widget _shimmer(double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

// ── Static configs per doc type ───────────────────────────────────────────────

const _kManagementTitles = <String, (String, String)>{
  'invoices':   ('Invoice Management',    'View, filter and manage your created invoices.'),
  'receipts':   ('Receipt Management',    'Create, preview, download and update payment receipts.'),
  'waybills':   ('Waybill Management',    'Create, track and print shipment waybills from one workspace.'),
  'quotations': ('Quotation Workspace',   'Create, preview, download and update quotations with the invoice-style workflow.'),
  'letters':    ('Letter Workspace',      'Create and manage branded letters with a focused writing flow.'),
};

const _kCreateLabels = <String, String>{
  'invoices':   'Create Invoice',
  'receipts':   'Create Receipt',
  'waybills':   'Create Waybill',
  'quotations': 'Create Quotation',
  'letters':    'Write Letter',
};

const _kSearchPlaceholders = <String, String>{
  'invoices':   'Invoice no, client name, business name...',
  'receipts':   'Receipt no, payer name, business name...',
  'waybills':   'Waybill no, sender, recipient, shipment...',
  'quotations': 'Quotation no, client, company, reference...',
  'letters':    'Letter title, recipient...',
};

const _kStatusOptions = <String, List<String>>{
  'invoices':   ['all', 'paid', 'pending', 'draft', 'overdue'],
  'receipts':   ['all', 'cash', 'transfer', 'cheque', 'card'],
  'waybills':   ['all', 'pending', 'shipped', 'delivered'],
  'quotations': ['all', 'open', 'accepted', 'expired', 'draft'],
  'letters':    ['all', 'draft', 'final'],
};

const _kNumberKeys = <String, String>{
  'invoices':   'invoice_number',
  'receipts':   'receipt_number',
  'waybills':   'waybill_number',
  'quotations': 'quotation_number',
  'letters':    'title',
};

const _kNameKeys = <String, String>{
  'invoices':   'client_name',
  'receipts':   'received_from',
  'waybills':   'recipient_name',
  'quotations': 'client_name',
  'letters':    'plain_text',
};

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.docKey,
    required this.items,
    this.letterheadCount = 0,
  });

  final String docKey;
  final List<Map<String, dynamic>> items;
  final int letterheadCount;

  @override
  Widget build(BuildContext ctx) {
    final specs = _buildSpecs();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.42,
      ),
      itemCount: 4,
      itemBuilder: (_, i) => _StatCard(spec: specs[i]),
    );
  }

  List<_StatSpec> _buildSpecs() {
    final count = items.length;
    switch (docKey) {
      case 'invoices':
        final total  = _sumField(items, 'total');
        final paid   = _countWhere(items, 'status', 'paid');
        final pend   = _countWhere(items, 'status', 'pending');
        final curr   = _firstCurrency(items);
        return [
          _StatSpec(Icons.receipt_long_outlined,  'Live',    _c(TopwebsuiteTheme.success), '$count',     'Total invoices'),
          _StatSpec(Icons.account_balance_wallet_outlined, 'Value', _c(const Color(0xFF2563EB)), '$curr ${_fmt(total)}', 'Total Invoiced'),
          _StatSpec(Icons.check_circle_outline,   'Paid',    _c(TopwebsuiteTheme.success), '$paid',      'Paid invoices'),
          _StatSpec(Icons.access_time_rounded,    'Pending', _c(TopwebsuiteTheme.warning), '$pend',      'Pending Invoices'),
        ];
      case 'receipts':
        final total  = _sumField(items, 'amount');
        final transf = _countWhere(items, 'payment_method', 'transfer');
        final today  = _countToday(items, 'date');
        final curr   = _firstCurrency(items);
        return [
          _StatSpec(Icons.receipt_outlined,       'Live',      _c(TopwebsuiteTheme.success), '$count',  'Total receipts'),
          _StatSpec(Icons.account_balance_wallet_outlined, 'Collected', _c(TopwebsuiteTheme.warning), '$curr ${_fmt(total)}', 'Total value'),
          _StatSpec(Icons.swap_horiz_rounded,     'Methods',   _c(const Color(0xFF2563EB)), '$transf', 'Transfer receipts'),
          _StatSpec(Icons.today_rounded,          'Today',     _c(TopwebsuiteTheme.success), '$today',  'Issued today'),
        ];
      case 'waybills':
        final weight    = _sumField(items, 'weight');
        final value     = _sumField(items, 'shipment_value');
        final delivered = _countWhere(items, 'status', 'delivered');
        final curr      = _firstCurrency(items);
        return [
          _StatSpec(Icons.local_shipping_outlined,  'Live',      _c(TopwebsuiteTheme.success), '$count',           'Total waybills'),
          _StatSpec(Icons.scale_outlined,           'Weight',    _c(TopwebsuiteTheme.warning), '${_fmt(weight)} kg','Total shipment weight'),
          _StatSpec(Icons.account_balance_wallet_outlined, 'Value', _c(const Color(0xFF2563EB)), '$curr ${_fmt(value)}', 'Total shipment value'),
          _StatSpec(Icons.location_on_outlined,     'Delivered', _c(TopwebsuiteTheme.success), '$delivered',       'Delivered waybills'),
        ];
      case 'quotations':
        final total   = _sumField(items, 'total');
        final open    = _countWhere(items, 'status', 'open');
        final recent  = _countRecent7Days(items);
        final curr    = _firstCurrency(items);
        return [
          _StatSpec(Icons.request_quote_outlined,  'Live',   _c(TopwebsuiteTheme.success), '$count',            'Total quotations'),
          _StatSpec(Icons.account_balance_wallet_outlined, 'Value', _c(TopwebsuiteTheme.warning), '$curr ${_fmt(total)}', 'Total quoted value'),
          _StatSpec(Icons.check_circle_outline,    'Open',   _c(const Color(0xFF2563EB)), '$open',              'Open quotations'),
          _StatSpec(Icons.calendar_today_rounded,  'Recent', _c(TopwebsuiteTheme.success), '$recent',           'Updated in 7 days'),
        ];
      case 'letters':
        final drafts = _countWhere(items, 'status', 'draft');
        final finals = _countWhere(items, 'status', 'final');
        final recent = _countRecent7Days(items);
        return [
          _StatSpec(Icons.layers_outlined,        'Assets', _c(TopwebsuiteTheme.success), '$letterheadCount', 'Letterhead layouts'),
          _StatSpec(Icons.description_outlined,   'Drafts', _c(TopwebsuiteTheme.warning), '$drafts',          'Open letters'),
          _StatSpec(Icons.edit_note_rounded,      'Ready',  _c(TopwebsuiteTheme.success), '$finals',          'Final letters'),
          _StatSpec(Icons.history_rounded,        'Recent', _c(TopwebsuiteTheme.success), '$recent',          'Updated in 7 days'),
        ];
      default:
        return [
          _StatSpec(Icons.description_outlined, 'Live', _c(TopwebsuiteTheme.success), '$count', 'Total records'),
          _StatSpec(Icons.check_circle_outline, 'Active', _c(const Color(0xFF2563EB)), '$count', 'Active'),
          _StatSpec(Icons.pending_outlined, 'Pending', _c(TopwebsuiteTheme.warning), '0', 'Pending'),
          _StatSpec(Icons.calendar_today_rounded, 'Recent', _c(TopwebsuiteTheme.success), '0', 'Recent'),
        ];
    }
  }

  // ── Helpers
  static double _sumField(List<Map<String, dynamic>> items, String key) {
    double sum = 0;
    for (final item in items) {
      final v = double.tryParse(item[key]?.toString() ?? '0') ?? 0;
      sum += v;
    }
    return sum;
  }

  static int _countWhere(List<Map<String, dynamic>> items, String field, String value) =>
      items.where((r) => r[field]?.toString().toLowerCase() == value).length;

  static int _countToday(List<Map<String, dynamic>> items, String field) {
    final today = DateTime.now();
    return items.where((r) {
      final s = r[field]?.toString() ?? '';
      final d = DateTime.tryParse(s);
      return d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
  }

  static int _countRecent7Days(List<Map<String, dynamic>> items) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return items.where((r) {
      for (final key in ['updated_at', 'created_at', 'date']) {
        final s = r[key]?.toString() ?? '';
        final d = DateTime.tryParse(s);
        if (d != null && d.isAfter(cutoff)) return true;
      }
      return false;
    }).length;
  }

  static String _firstCurrency(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return '';
    final curr = items.first['currency']?.toString() ?? '';
    return curr;
  }

  static String _fmt(double v) {
    if (v == 0) return '0.00';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }

  static Color _c(Color c) => c;
}

class _StatSpec {
  const _StatSpec(this.icon, this.badge, this.badgeColor, this.value, this.label);
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final String value;
  final String label;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.spec});
  final _StatSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06024EE0), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(spec.icon, size: 14, color: TopwebsuiteTheme.primary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: spec.badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(spec.badge,
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: spec.badgeColor,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(spec.value,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              letterSpacing: -0.02, color: TopwebsuiteTheme.ink,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(spec.label,
            style: const TextStyle(fontSize: 10, color: TopwebsuiteTheme.muted),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Management card ───────────────────────────────────────────────────────────

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.createLabel,
    required this.showLetterheadBtn,
    required this.onFilter,
    required this.onCreate,
    required this.onCreateLetterhead,
  });

  final String title;
  final String subtitle;
  final String createLabel;
  final bool showLetterheadBtn;
  final VoidCallback onFilter;
  final VoidCallback onCreate;
  final VoidCallback onCreateLetterhead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06024EE0), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: TopwebsuiteTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
            style: const TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Filter button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFilter,
                  icon: const Icon(Icons.filter_list_rounded, size: 16),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TopwebsuiteTheme.ink,
                    side: const BorderSide(color: TopwebsuiteTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Create button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(createLabel, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TopwebsuiteTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showLetterheadBtn) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreateLetterhead,
                icon: const Icon(Icons.layers_outlined, size: 16),
                label: const Text('Create Letterhead'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TopwebsuiteTheme.primary,
                  side: const BorderSide(color: TopwebsuiteTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusOptions,
    required this.selectedStatus,
    required this.sortOrder,
    required this.search,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
    required this.searchPlaceholder,
  });

  final List<String> statusOptions;
  final String selectedStatus;
  final String sortOrder;
  final String search;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;
  final String searchPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status dropdown
          const Text('Status',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: TopwebsuiteTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          _DropdownField(
            value: selectedStatus,
            items: statusOptions,
            labelOf: (s) => s == 'all'
                ? (statusOptions.first.startsWith('All') ? statusOptions.first : 'All Statuses')
                : _capitalize(s),
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),

          // Sort dropdown
          const Text('Sort By',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: TopwebsuiteTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          _DropdownField(
            value: sortOrder,
            items: const ['newest', 'oldest'],
            labelOf: (s) => s == 'newest' ? 'Newest First' : 'Oldest First',
            onChanged: onSortChanged,
          ),
          const SizedBox(height: 12),

          // Quick search
          const Text('Quick Search',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: TopwebsuiteTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
            decoration: InputDecoration(
              hintText: searchPlaceholder,
              hintStyle: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              filled: true,
              fillColor: TopwebsuiteTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TopwebsuiteTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TopwebsuiteTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: TopwebsuiteTheme.primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final String Function(String) labelOf;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: TopwebsuiteTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: DropdownButton<String>(
        value: effectiveValue,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(
          fontSize: 13, color: TopwebsuiteTheme.ink,
          fontWeight: FontWeight.w500,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: TopwebsuiteTheme.muted, size: 18),
        items: items.map((s) => DropdownMenuItem(
          value: s,
          child: Text(labelOf(s)),
        )).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── Doc card ──────────────────────────────────────────────────────────────────

class _DocCard extends ConsumerWidget {
  const _DocCard({
    required this.config,
    required this.row,
    required this.numberKey,
    required this.nameKey,
    required this.onEdit,
    required this.onRefresh,
  });

  final ResourceConfig config;
  final Map<String, dynamic> row;
  final String numberKey;
  final String nameKey;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id     = stringValue(row, config.idKeys);
    final number = row[numberKey]?.toString() ?? id;
    final name   = row[nameKey]?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0F7)),
        boxShadow: const [
          BoxShadow(color: Color(0x06024EE0), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: TopwebsuiteTheme.primarySoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.description_outlined,
                      size: 17, color: TopwebsuiteTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(number,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: TopwebsuiteTheme.ink,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (name.isNotEmpty)
                        Text(name,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: TopwebsuiteTheme.primary,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEAF0F7)),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    _ActionBtn(
                      label: 'Preview',
                      icon: Icons.visibility_outlined,
                      onTap: config.previewPath != null && id.isNotEmpty
                          ? () async {
                              final token = await ref
                                  .read(secureTokenStoreProvider)
                                  .readAccessToken();
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BackendPreviewScreen(
                                    title: number,
                                    path: config.previewPath!(id),
                                    token: token,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      label: 'Download PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      onTap: config.downloadPath != null && id.isNotEmpty
                          ? () => ref
                              .read(fileServiceProvider)
                              .openPdf(config.downloadPath!(id), '$number.pdf')
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionBtn(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      danger: true,
                      onTap: id.isEmpty ? null : () => _confirmDelete(context, ref, id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: TopwebsuiteTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(resourceRepositoryProvider).remove(config, id);
      onRefresh();
    }
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? TopwebsuiteTheme.danger : TopwebsuiteTheme.ink;
    final borderColor = danger
        ? TopwebsuiteTheme.danger.withValues(alpha: 0.4)
        : TopwebsuiteTheme.border;

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.statusOptions,
    required this.selectedStatus,
    required this.sortOrder,
    required this.onApply,
  });

  final List<String> statusOptions;
  final String selectedStatus;
  final String sortOrder;
  final void Function(String status, String sort) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _status;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _sort   = widget.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: TopwebsuiteTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filter & Sort',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Status', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: TopwebsuiteTheme.muted,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.statusOptions.map((s) {
              final sel = s == _status;
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? TopwebsuiteTheme.primary : TopwebsuiteTheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: sel ? TopwebsuiteTheme.primary : TopwebsuiteTheme.border,
                    ),
                  ),
                  child: Text(s == 'all' ? 'All Statuses' : _capitalize(s),
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : TopwebsuiteTheme.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Sort By', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: TopwebsuiteTheme.muted,
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              _SortChip(label: 'Newest First', value: 'newest', selected: _sort, onTap: (v) => setState(() => _sort = v)),
              const SizedBox(width: 8),
              _SortChip(label: 'Oldest First', value: 'oldest', selected: _sort, onTap: (v) => setState(() => _sort = v)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_status, _sort);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TopwebsuiteTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });
  final String label, value, selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? TopwebsuiteTheme.primary : TopwebsuiteTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: sel ? TopwebsuiteTheme.primary : TopwebsuiteTheme.border,
          ),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : TopwebsuiteTheme.ink,
          ),
        ),
      ),
    );
  }
}

// ── Tips card ─────────────────────────────────────────────────────────────────

class _TipData {
  const _TipData(this.title, this.body, this.icon);
  final String title;
  final String body;
  final IconData icon;
}

const _kTips = <String, (String, List<_TipData>)>{
  'invoices': ('Quick Insights', [
    _TipData('Best Month', 'Check your dashboard to find the month with the highest invoice volume.', Icons.trending_up_rounded),
    _TipData('Top Client', 'Your most invoiced client leads by total value — tap View all → to see details.', Icons.person_outlined),
    _TipData('Action Needed', 'Follow up on pending invoices to ensure timely payment from clients.', Icons.bolt_rounded),
  ]),
  'receipts': ('Receipt Notes', [
    _TipData('Best use', 'Capture completed payments and give clients a clean proof of payment.', Icons.check_circle_outline),
    _TipData('Branding', 'Use your logo, brand color and signature to keep receipts consistent.', Icons.palette_outlined),
    _TipData('Delivery', 'After saving, open preview and download PDF to share with the payer.', Icons.send_outlined),
  ]),
  'waybills': ('Waybill Tips', [
    _TipData('Accurate contacts', 'Add sender and recipient contact details so dispatch teams can follow up quickly.', Icons.contacts_outlined),
    _TipData('Weight matters', 'Use a realistic shipment weight to keep delivery records clear and auditable.', Icons.scale_outlined),
    _TipData('Status updates', 'Update the waybill status (Shipped → Delivered) to track your shipments.', Icons.local_shipping_outlined),
  ]),
  'quotations': ('Quotation Note', [
    _TipData('Backend synced', 'Quotations use the live API endpoints and backend numbering automatically.', Icons.cloud_done_outlined),
    _TipData('Preview flow', 'Save a quotation, open preview, continue editing, and download the generated PDF.', Icons.visibility_outlined),
    _TipData('Invoice-style builder', 'The layout, live preview, item totals and document flow follow the invoice experience.', Icons.receipt_long_outlined),
  ]),
  'letters': ('Letter Tips', [
    _TipData('Letterhead first', 'Upload a letterhead layout before writing a letter to get a branded output.', Icons.layers_outlined),
    _TipData('Status control', 'Keep letters as Draft while editing; mark Final only when ready to send.', Icons.edit_note_rounded),
    _TipData('PDF export', 'After writing a letter, use Download PDF to get a print-ready version.', Icons.picture_as_pdf_outlined),
  ]),
};

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.docKey});
  final String docKey;

  @override
  Widget build(BuildContext context) {
    final entry = _kTips[docKey];
    if (entry == null) return const SizedBox.shrink();
    final (sectionTitle, tips) = entry;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06024EE0), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sectionTitle,
            style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: TopwebsuiteTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text('Helpful reminders for this workspace.',
            style: const TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted),
          ),
          const SizedBox(height: 14),
          for (final tip in tips) ...[
            _TipItem(tip: tip),
            if (tip != tips.last)
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.tip});
  final _TipData tip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: TopwebsuiteTheme.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(tip.icon, size: 16, color: TopwebsuiteTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.title,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(tip.body,
                style: const TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _WorkspaceTopBar extends ConsumerWidget {
  const _WorkspaceTopBar({
    required this.placeholder,
    required this.onSearch,
  });

  final String placeholder;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Container(
      color: TopwebsuiteTheme.primary,
      padding: EdgeInsets.fromLTRB(
          10, MediaQuery.of(context).padding.top + 8, 10, 8),
      child: Row(
        children: [
          // Hamburger
          _TBIconBtn(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),

          // Search
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: TextField(
                onChanged: onSearch,
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.95)),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: Colors.white.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Create quick (+)
          _TBIconBtn(
            icon: Icons.add_rounded,
            onTap: () {
              final state = context.findAncestorStateOfType<_DocWorkspaceScreenState>();
              state?._openForm(context, null);
            },
          ),
          const SizedBox(width: 8),

          // Avatar — tappable: shows profile/logout sheet
          if (user != null)
            GestureDetector(
              onTap: () => _showUserMenu(context, ref, user),
              child: _UserAvatarBtn(name: user.displayName),
            ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocUserMenuSheet(user: user, ref: ref),
    );
  }
}

class _TBIconBtn extends StatelessWidget {
  const _TBIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _UserAvatarBtn extends StatelessWidget {
  const _UserAvatarBtn({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? 'U'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [TopwebsuiteTheme.primary, Color(0xFF5B9FE8)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(initials,
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
        ),
      ),
    );
  }
}

// ── User menu sheet ───────────────────────────────────────────────────────────

class _DocUserMenuSheet extends StatelessWidget {
  const _DocUserMenuSheet({required this.user, required this.ref});
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: TopwebsuiteTheme.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        // User header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: TopwebsuiteTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TopwebsuiteTheme.border)),
          child: Row(children: [
            _UserAvatarBtn(name: user?.displayName ?? ''),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? '',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: TopwebsuiteTheme.ink)),
                  Text(user?.email ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: TopwebsuiteTheme.muted)),
                ])),
          ]),
        ),
        const SizedBox(height: 12),
        _MenuItem(
          icon: Icons.person_outline_rounded,
          label: 'User Profile',
          subtitle: 'Update your business details',
          onTap: () { Navigator.pop(context); context.push('/account'); },
        ),
        _MenuItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          subtitle: 'Account and preferences',
          onTap: () { Navigator.pop(context); context.push('/account'); },
        ),
        _MenuItem(
          icon: Icons.workspace_premium_outlined,
          label: 'Billing',
          subtitle: 'Manage your subscription plan',
          onTap: () { Navigator.pop(context); context.push('/billing'); },
        ),
        _MenuItem(
          icon: Icons.logout_rounded,
          label: 'Logout',
          subtitle: 'End this session',
          destructive: true,
          onTap: () {
            Navigator.pop(context);
            ref.read(authControllerProvider.notifier).logout();
          },
        ),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon, required this.label,
    required this.subtitle, required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? TopwebsuiteTheme.danger : TopwebsuiteTheme.ink;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: destructive
                ? const Color(0xFFFEF2F2) : TopwebsuiteTheme.primarySoft,
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18,
            color: destructive ? TopwebsuiteTheme.danger : TopwebsuiteTheme.primary)),
      title: Text(label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted)),
      onTap: onTap,
    );
  }
}

// ── Sidebar drawer ────────────────────────────────────────────────────────────

class _WorkspaceDrawer extends ConsumerWidget {
  const _WorkspaceDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const items = [
      _DItem('Dashboard',        Icons.speed_rounded,             '/'),
      _DItem('Invoices',         Icons.receipt_long_outlined,     '/invoices'),
      _DItem('Receipts',         Icons.receipt_outlined,          '/receipts'),
      _DItem('Waybills',         Icons.local_shipping_outlined,   '/waybills'),
      _DItem('Quotations',       Icons.request_quote_outlined,    '/quotations'),
      _DItem('Letterheads',      Icons.mail_outline_rounded,      '/letterheads'),
      _DItem('Business Profile', Icons.storefront_outlined,       '/business-profile'),
      _DItem('CRM',              Icons.groups_2_outlined,         '/crm'),
      _DItem('ERP',              Icons.inventory_2_outlined,      '/erp'),
      _DItem('Billing',          Icons.workspace_premium_outlined,'/billing'),
    ];

    final loc = GoRouterState.of(context).matchedLocation;

    return Drawer(
      width: 285,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  const AppLogo(compact: true),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Topwebsuite',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: TopwebsuiteTheme.ink,
                          ),
                        ),
                        Text('Workspace',
                          style: TextStyle(
                            fontSize: 12, color: TopwebsuiteTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: TopwebsuiteTheme.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: TopwebsuiteTheme.border),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('MAIN MENU',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 0.12, color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: items.map((item) {
                  final isActive = loc == item.route ||
                      (item.route != '/' && loc.startsWith(item.route));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      tileColor: isActive ? TopwebsuiteTheme.primarySoft : null,
                      leading: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isActive
                              ? TopwebsuiteTheme.primary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, size: 17,
                          color: isActive ? Colors.white : TopwebsuiteTheme.primary),
                      ),
                      title: Text(item.label,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: isActive
                              ? TopwebsuiteTheme.primary : TopwebsuiteTheme.ink,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(item.route);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1, color: TopwebsuiteTheme.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      size: 17, color: TopwebsuiteTheme.danger),
                ),
                title: const Text('Logout',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: TopwebsuiteTheme.danger,
                  ),
                ),
                subtitle: const Text('End this session',
                  style: TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted)),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DItem {
  const _DItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

// ── Bottom create bar ─────────────────────────────────────────────────────────

class _ExtraCreateBtn {
  const _ExtraCreateBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

class _CreateBar extends StatelessWidget {
  const _CreateBar({
    required this.label,
    required this.onTap,
    this.extra,
  });

  final String label;
  final VoidCallback onTap;
  final _ExtraCreateBtn? extra;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: TopwebsuiteTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resource form (bottom sheet) ──────────────────────────────────────────────

class _DocForm extends ConsumerStatefulWidget {
  const _DocForm({required this.config, this.row});
  final ResourceConfig config;
  final Map<String, dynamic>? row;

  @override
  ConsumerState<_DocForm> createState() => _DocFormState();
}

class _DocFormState extends ConsumerState<_DocForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final List<_LIC> _lineItems;
  bool _saving = false;
  String get _draftKey => 'draft_${widget.config.key}';

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.config.fields)
        f.key: TextEditingController(text: widget.row?[f.key]?.toString() ?? ''),
    };
    for (final c in _controllers.values) { c.addListener(_saveDraft); }
    _lineItems = [];
    if (widget.config.hasLineItems) {
      final existing = widget.row?['items'];
      if (existing is List && existing.isNotEmpty) {
        for (final item in existing.whereType<Map>()) {
          _lineItems.add(_LIC.fromMap(item));
        }
      } else {
        _lineItems.add(_LIC.empty());
      }
    }
    if (widget.row == null) Future.microtask(_loadDraft);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    for (final li in _lineItems) { li.dispose(); }
    super.dispose();
  }

  // ── Computed totals ──────────────────────────────────────────────────────────

  double get _subtotal {
    double sum = 0;
    for (final li in _lineItems) {
      final q = double.tryParse(li.qty.text) ?? 0;
      final r = double.tryParse(li.rate.text) ?? 0;
      sum += q * r;
    }
    return sum;
  }

  double get _total {
    final sub  = _subtotal;
    final disc = double.tryParse(
      _controllers['discount_percent']?.text ?? _controllers['discount']?.text ?? '0') ?? 0;
    final tax  = double.tryParse(
      _controllers['vat_percent']?.text ?? _controllers['tax_percent']?.text ?? '0') ?? 0;
    return sub * (1 - disc / 100) * (1 + tax / 100);
  }

  String _fmtAmt(double v) =>
      v == 0 ? '0.00' : v.toStringAsFixed(2);

  // ── Date picker helper ────────────────────────────────────────────────────

  Future<void> _pickDate(String fieldKey) async {
    final c = _controllers[fieldKey];
    if (c == null) return;
    final initial = DateTime.tryParse(c.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      c.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _saveDraft();
    }
  }

  // ── Section layout helpers ────────────────────────────────────────────────

  static const _sectionHeaderStyle = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w800,
    letterSpacing: 0.08, color: Color(0xFF334155),
  );
  static const _badgeStyle = TextStyle(
    fontSize: 11, color: TopwebsuiteTheme.muted,
  );

  Widget _section(String title, String badge, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: _sectionHeaderStyle),
              Text(badge, style: _badgeStyle),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TopwebsuiteTheme.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String key, {String? labelOverride, bool multiline = false,
      TextInputType? keyboard, bool required = false}) {
    final c = _controllers[key];
    if (c == null) return const SizedBox.shrink();
    final label = labelOverride ??
        widget.config.fields.where((f) => f.key == key).firstOrNull?.label ?? key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        maxLines: multiline ? 4 : 1,
        style: const TextStyle(color: TopwebsuiteTheme.ink, fontSize: 14),
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: TopwebsuiteTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: TopwebsuiteTheme.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: TopwebsuiteTheme.primary, width: 1.4)),
          filled: true, fillColor: Colors.white,
        ),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _dateField(String key, {String? label}) {
    final c = _controllers[key];
    if (c == null) return const SizedBox.shrink();
    final lbl = label ??
        widget.config.fields.where((f) => f.key == key).firstOrNull?.label ?? key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _pickDate(key),
        child: AbsorbPointer(
          child: TextFormField(
            controller: c,
            style: const TextStyle(color: TopwebsuiteTheme.ink, fontSize: 14),
            decoration: InputDecoration(
              labelText: lbl,
              labelStyle: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.muted),
              suffixIcon: const Icon(Icons.calendar_today_rounded,
                  size: 16, color: TopwebsuiteTheme.muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: TopwebsuiteTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: TopwebsuiteTheme.border)),
              filled: true, fillColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _totalsDisplay(String currencyKey) {
    final curr = _controllers[currencyKey]?.text ?? '';
    final label = curr.isEmpty ? '' : '$curr ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TopwebsuiteTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', '$label${_fmtAmt(_subtotal)}', muted: true),
          const SizedBox(height: 4),
          _totalRow('Total', '$label${_fmtAmt(_total)}', bold: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool muted = false, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          color: muted ? TopwebsuiteTheme.muted : TopwebsuiteTheme.ink,
        )),
        Text(value, style: TextStyle(
          fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          color: bold ? TopwebsuiteTheme.ink : TopwebsuiteTheme.muted,
        )),
      ],
    );
  }

  // ── Section groups by document type ──────────────────────────────────────

  List<Widget> _buildSections() {
    final k = widget.config.key;
    switch (k) {
      case 'invoices':    return _invoiceSections();
      case 'receipts':    return _receiptSections();
      case 'waybills':    return _waybillSections();
      case 'quotations':  return _quotationSections();
      case 'letters':     return _letterSections();
      case 'letterhead':  return _letterheadSections();
      default:            return _genericSections();
    }
  }

  List<Widget> _invoiceSections() => [
    _section('INVOICE DETAILS', 'Basic info', [
      _field('invoice_number', labelOverride: 'Invoice # (auto if blank)'),
      _dateField('issued_date', label: 'Date'),
      _dateField('due_date', label: 'Due Date'),
      _field('currency', labelOverride: 'Currency (e.g. NGN, USD)'),
    ]),
    _section('BILL FROM', 'Your company', [
      _field('company_name', required: true),
      _field('company_address', multiline: true),
      _field('company_phone', keyboard: TextInputType.phone),
      _field('company_email', keyboard: TextInputType.emailAddress),
      _field('company_website', keyboard: TextInputType.url),
    ]),
    _section('BILL TO', 'Client info', [
      _field('client_name', required: true),
      _field('client_address', multiline: true),
      _field('client_phone', keyboard: TextInputType.phone),
      _field('client_email', keyboard: TextInputType.emailAddress),
    ]),
    Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ITEMS', style: _sectionHeaderStyle),
              Text('Services / products', style: _badgeStyle),
            ],
          ),
          const SizedBox(height: 10),
          _LineItemsEditor(
            items: _lineItems,
            onChanged: () { setState(() {}); _saveDraft(); },
          ),
          const SizedBox(height: 10),
          _totalsDisplay('currency'),
        ],
      ),
    ),
    _section('TOTAL SETTINGS', 'Optional values', [
      _field('discount_percent', labelOverride: 'Discount (%)', keyboard: TextInputType.number),
      _field('vat_percent', labelOverride: 'Tax / VAT (%)', keyboard: TextInputType.number),
    ]),
    _section('PAYMENT', 'Instructions', [
      _field('payment_details', multiline: true,
          labelOverride: 'Bank name, account number, payment instructions'),
      _field('authorized_name', labelOverride: 'Authorised name'),
    ]),
    _section('TERMS', 'Notes', [
      _field('notes', multiline: true,
          labelOverride: 'Thank you for your business! Payment due within 30 days.'),
    ]),
  ];

  List<Widget> _receiptSections() => [
    _section('RECEIPT DETAILS', 'Basic info', [
      _field('receipt_number', labelOverride: 'Receipt # (auto if blank)'),
      _dateField('date', label: 'Date'),
      _field('currency', labelOverride: 'Currency (e.g. NGN, USD)'),
    ]),
    _section('COMPANY', 'Your info', [
      _field('company_name', required: true),
      _field('company_address', multiline: true),
      _field('company_phone', keyboard: TextInputType.phone),
      _field('company_email', keyboard: TextInputType.emailAddress),
    ]),
    _section('PAYMENT', 'From payer', [
      _field('received_from', required: true, labelOverride: 'Received from (payer name)'),
      _field('amount', required: true, keyboard: TextInputType.number),
      _field('balance', keyboard: TextInputType.number),
      _field('payment_method', labelOverride: 'Payment method (cash/transfer/card)'),
      _field('being_payment_for', multiline: true, labelOverride: 'Being payment for'),
    ]),
    _section('NOTES', 'Optional', [
      _field('notes', multiline: true),
      _field('authorized_name', labelOverride: 'Authorised name'),
    ]),
  ];

  List<Widget> _waybillSections() => [
    _section('COMPANY', 'Your info', [
      _field('company_name', required: true),
      _field('company_address', multiline: true),
      _field('company_phone', keyboard: TextInputType.phone),
      _field('company_email', keyboard: TextInputType.emailAddress),
    ]),
    _section('WAYBILL DETAILS', 'Basic info', [
      _field('waybill_number', labelOverride: 'Waybill # (auto if blank)'),
      _dateField('date', label: 'Date'),
      _field('currency', labelOverride: 'Currency'),
    ]),
    _section('SENDER', 'From', [
      _field('sender_name', labelOverride: 'Sender name'),
      _field('sender_address', multiline: true, labelOverride: 'Sender address'),
      _field('sender_contact', keyboard: TextInputType.phone,
          labelOverride: 'Sender phone'),
    ]),
    _section('RECIPIENT', 'To', [
      _field('recipient_name', required: true, labelOverride: 'Recipient name'),
      _field('recipient_address', multiline: true, required: true,
          labelOverride: 'Recipient address'),
      _field('recipient_contact', keyboard: TextInputType.phone, required: true,
          labelOverride: 'Recipient phone'),
    ]),
    _section('SHIPMENT', 'Goods info', [
      _field('shipment_description', multiline: true, required: true,
          labelOverride: 'Description of goods'),
      _field('shipment_value', keyboard: TextInputType.number, required: true,
          labelOverride: 'Declared value'),
      _field('weight', keyboard: TextInputType.number, required: true,
          labelOverride: 'Weight (kg)'),
      _field('status', labelOverride: 'Status (pending/shipped/delivered)'),
    ]),
  ];

  List<Widget> _quotationSections() => [
    _section('QUOTATION DETAILS', 'Basic info', [
      _field('quotation_number', labelOverride: 'Quotation # (auto if blank)'),
      _dateField('date', label: 'Issue Date'),
      _dateField('valid_until', label: 'Valid Until'),
      _field('reference', labelOverride: 'Reference'),
      _field('currency', labelOverride: 'Currency (e.g. NGN, USD)'),
    ]),
    _section('BILL FROM', 'Your company', [
      _field('company_name', required: true),
      _field('company_address', multiline: true),
      _field('company_phone', keyboard: TextInputType.phone),
      _field('company_email', keyboard: TextInputType.emailAddress),
    ]),
    _section('BILL TO', 'Client info', [
      _field('client_name', required: true),
      _field('client_address', multiline: true),
      _field('client_phone', keyboard: TextInputType.phone),
      _field('client_email', keyboard: TextInputType.emailAddress),
    ]),
    Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ITEMS', style: _sectionHeaderStyle),
              Text('Services / products', style: _badgeStyle),
            ],
          ),
          const SizedBox(height: 10),
          _LineItemsEditor(
            items: _lineItems,
            onChanged: () { setState(() {}); _saveDraft(); },
          ),
          const SizedBox(height: 10),
          _totalsDisplay('currency'),
        ],
      ),
    ),
    _section('TOTAL SETTINGS', 'Optional values', [
      _field('discount_percent', labelOverride: 'Discount (%)', keyboard: TextInputType.number),
      _field('tax_percent', labelOverride: 'Tax / VAT (%)', keyboard: TextInputType.number),
    ]),
    _section('NOTES', 'Optional', [
      _field('notes', multiline: true),
    ]),
  ];

  List<Widget> _letterSections() => [
    _section('LETTER DETAILS', 'Metadata', [
      _field('title', required: true),
      _field('page_size', labelOverride: 'Page size (A4/Letter)'),
      _field('orientation', labelOverride: 'Orientation (portrait/landscape)'),
      _field('status', labelOverride: 'Status (draft/final)'),
    ]),
    _section('CONTENT', 'Letter body', [
      _field('plain_text', multiline: true, required: true,
          labelOverride: 'Write your letter here...'),
    ]),
  ];

  List<Widget> _letterheadSections() => [
    _section('LETTERHEAD', 'Details', [
      _field('title', required: true),
      _field('page_size', labelOverride: 'Page size (A4/Letter)'),
      _field('margin_top', keyboard: TextInputType.number, labelOverride: 'Top margin'),
      _field('margin_right', keyboard: TextInputType.number, labelOverride: 'Right margin'),
      _field('margin_bottom', keyboard: TextInputType.number, labelOverride: 'Bottom margin'),
      _field('margin_left', keyboard: TextInputType.number, labelOverride: 'Left margin'),
    ]),
  ];

  List<Widget> _genericSections() {
    return widget.config.fields.map((f) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: f.keyboard == FieldKeyboard.date
          ? _dateField(f.key)
          : _field(f.key,
              multiline: f.multiline,
              required: f.required,
              keyboard: switch (f.keyboard) {
                FieldKeyboard.email  => TextInputType.emailAddress,
                FieldKeyboard.phone  => TextInputType.phone,
                FieldKeyboard.number => TextInputType.number,
                FieldKeyboard.url    => TextInputType.url,
                _                    => TextInputType.text,
              }),
    )).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.row == null;
    final title = isCreate
        ? 'Create ${widget.config.title}'
        : 'Edit ${widget.config.title}';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      builder: (ctx, ctrl) => Material(
        color: TopwebsuiteTheme.surface,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  // Drag handle centred
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36, height: 4,
                            decoration: BoxDecoration(
                              color: TopwebsuiteTheme.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(title,
                          style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: TopwebsuiteTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: TopwebsuiteTheme.muted),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: TopwebsuiteTheme.border),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: _buildSections(),
                ),
              ),
            ),

            // ── Sticky footer buttons ────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, MediaQuery.of(ctx).padding.bottom + 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TopwebsuiteTheme.ink,
                        side: const BorderSide(color: TopwebsuiteTheme.border),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(_saving ? 'Saving...' : 'Save ${ widget.config.title.split(' ').first}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TopwebsuiteTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      for (final e in _controllers.entries) e.key: e.value.text.trim(),
    };
    if (widget.config.hasLineItems) {
      final items = _lineItems
          .map((li) => li.toPayload())
          .where((li) => li['description'].toString().isNotEmpty)
          .toList();
      if (items.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one line item.')));
        return;
      }
      payload['items'] = items;
    }
    try {
      final id = stringValue(widget.row ?? {}, widget.config.idKeys);
      if (widget.row == null || id.isEmpty) {
        await ref.read(resourceRepositoryProvider).create(widget.config, payload);
      } else {
        await ref.read(resourceRepositoryProvider).update(widget.config, id, payload);
      }
      await ref.read(localStoreProvider).remove(_draftKey);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(localStoreProvider).readJson(_draftKey);
    if (draft == null || !mounted) return;
    for (final e in _controllers.entries) {
      final v = draft[e.key];
      if (v != null && e.value.text.isEmpty) e.value.text = v.toString();
    }
  }

  Future<void> _saveDraft() async {
    if (widget.row != null) return;
    final draft = <String, dynamic>{
      for (final e in _controllers.entries) e.key: e.value.text,
    };
    await ref.read(localStoreProvider).writeJson(_draftKey, draft);
  }
}

// ── Line item controllers (shared) ────────────────────────────────────────────

class _LIC {
  _LIC({required this.desc, required this.qty, required this.rate});

  factory _LIC.empty() => _LIC(
    desc: TextEditingController(),
    qty:  TextEditingController(text: '1'),
    rate: TextEditingController(),
  );

  factory _LIC.fromMap(Map<dynamic, dynamic> m) => _LIC(
    desc: TextEditingController(text: m['description']?.toString() ?? ''),
    qty:  TextEditingController(text: m['quantity']?.toString() ?? '1'),
    rate: TextEditingController(
        text: (m['rate'] ?? m['unit_price'] ?? m['price'])?.toString() ?? ''),
  );

  final TextEditingController desc;
  final TextEditingController qty;
  final TextEditingController rate;

  Map<String, dynamic> toPayload() => {
    'description': desc.text.trim(),
    'quantity':    qty.text.trim().isEmpty ? '1' : qty.text.trim(),
    'rate':        rate.text.trim().isEmpty ? '0' : rate.text.trim(),
  };

  void dispose() { desc.dispose(); qty.dispose(); rate.dispose(); }
}

class _LineItemsEditor extends StatefulWidget {
  const _LineItemsEditor({required this.items, required this.onChanged});
  final List<_LIC> items;
  final VoidCallback onChanged;

  @override
  State<_LineItemsEditor> createState() => _LineItemsEditorState();
}

class _LineItemsEditorState extends State<_LineItemsEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Line Items',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: TopwebsuiteTheme.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add item',
                onPressed: () {
                  setState(() => widget.items.add(_LIC.empty()));
                  widget.onChanged();
                },
                icon: const Icon(Icons.add_circle_outline,
                    color: TopwebsuiteTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < widget.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  TextFormField(
                    controller: widget.items[i].desc,
                    onChanged: (_) => widget.onChanged(),
                    style: const TextStyle(
                        color: TopwebsuiteTheme.ink, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Item ${i + 1} description',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.items[i].qty,
                          onChanged: (_) => widget.onChanged(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: TopwebsuiteTheme.ink, fontSize: 14),
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: widget.items[i].rate,
                          onChanged: (_) => widget.onChanged(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: TopwebsuiteTheme.ink, fontSize: 14),
                          decoration: const InputDecoration(labelText: 'Rate'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: widget.items.length == 1 ? null : () {
                          final removed = widget.items.removeAt(i);
                          removed.dispose();
                          setState(() {});
                          widget.onChanged();
                        },
                        icon: const Icon(Icons.remove_circle_outline,
                            color: TopwebsuiteTheme.danger),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
