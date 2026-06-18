import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard_data.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
      DashboardController.new,
    );

/// Stale-while-revalidate controller: paints cached data immediately on launch,
/// then refreshes from the network in the background.
class DashboardController extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final repo = ref.watch(dashboardRepositoryProvider);
    final cached = await repo.readCache();
    if (cached != null) {
      // Return cached instantly, then revalidate without blocking first paint.
      Future.microtask(_revalidate);
      return cached;
    }
    return repo.fetch();
  }

  Future<void> _revalidate() async {
    try {
      state = AsyncData(await ref.read(dashboardRepositoryProvider).fetch());
    } catch (_) {
      // Keep the cached snapshot if the background refresh fails.
    }
  }

  /// Pull-to-refresh. The current data stays visible during the await, then is
  /// replaced with the fresh snapshot (or an error).
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).fetch(),
    );
  }
}
