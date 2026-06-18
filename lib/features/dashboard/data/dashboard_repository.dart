import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../domain/dashboard_data.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    api: ref.watch(apiClientProvider),
    store: ref.watch(localStoreProvider),
  );
});

/// Loads the dashboard snapshot in a single parallel pass and caches the last
/// successful result on disk so the next launch can paint instantly.
class DashboardRepository {
  DashboardRepository({required this.api, required this.store});

  final ApiClient api;
  final LocalStore store;

  static const _cacheKey = 'topwebsuite_dashboard_cache';

  Future<DashboardData?> readCache() async {
    final json = await store.readJson(_cacheKey);
    if (json == null) return null;
    try {
      return DashboardData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<DashboardData> fetch() async {
    // One parallel pass. Each list is fetched exactly once and reused for both
    // the counts and the recent-documents feed (previously fetched twice).
    final results = await Future.wait([
      _safeMap('/api/billing/subscription/'),
      _safeMap('/api/auth/usage/'),
      _safeList('/api/invoices/'),
      _safeList('/api/receipts/'),
      _safeList('/api/waybills/'),
      _safeList('/api/letters/'),
      _safeList('/api/quotations/'),
      _safeList('/api/v1/business-profile/'),
    ]);

    final subscription = results[0] as Map<String, dynamic>;
    final usage = results[1] as Map<String, dynamic>;
    final invoices = results[2] as List<dynamic>;
    final receipts = results[3] as List<dynamic>;
    final waybills = results[4] as List<dynamic>;
    final letters = results[5] as List<dynamic>;
    final quotations = results[6] as List<dynamic>;
    final profiles = results[7] as List<dynamic>;

    final recent = <Map<String, dynamic>>[];
    for (final list in [invoices, receipts, waybills, letters]) {
      recent.addAll(list.whereType<Map<String, dynamic>>());
    }

    final profileSummary = profiles.isEmpty
        ? {'count': 0, 'score': 0, 'status': ''}
        : {
            'count': profiles.length,
            'score': (profiles.first as Map)['completeness_score'] ?? 0,
            'status':
                (profiles.first as Map)['publish_status']?.toString() ?? '',
          };

    final data = DashboardData(
      subscription: subscription,
      usage: usage,
      counts: {
        'invoices': invoices.length,
        'receipts': receipts.length,
        'waybills': waybills.length,
        'letters': letters.length,
        'quotations': quotations.length,
        'profiles': profiles.length,
      },
      recentDocs: recent.take(6).toList(),
      profile: profileSummary,
    );

    await store.writeJson(_cacheKey, data.toJson());
    return data;
  }

  Future<Map<String, dynamic>> _safeMap(String path) async {
    try {
      return await api.getMap(path);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<List<dynamic>> _safeList(String path) async {
    try {
      return await api.getList(path);
    } catch (_) {
      return const [];
    }
  }
}
