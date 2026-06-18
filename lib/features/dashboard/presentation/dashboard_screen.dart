import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../app/theme.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../auth/application/auth_controller.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_data.dart';

/// Opens the in-app review prompt, falling back to the store listing page.
Future<void> rateApp() async {
  final review = InAppReview.instance;
  try {
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  } catch (_) {
    // Reviewing is optional; ignore failures (e.g. store unavailable).
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Prompt for an app update once the dashboard is shown (Android/Play only).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateServiceProvider).maybePromptUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF024EE0), // solid blue (top bar)
            Color(0xFF024EE0), // hold blue until first card
            Color(0xFFFFFFFF), // pure white
          ],
          stops: [0.0, 0.15, 0.55],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const _AppDrawer(),
        body: const _HomeBody(),
        bottomNavigationBar: const _CreateBar(),
      ),
    );
  }
}

// ── Create bar (full-width bottom button) ─────────────────────────────────────

class _CreateBar extends StatelessWidget {
  const _CreateBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateSheet(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Create Document'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TopwebsuiteTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateSheet(),
    );
  }
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

  static const _items = [
    ('Invoice', Icons.receipt_long_outlined, '/invoices'),
    ('Receipt', Icons.receipt_outlined, '/receipts'),
    ('Waybill', Icons.local_shipping_outlined, '/waybills'),
    ('Quotation', Icons.request_quote_outlined, '/quotations'),
    ('Letterhead', Icons.mail_outline_rounded, '/letterheads'),
  ];

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
            'Create New Document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in _items)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.$2, size: 18, color: TopwebsuiteTheme.primary),
              ),
              title: Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: TopwebsuiteTheme.muted,
              ),
              onTap: () {
                Navigator.pop(context);
                context.go(item.$3);
              },
            ),
        ],
      ),
    );
  }
}

// ── Drawer (web sidebar) ──────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const menuItems = [
      _DrawerItem('Dashboard', Icons.speed_rounded, '/'),
      _DrawerItem('Invoices', Icons.receipt_long_outlined, '/invoices'),
      _DrawerItem('Receipts', Icons.receipt_outlined, '/receipts'),
      _DrawerItem('Waybills', Icons.local_shipping_outlined, '/waybills'),
      _DrawerItem('Quotations', Icons.request_quote_outlined, '/quotations'),
      _DrawerItem('Letterheads', Icons.mail_outline_rounded, '/letterheads'),
      _DrawerItem(
        'Business Profile',
        Icons.storefront_outlined,
        '/business-profile',
      ),
      _DrawerItem('CRM', Icons.groups_2_outlined, '/crm'),
      _DrawerItem('ERP', Icons.inventory_2_outlined, '/erp'),
      _DrawerItem('Billing', Icons.workspace_premium_outlined, '/billing'),
    ];

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
                        Text(
                          'Topwebsuite',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TopwebsuiteTheme.ink,
                          ),
                        ),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 12,
                            color: TopwebsuiteTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TopwebsuiteTheme.muted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: TopwebsuiteTheme.border),

            // Menu label
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MAIN MENU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),

            // Menu items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: menuItems.length,
                itemBuilder: (context, i) {
                  final item = menuItems[i];
                  final isActive =
                      item.route == '/' &&
                      GoRouterState.of(context).matchedLocation == '/';
                  return _DrawerMenuItem(item: item, isActive: isActive);
                },
              ),
            ),

            // Footer — logout
            const Divider(height: 1, color: TopwebsuiteTheme.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 17,
                    color: TopwebsuiteTheme.danger,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TopwebsuiteTheme.danger,
                  ),
                ),
                subtitle: const Text(
                  'End this session',
                  style: TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted),
                ),
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

