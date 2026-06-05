import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/data/resource_repository.dart';
import '../../shared/domain/field_config.dart';
import '../../shared/domain/resource_config.dart';
import '../../shared/presentation/resource_workspace_screen.dart';
import '../module_configs.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _erpSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final results = await Future.wait([
      api.getList('/api/v1/erp/products/'),
      api.getList('/api/v1/erp/services/'),
      api.getList('/api/v1/erp/customers/'),
      api.getList('/api/v1/erp/orders/'),
    ]);
    return {
      'products':  results[0].length,
      'services':  results[1].length,
      'customers': results[2].length,
      'orders':    results[3].length,
    };
  } catch (_) {
    return {'products': 0, 'services': 0, 'customers': 0, 'orders': 0};
  }
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class ErpWorkspaceScreen extends ConsumerStatefulWidget {
  const ErpWorkspaceScreen({super.key});

  @override
  ConsumerState<ErpWorkspaceScreen> createState() => _ErpWorkspaceScreenState();
}

class _ErpWorkspaceScreenState extends ConsumerState<ErpWorkspaceScreen> {
  String _selectedCategory = 'products';
  String _search = '';
  final _searchCtrl = TextEditingController();

  static const _categories = [
    ('products',     'Products',     Icons.inventory_2_outlined),
    ('services',     'Services',     Icons.design_services_outlined),
    ('customers',    'Customers',    Icons.group_outlined),
    ('orders',       'Orders',       Icons.shopping_bag_outlined),
    ('procurements', 'Procurements', Icons.local_mall_outlined),
    ('deliveries',   'Deliveries',   Icons.local_shipping_outlined),
  ];

  ResourceConfig get _currentConfig =>
      erpConfigs.firstWhere((c) => c.key == _selectedCategory,
          orElse: () => erpConfigs.first);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        drawer: _ErpDrawer(),
        body: _buildBody(),
        bottomNavigationBar: _CreateBar(
          label: 'Create ${_currentLabel()}',
          onTap: () => _openForm(context, null),
        ),
      ),
    );
  }

  String _currentLabel() =>
      _categories.firstWhere((c) => c.$1 == _selectedCategory).$2;

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Builder(builder: (ctx) => _TopBar(
            category: 'ERP',
            searchCtrl: _searchCtrl,
            onSearch: (v) => setState(() => _search = v),
            onCreateTap: () => _openForm(ctx, null),
          )),
        ),
        const SliverToBoxAdapter(
            child: Divider(height: 1, color: TopwebsuiteTheme.border)),

        // Stats 2x2
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Consumer(
              builder: (_, ref, __) => ref.watch(_erpSummaryProvider).when(
                data: (counts) => _ErpStatsGrid(counts: counts),
                loading: () => _shimmer(130),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Management card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _ManagementCard(
              title: 'ERP Workspace',
              subtitle:
                  'Manage stock, services, customers, orders, procurements, and deliveries with optional document generation helpers.',
              onRefresh: () {
                ref.invalidate(_erpSummaryProvider);
                ref.invalidate(resourceListProvider(_currentConfig));
              },
              onCreateTap: () => _openForm(context, null),
              createLabel: 'Create Record',
            ),
          ),
        ),

        // Category chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: cat.$2,
                        selected: _selectedCategory == cat.$1,
                        onTap: () => setState(() {
                          _selectedCategory = cat.$1;
                          _search = '';
                          _searchCtrl.clear();
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Quick search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _QuickSearchField(
              controller: _searchCtrl,
              placeholder: 'Search name, SKU, status...',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),

        // Records list
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Consumer(
              builder: (ctx, ref, __) {
                final rows = ref.watch(resourceListProvider(_currentConfig));
                return rows.when(
                  data: (items) {
                    final filtered = _applySearch(items);
                    if (filtered.isEmpty) return _emptyState(_currentLabel());
                    return Column(
                      children: filtered.map((row) =>
                          _ErpRecordCard(
                            config: _currentConfig,
                            row: row,
                            onEdit: () => _openForm(ctx, row),
                            onDeleted: () =>
                                ref.invalidate(resourceListProvider(_currentConfig)),
                          )).toList(),
                    );
                  },
                  loading: () => _shimmer(200),
                  error: (e, _) => _errorState(e.toString()),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  List<Map<String, dynamic>> _applySearch(List<dynamic> items) {
    final typed = items.whereType<Map<String, dynamic>>().toList();
    if (_search.isEmpty) return typed;
    final q = _search.toLowerCase();
    return typed.where((r) {
      for (final key in ['name', 'full_name', 'sku', 'order_number',
            'tracking_number', 'status', 'title']) {
        if (r[key]?.toString().toLowerCase().contains(q) == true) return true;
      }
      return false;
    }).toList();
  }

  Future<void> _openForm(BuildContext context, Map<String, dynamic>? row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ErpForm(config: _currentConfig, row: row),
    );
    if (saved == true) {
      ref.invalidate(resourceListProvider(_currentConfig));
      ref.invalidate(_erpSummaryProvider);
    }
  }

  Widget _shimmer(double h) => Container(
      height: h,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16)));

  Widget _emptyState(String label) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TopwebsuiteTheme.border)),
      child: Column(children: [
        const Icon(Icons.inbox_outlined, size: 36, color: TopwebsuiteTheme.muted),
        const SizedBox(height: 10),
        Text('No $label yet',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Create your first $label record',
            style: const TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted)),
      ]));

  Widget _errorState(String msg) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12)),
      child: Text(msg,
          style: const TextStyle(color: TopwebsuiteTheme.danger, fontSize: 13)));
}

