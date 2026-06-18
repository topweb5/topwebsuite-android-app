/// Aggregated, cache-friendly snapshot of everything the dashboard renders.
///
/// Pure data (no Flutter imports) so it can be serialized to disk for
/// stale-while-revalidate loading.
class DashboardData {
  const DashboardData({
    required this.subscription,
    required this.usage,
    required this.counts,
    required this.recentDocs,
    required this.profile,
  });

  final Map<String, dynamic> subscription;
  final Map<String, dynamic> usage;
  final Map<String, int> counts;
  final List<Map<String, dynamic>> recentDocs;
  final Map<String, dynamic> profile;

  static const empty = DashboardData(
    subscription: {},
    usage: {},
    counts: {},
    recentDocs: [],
    profile: {},
  );

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      subscription: _map(json['subscription']),
      usage: _map(json['usage']),
      counts:
          (json['counts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      recentDocs: ((json['recentDocs'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      profile: _map(json['profile']),
    );
  }

  Map<String, dynamic> toJson() => {
    'subscription': subscription,
    'usage': usage,
    'counts': counts,
    'recentDocs': recentDocs,
    'profile': profile,
  };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