class _DrawerItem {
  const _DrawerItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({required this.item, required this.isActive});
  final _DrawerItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isActive ? TopwebsuiteTheme.primarySoft : null,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? TopwebsuiteTheme.primary
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            size: 17,
            color: isActive ? Colors.white : TopwebsuiteTheme.primary,
          ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? TopwebsuiteTheme.primary : TopwebsuiteTheme.ink,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          context.go(item.route);
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Container(
      color: TopwebsuiteTheme.primary,
      padding: EdgeInsets.fromLTRB(
        10,
        MediaQuery.of(context).padding.top + 8,
        10,
        8,
      ),
      child: Row(
        children: [
          // Hamburger
          _TopIconBtn(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),

          // Search bar
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search documents...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Quick-create (+)
          _TopIconBtn(
            icon: Icons.add_rounded,
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const _CreateSheet(),
            ),
          ),
          const SizedBox(width: 8),

          // User avatar
          if (user != null)
            GestureDetector(
              onTap: () => _showUserMenu(context, ref),
              child: _UserAvatar(name: user.displayName),
            ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref) {
    final user = ref.read(authControllerProvider).value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserMenuSheet(user: user),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  const _TopIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'U'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TopwebsuiteTheme.primary, Color(0xFF5B9FE8)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _UserMenuSheet extends ConsumerWidget {
  const _UserMenuSheet({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Scrollable so the menu never overflows on short screens.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // User header
            if (user != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TopwebsuiteTheme.border),
                ),
                child: Row(
                  children: [
                    _UserAvatar(name: user.displayName ?? ''),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TopwebsuiteTheme.ink,
                            ),
                          ),
                          Text(
                            user.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: TopwebsuiteTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Menu items
            _UserMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'User Profile',
              subtitle: 'Update your business details',
              onTap: () {
                Navigator.pop(context);
                context.push('/account');
              },
            ),
            _UserMenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              subtitle: 'Account and preferences',
              onTap: () {
                Navigator.pop(context);
                context.push('/account');
              },
            ),
            _UserMenuItem(
              icon: Icons.workspace_premium_outlined,
              label: 'Upgrade Plan',
              subtitle: 'Manage subscription',
              onTap: () {
                Navigator.pop(context);
                context.push('/billing');
              },
            ),
            _UserMenuItem(
              icon: Icons.star_outline_rounded,
              label: 'Rate this app',
              subtitle: 'Leave a review on the store',
              onTap: () {
                Navigator.pop(context);
                rateApp();
              },
            ),
            _UserMenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              subtitle: 'End this session',
              destructive: true,
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMenuItem extends StatelessWidget {
  const _UserMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: destructive
              ? const Color(0xFFFEF2F2)
              : TopwebsuiteTheme.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: destructive
              ? TopwebsuiteTheme.danger
              : TopwebsuiteTheme.primary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted),
      ),
      onTap: onTap,
    );
  }
}

// ── Home body ─────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardControllerProvider);
    final data = async.value ?? DashboardData.empty;
    final loading = async.isLoading && async.value == null;
    final summaryMap = {'subscription': data.subscription, 'usage': data.usage};