// ── Stats grid ─────────────────────────────────────────────────────────────────

class _ErpStatsGrid extends StatelessWidget {
  const _ErpStatsGrid({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final specs = [
      _S(Icons.inventory_2_outlined,      'Products',  TopwebsuiteTheme.success,       '${counts['products'] ?? 0}',  'Tracked products'),
      _S(Icons.design_services_outlined,  'Services',  const Color(0xFF2563EB),        '${counts['services'] ?? 0}',  'Service catalogue'),
      _S(Icons.group_outlined,            'Customers', TopwebsuiteTheme.warning,       '${counts['customers'] ?? 0}', 'ERP customers'),
      _S(Icons.shopping_bag_outlined,     'Orders',    TopwebsuiteTheme.success,       '${counts['orders'] ?? 0}',    'Orders and deliveries'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.42,
      ),
      itemCount: specs.length,
      itemBuilder: (_, i) => _StatCard(spec: specs[i]),
    );
  }
}

class _S {
  const _S(this.icon, this.badge, this.color, this.value, this.label);
  final IconData icon;
  final String badge;
  final Color color;
  final String value;
  final String label;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.spec});
  final _S spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06024EE0), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: TopwebsuiteTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(spec.icon, size: 14, color: TopwebsuiteTheme.primary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999)),
              child: Text(spec.badge,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: spec.color)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(spec.value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  letterSpacing: -0.02, color: TopwebsuiteTheme.ink),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(spec.label,
              style: const TextStyle(fontSize: 10, color: TopwebsuiteTheme.muted),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── ERP Record card ────────────────────────────────────────────────────────────

class _ErpRecordCard extends ConsumerWidget {
  const _ErpRecordCard({
    required this.config,
    required this.row,
    required this.onEdit,
    required this.onDeleted,
  });
  final ResourceConfig config;
  final Map<String, dynamic> row;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id   = stringValue(row, config.idKeys);
    final name = stringValue(row, ['name', 'full_name', 'order_number',
        'tracking_number', 'title'], fallback: id);
    final sub  = stringValue(row, ['sku', 'company_name', 'status',
        'delivery_status', 'description'], fallback: '');
    final price = row['unit_price']?.toString() ?? row['total']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TopwebsuiteTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x04024EE0), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: TopwebsuiteTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 18, color: TopwebsuiteTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: TopwebsuiteTheme.ink)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 12, color: TopwebsuiteTheme.primary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              if (price.isNotEmpty)
                Text(price,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: TopwebsuiteTheme.ink)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _btn('Edit', Icons.edit_outlined, false, onEdit)),
              const SizedBox(width: 8),
              Expanded(child: _btn('Delete', Icons.delete_outline, true, () async {
                await ref.read(resourceRepositoryProvider).remove(config, id);
                onDeleted();
              })),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, bool danger, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? TopwebsuiteTheme.danger : TopwebsuiteTheme.ink,
          side: BorderSide(
              color: danger
                  ? TopwebsuiteTheme.danger.withValues(alpha: 0.4)
                  : TopwebsuiteTheme.border),
          minimumSize: const Size.fromHeight(38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.category,
    required this.searchCtrl,
    required this.onSearch,
    required this.onCreateTap,
  });
  final String category;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return Container(
      color: TopwebsuiteTheme.primary,
      padding: EdgeInsets.fromLTRB(
          10, MediaQuery.of(context).padding.top + 8, 10, 8),
      child: Row(children: [
        _IconBtn(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(context).openDrawer()),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search $category...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 17, color: Colors.white.withValues(alpha: 0.7)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6))),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.add_rounded, onTap: onCreateTap),
        const SizedBox(width: 8),
        if (user != null)
          GestureDetector(
            onTap: () => _showMenu(context, ref, user),
            child: _Avatar(name: user.displayName),
          ),
      ]),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserMenuSheet(user: user, ref: ref),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
          child: Icon(icon, size: 18, color: Colors.white)));
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'U'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TopwebsuiteTheme.primary, Color(0xFF5B9FE8)]),
            borderRadius: BorderRadius.circular(13)),
        alignment: Alignment.center,
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)));
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    required this.onCreateTap,
    required this.createLabel,
  });
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onCreateTap;
  final String createLabel;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TopwebsuiteTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.ink)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: TopwebsuiteTheme.muted, height: 1.4)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: TopwebsuiteTheme.ink,
                  side: const BorderSide(color: TopwebsuiteTheme.border),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(createLabel, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                  backgroundColor: TopwebsuiteTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]));
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: selected ? TopwebsuiteTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: selected
                      ? TopwebsuiteTheme.primary
                      : TopwebsuiteTheme.border)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : TopwebsuiteTheme.ink))));
}

