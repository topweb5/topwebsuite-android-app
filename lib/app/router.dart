import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/account/presentation/account_settings_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/drafts/presentation/offline_drafts_screen.dart';
import '../features/modules/module_configs.dart';
import '../features/modules/presentation/crm_workspace_screen.dart';
import '../features/modules/presentation/erp_workspace_screen.dart';
import '../features/release/presentation/release_setup_screen.dart';
import '../features/shared/presentation/doc_workspace_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final isLoading = auth.isLoading;
      final isAuthed = auth.value != null;
      final location = state.matchedLocation;
      const authRoutes = {
        '/login',
        '/signup',
        '/forgot-password',
        '/verify-email',
      };

      if (isLoading && (location == '/splash' || authRoutes.contains(location))) {
        return null;
      }
      if (isLoading) return location == '/splash' ? null : '/splash';
      if (!isAuthed && !authRoutes.contains(location)) return '/login';
      if (isAuthed && (authRoutes.contains(location) || location == '/splash')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(email: state.extra?.toString() ?? '')),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // Dashboard
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),

      // ── Individual document screens ─────────────────────────────────────────
      GoRoute(path: '/invoices',
        builder: (_, __) => DocWorkspaceScreen(
          config: documentConfigs.firstWhere((c) => c.key == 'invoices'))),
      GoRoute(path: '/receipts',
        builder: (_, __) => DocWorkspaceScreen(
          config: documentConfigs.firstWhere((c) => c.key == 'receipts'))),
      GoRoute(path: '/waybills',
        builder: (_, __) => DocWorkspaceScreen(
          config: documentConfigs.firstWhere((c) => c.key == 'waybills'))),
      GoRoute(path: '/quotations',
        builder: (_, __) => DocWorkspaceScreen(
          config: documentConfigs.firstWhere((c) => c.key == 'quotations'))),
      GoRoute(path: '/letterheads',
        builder: (_, __) => DocWorkspaceScreen(
          config: letterConfigs.firstWhere((c) => c.key == 'letters'),
          letterheadConfig: letterConfigs.firstWhere((c) => c.key == 'letterhead'),
        )),

      // Keep /documents as a redirect to /invoices
      GoRoute(path: '/documents', redirect: (_, __) => '/invoices'),
      GoRoute(path: '/letters',   redirect: (_, __) => '/letterheads'),

      // ── Business profile ────────────────────────────────────────────────────
      GoRoute(path: '/business-profile',
        builder: (_, __) => DocWorkspaceScreen(config: businessProfileConfig)),

      // ── CRM / ERP (dedicated workspace screens) ────────────────────────────
      GoRoute(path: '/crm', builder: (_, __) => const CrmWorkspaceScreen()),
      GoRoute(path: '/erp', builder: (_, __) => const ErpWorkspaceScreen()),

      // ── Account / Billing ───────────────────────────────────────────────────
      GoRoute(path: '/account',  builder: (_, __) => const AccountSettingsScreen()),
      GoRoute(path: '/billing',  builder: (_, __) => const BillingScreen()),
      GoRoute(path: '/drafts',   builder: (_, __) => const OfflineDraftsScreen()),
      GoRoute(path: '/release',  builder: (_, __) => const ReleaseSetupScreen()),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