    return RefreshIndicator(
      color: TopwebsuiteTheme.primary,
      onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Top bar
          SliverToBoxAdapter(child: Builder(builder: (ctx) => _TopBar())),
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: TopwebsuiteTheme.border),
          ),

          // ── Overview heading
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: _OverviewHeader(),
            ),
          ),

          // ── Action tiles 2-col grid (cards self-stagger in)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _ActionTilesGrid()),
          ),

          // ── PLAN + PROFILE compact panels
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: loading
                  ? const _Shimmer(height: 230)
                  : EntranceAnimation(
                      delay: const Duration(milliseconds: 70),
                      child: Column(
                        children: [
                          _PlanCompactPanel(data: summaryMap),
                          const SizedBox(height: 12),
                          _ProfileCompactPanel(profile: data.profile),
                        ],
                      ),
                    ),
            ),
          ),

          // ── Stats 2-col grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: loading
                  ? const _Shimmer(height: 160)
                  : _StatsGrid(counts: data.counts),
            ),
          ),

          // ── Recent Documents
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: loading
                  ? const _Shimmer(height: 200)
                  : EntranceAnimation(
                      delay: const Duration(milliseconds: 210),
                      child: _RecentDocsPanel(docs: data.recentDocs),
                    ),
            ),
          ),

          // ── Subscription + Business Profile mini-panels
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: loading
                  ? const _Shimmer(height: 160)
                  : EntranceAnimation(
                      delay: const Duration(milliseconds: 280),
                      child: _SidePanels(data: summaryMap),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Overview header ───────────────────────────────────────────────────────────

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Business Dashboard',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Action tiles 2-column grid ────────────────────────────────────────────────

class _ActionTile {
  const _ActionTile({
    required this.label,
    required this.detail,
    required this.icon,
    required this.route,
    this.primary = false,
  });
  final String label;
  final String detail;
  final IconData icon;
  final String route;
  final bool primary;
}

class _ActionTilesGrid extends StatelessWidget {
  const _ActionTilesGrid();

  static const _tiles = [
    _ActionTile(
      label: 'Invoice',
      detail: 'Create new',
      icon: Icons.receipt_long_outlined,
      route: '/invoices',
      primary: true,
    ),
    _ActionTile(
      label: 'Receipt',
      detail: 'Create new',
      icon: Icons.receipt_outlined,
      route: '/receipts',
    ),
    _ActionTile(
      label: 'Waybill',
      detail: 'Create new',
      icon: Icons.local_shipping_outlined,
      route: '/waybills',
    ),
    _ActionTile(
      label: 'Quotation',
      detail: 'Create new',
      icon: Icons.request_quote_outlined,
      route: '/quotations',
    ),
    _ActionTile(
      label: 'Letterhead',
      detail: 'Manage letters',
      icon: Icons.mail_outline_rounded,
      route: '/letterheads',
    ),
    _ActionTile(
      label: 'Business Profile',
      detail: 'Manage listing',
      icon: Icons.storefront_outlined,
      route: '/business-profile',
    ),
    _ActionTile(
      label: 'CRM',
      detail: 'Track pipeline',
      icon: Icons.groups_2_outlined,
      route: '/crm',
    ),
    _ActionTile(
      label: 'ERP',
      detail: 'Manage operations',
      icon: Icons.inventory_2_outlined,
      route: '/erp',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.0,
          ),
          itemCount: _tiles.length,
          itemBuilder: (context, i) => EntranceAnimation(
            delay: Duration(milliseconds: 45 * i),
            offsetY: 14,
            child: _ActionTileCard(tile: _tiles[i]),
          ),
        ),
      ),
    );
  }
}

class _ActionTileCard extends StatelessWidget {
  const _ActionTileCard({required this.tile});
  final _ActionTile tile;