class _QuickSearchField extends StatelessWidget {
  const _QuickSearchField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: TopwebsuiteTheme.ink, fontSize: 13),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
              color: Color(0xFF94A3B8), fontSize: 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: TopwebsuiteTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: TopwebsuiteTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: TopwebsuiteTheme.primary, width: 1.4)),
        ),
      );
}

class _CreateBar extends StatelessWidget {
  const _CreateBar({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: TopwebsuiteTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))))));
}

// ── Drawer ─────────────────────────────────────────────────────────────────────

// ── User menu sheet ───────────────────────────────────────────────────────────

class _UserMenuSheet extends StatelessWidget {
  const _UserMenuSheet({required this.user, required this.ref});
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: TopwebsuiteTheme.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: TopwebsuiteTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TopwebsuiteTheme.border)),
          child: Row(children: [
            _Avatar(name: user?.displayName ?? ''),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.displayName ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: TopwebsuiteTheme.ink)),
              Text(user?.email ?? '',
                  style: const TextStyle(fontSize: 12, color: TopwebsuiteTheme.muted)),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
        _menuItem(context, Icons.person_outline_rounded, 'User Profile',
            'Update your business details', false,
            () { Navigator.pop(context); context.go('/account'); }),
        _menuItem(context, Icons.settings_outlined, 'Settings',
            'Account and preferences', false,
            () { Navigator.pop(context); context.go('/account'); }),
        _menuItem(context, Icons.workspace_premium_outlined, 'Billing',
            'Manage subscription', false,
            () { Navigator.pop(context); context.go('/billing'); }),
        _menuItem(context, Icons.logout_rounded, 'Logout', 'End this session', true,
            () { Navigator.pop(context); ref.read(authControllerProvider.notifier).logout(); }),
      ]),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title,
      String sub, bool danger, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: danger ? const Color(0xFFFEF2F2) : TopwebsuiteTheme.primarySoft,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18,
              color: danger ? TopwebsuiteTheme.danger : TopwebsuiteTheme.primary)),
      title: Text(title, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: danger ? TopwebsuiteTheme.danger : TopwebsuiteTheme.ink)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted)),
      onTap: onTap,
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _ErpDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const items = [
      ('/', 'Dashboard', Icons.speed_rounded),
      ('/invoices', 'Invoices', Icons.receipt_long_outlined),
      ('/receipts', 'Receipts', Icons.receipt_outlined),
      ('/waybills', 'Waybills', Icons.local_shipping_outlined),
      ('/quotations', 'Quotations', Icons.request_quote_outlined),
      ('/letterheads', 'Letterheads', Icons.mail_outline_rounded),
      ('/business-profile', 'Business Profile', Icons.storefront_outlined),
      ('/crm', 'CRM', Icons.groups_2_outlined),
      ('/erp', 'ERP', Icons.inventory_2_outlined),
      ('/billing', 'Billing', Icons.workspace_premium_outlined),
    ];
    return Drawer(
      width: 285,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: TopwebsuiteTheme.primarySoft,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 18, color: TopwebsuiteTheme.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Topwebsuite',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: TopwebsuiteTheme.ink)),
                      Text('ERP',
                          style: TextStyle(
                              fontSize: 12,
                              color: TopwebsuiteTheme.muted)),
                    ]),
              ),
              IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: TopwebsuiteTheme.muted),
                  onPressed: () => Navigator.of(context).pop()),
            ]),
          ),
          const Divider(height: 1, color: TopwebsuiteTheme.border),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: items.map((item) {
                final active = item.$1 == '/erp';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    tileColor:
                        active ? TopwebsuiteTheme.primarySoft : null,
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: active
                              ? TopwebsuiteTheme.primary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(11)),
                      child: Icon(item.$3,
                          size: 16,
                          color: active
                              ? Colors.white
                              : TopwebsuiteTheme.primary),
                    ),
                    title: Text(item.$2,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? TopwebsuiteTheme.primary
                                : TopwebsuiteTheme.ink)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(item.$1);
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
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.logout_rounded,
                    size: 16, color: TopwebsuiteTheme.danger),
              ),
              title: const Text('Logout',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TopwebsuiteTheme.danger)),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── ERP Form ──────────────────────────────────────────────────────────────────

