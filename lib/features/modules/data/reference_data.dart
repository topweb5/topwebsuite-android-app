import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Reference lists used to populate select fields (Business Profile category and
/// country). Cached for the session by Riverpod.

final businessCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await ref
      .watch(apiClientProvider)
      .getList('/api/v1/business-profile/categories/');
  return rows
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

final countriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await ref
      .watch(apiClientProvider)
      .getList('/api/directory/countries/');
  return rows
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});