  @override
  Widget build(BuildContext context) {
    final isPrimary = tile.primary;
    return GestureDetector(
      onTap: () => context.go(tile.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? TopwebsuiteTheme.primary
              : TopwebsuiteTheme.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? TopwebsuiteTheme.primary
                : const Color(0xFFEAF0F7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : TopwebsuiteTheme.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tile.icon,
                size: 17,
                color: isPrimary ? Colors.white : TopwebsuiteTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tile.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? Colors.white : TopwebsuiteTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tile.detail,
                    style: TextStyle(
                      fontSize: 11,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.75)
                          : TopwebsuiteTheme.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ── PLAN compact panel ────────────────────────────────────────────────────────

class _PlanCompactPanel extends StatelessWidget {
  const _PlanCompactPanel({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final subscription = data['subscription'] as Map<String, dynamic>? ?? {};
    final usage = data['usage'] as Map<String, dynamic>? ?? {};
    final plan = subscription['plan']?.toString() ?? 'Free';
    final currency = subscription['currency']?.toString() ?? '';
    final billingCur = subscription['billing_currency']?.toString() ?? '';
    final used = (usage['usage_used'] as num?)?.toInt() ?? 0;
    final limitRaw = usage['usage_limit'];
    final isUnlimited = limitRaw == null;
    final limit = isUnlimited ? 0 : (limitRaw as num).toInt();
    final progress = isUnlimited || limit == 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);
    final pct = isUnlimited ? 0 : (progress * 100).round();
    final planLabel = [
      plan,
      currency,
      billingCur,
    ].where((s) => s.isNotEmpty).join(' · ');

    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PLAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    planLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TopwebsuiteTheme.success,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            Text(
              isUnlimited
                  ? 'Unlimited documents'
                  : '$used / $limit documents used',
              style: const TextStyle(
                fontSize: 13,
                color: TopwebsuiteTheme.muted,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFD6E2FB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.85
                      ? TopwebsuiteTheme.warning
                      : TopwebsuiteTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PROFILE compact panel ─────────────────────────────────────────────────────

class _ProfileCompactPanel extends StatelessWidget {
  const _ProfileCompactPanel({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final count = (profile['count'] as int?) ?? 0;
    final score = (profile['score'] as num?)?.toInt() ?? 0;
    final status = profile['status']?.toString() ?? '';
    final isVerified = status == 'verified';

    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROFILE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isVerified
                            ? TopwebsuiteTheme.success
                            : TopwebsuiteTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              count == 0 ? '--' : '$score%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            Text(
              count == 0 ? 'No profiles yet' : '$count profile in workspace',
              style: const TextStyle(
                fontSize: 13,
                color: TopwebsuiteTheme.muted,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.go('/business-profile'),
              child: const Text(
                'Manage profiles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats 2-col grid ──────────────────────────────────────────────────────────

class _StatDef {
  const _StatDef(this.label, this.key, this.icon);
  final String label;
  final String key;
  final IconData icon;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.counts});
  final Map<String, int> counts;

  static const _defs = [
    _StatDef('Invoices', 'invoices', Icons.receipt_long_outlined),
    _StatDef('Receipts', 'receipts', Icons.receipt_outlined),
    _StatDef('Waybills', 'waybills', Icons.local_shipping_outlined),
    _StatDef('Letters', 'letters', Icons.mail_outline_rounded),
    _StatDef('Quotations', 'quotations', Icons.request_quote_outlined),
    _StatDef('Business Profiles', 'profiles', Icons.storefront_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: _defs.length,
      itemBuilder: (context, i) => EntranceAnimation(
        delay: Duration(milliseconds: 45 * i),
        offsetY: 14,
        child: _StatCard(def: _defs[i], count: counts[_defs[i].key]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.def, required this.count});
  final _StatDef def;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06024EE0),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  def.icon,
                  size: 16,
                  color: TopwebsuiteTheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TopwebsuiteTheme.success,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count == null ? '--' : '$count',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.04,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
              Text(
                def.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: TopwebsuiteTheme.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent docs panel ─────────────────────────────────────────────────────────

class _RecentDocsPanel extends StatelessWidget {
  const _RecentDocsPanel({required this.docs});
  final List<Map<String, dynamic>> docs;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Documents',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TopwebsuiteTheme.ink,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/documents'),
                  child: const Row(
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TopwebsuiteTheme.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: TopwebsuiteTheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _EmptyDocs(),
            )
          else
            for (final doc in docs) _DocItem(doc: doc),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _EmptyDocs extends StatelessWidget {
  const _EmptyDocs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TopwebsuiteTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 18,
            color: TopwebsuiteTheme.muted,
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No recent documents',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
              Text(
                'Create your first document',
                style: TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  const _DocItem({required this.doc});
  final Map<String, dynamic> doc;

  @override
  Widget build(BuildContext context) {
    // Detect document type from fields
    final isReceipt =
        doc.containsKey('received_from') || doc.containsKey('receipt_number');
    final isWaybill =
        doc.containsKey('waybill_number') || doc.containsKey('recipient_name');
    final isLetter =
        doc.containsKey('content_html') || doc.containsKey('plain_text');
    final isQuotation = doc.containsKey('quotation_number');

    final docType = isReceipt
        ? 'Receipt'
        : isWaybill
        ? 'Waybill'
        : isLetter
        ? 'Letter'
        : isQuotation
        ? 'Quotation'
        : 'Invoice';

    final docIcon = isReceipt
        ? Icons.receipt_outlined
        : isWaybill
        ? Icons.local_shipping_outlined
        : isLetter
        ? Icons.mail_outline_rounded
        : isQuotation
        ? Icons.request_quote_outlined
        : Icons.receipt_long_outlined;

    final number =
        _findStr(doc, [
          'invoice_number',
          'receipt_number',
          'waybill_number',
          'quotation_number',
          'title',
        ]) ??
        docType;
    final amount = _findStr(doc, ['total', 'amount', 'shipment_value']) ?? '0';
    final status = doc['status']?.toString() ?? '';
    final currency = doc['currency']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TopwebsuiteTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAF0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(docIcon, size: 16, color: TopwebsuiteTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TopwebsuiteTheme.ink,
                      ),
                    ),
                    Text(
                      docType,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TopwebsuiteTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (status.isNotEmpty) _StatusPill(status: status),
              const SizedBox(width: 8),
              Text(
                '$currency $amount'.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _findStr(Map<String, dynamic> doc, List<String> keys) {
    for (final k in keys) {
      final v = doc[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return null;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(String s) => switch (s.toLowerCase()) {
    'paid' => (const Color(0xFFF0FDF4), TopwebsuiteTheme.success),
    'pending' => (const Color(0xFFFFFBEB), TopwebsuiteTheme.warning),
    'overdue' => (const Color(0xFFFEF2F2), TopwebsuiteTheme.danger),
    'draft' => (TopwebsuiteTheme.primarySoft, TopwebsuiteTheme.primary),
    'final' => (TopwebsuiteTheme.primarySoft, TopwebsuiteTheme.primary),
    'transfer' => (TopwebsuiteTheme.primarySoft, TopwebsuiteTheme.primary),
    'shipped' => (TopwebsuiteTheme.primarySoft, TopwebsuiteTheme.primary),
    _ => (TopwebsuiteTheme.primarySoft, TopwebsuiteTheme.primary),
  };
}

// ── Side panels ───────────────────────────────────────────────────────────────

class _SidePanels extends StatelessWidget {
  const _SidePanels({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final subscription = data['subscription'] as Map<String, dynamic>? ?? {};
    final renewal = subscription['renewal_date']?.toString() ?? '';
    final billingCur = subscription['billing_currency']?.toString() ?? '';

    return Column(
      children: [
        _MiniPanel(
          icon: Icons.workspace_premium_rounded,
          title: 'Subscription',
          subtitle: [
            renewal.isEmpty ? '' : 'Renewal: $renewal',
            billingCur.isEmpty ? '' : 'Billing in $billingCur',
          ].where((s) => s.isNotEmpty).join(' · '),
          actionLabel: 'Manage',
          primaryAction: true,
          onAction: () => context.push('/billing'),
        ),
        const SizedBox(height: 10),
        _MiniPanel(
          icon: Icons.storefront_outlined,
          title: 'Business Profile',
          subtitle: 'Manage your public business listing',
          actionLabel: 'Update',
          onAction: () => context.go('/business-profile'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.primaryAction = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: TopwebsuiteTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
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
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: TopwebsuiteTheme.muted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAction
                      ? TopwebsuiteTheme.primary
                      : Colors.white,
                  foregroundColor: primaryAction
                      ? Colors.white
                      : TopwebsuiteTheme.ink,
                  elevation: 0,
                  side: primaryAction
                      ? null
                      : const BorderSide(color: TopwebsuiteTheme.border),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared panel container ────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
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
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