class _ErpForm extends ConsumerStatefulWidget {
  const _ErpForm({required this.config, this.row});
  final ResourceConfig config;
  final Map<String, dynamic>? row;

  @override
  ConsumerState<_ErpForm> createState() => _ErpFormState();
}

class _ErpFormState extends ConsumerState<_ErpForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = {
      for (final f in widget.config.fields)
        f.key: TextEditingController(
            text: widget.row?[f.key]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.row == null
        ? 'Create ${widget.config.title}'
        : 'Edit ${widget.config.title}';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      builder: (ctx, ctrl) => Material(
        color: TopwebsuiteTheme.surface,
        child: Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 36, height: 4,
                              decoration: BoxDecoration(
                                  color: TopwebsuiteTheme.border,
                                  borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 10),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: TopwebsuiteTheme.ink)),
                    ]),
              ),
              IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: TopwebsuiteTheme.muted),
                  onPressed: () => Navigator.of(ctx).pop(false)),
            ]),
          ),
          const Divider(height: 1, color: TopwebsuiteTheme.border),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final f in widget.config.fields) ...[
                    TextFormField(
                      controller: _ctrl[f.key],
                      maxLines: f.multiline ? 4 : 1,
                      style: const TextStyle(
                          color: TopwebsuiteTheme.ink, fontSize: 14),
                      keyboardType: switch (f.keyboard) {
                        FieldKeyboard.email  => TextInputType.emailAddress,
                        FieldKeyboard.phone  => TextInputType.phone,
                        FieldKeyboard.number => TextInputType.number,
                        FieldKeyboard.date   => TextInputType.datetime,
                        FieldKeyboard.url    => TextInputType.url,
                        _                    => TextInputType.text,
                      },
                      decoration: InputDecoration(
                        labelText: f.label,
                        labelStyle: const TextStyle(
                            fontSize: 13, color: TopwebsuiteTheme.muted),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: TopwebsuiteTheme.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: TopwebsuiteTheme.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: TopwebsuiteTheme.primary,
                                width: 1.4)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: f.required
                          ? (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, MediaQuery.of(ctx).padding.bottom + 10),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: TopwebsuiteTheme.border),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: TopwebsuiteTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(_saving ? 'Saving...' : 'Save Record',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      for (final e in _ctrl.entries) e.key: e.value.text.trim()
    };
    try {
      final id = stringValue(widget.row ?? {}, widget.config.idKeys);
      if (widget.row == null || id.isEmpty) {
        await ref.read(resourceRepositoryProvider).create(widget.config, payload);
      } else {
        await ref
            .read(resourceRepositoryProvider)
            .update(widget.config, id, payload);
      }
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
}
