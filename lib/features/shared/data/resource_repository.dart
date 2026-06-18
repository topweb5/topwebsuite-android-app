import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';
import '../domain/resource_config.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository(ref.watch(apiClientProvider));
});

class ResourceRepository {
  ResourceRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list(ResourceConfig config) async {
    final rows = await _api.getList(config.listPath);
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<Map<String, dynamic>> detail(ResourceConfig config, String id) async {
    return unwrapData(await _api.getMap(config.detailPath(id)));
  }

  Future<Map<String, dynamic>> create(
    ResourceConfig config,
    Map<String, dynamic> payload,
  ) async {
    return unwrapData(await _api.postMap(config.createPath, payload));
  }

  Future<Map<String, dynamic>> update(
    ResourceConfig config,
    String id,
    Map<String, dynamic> payload,
  ) async {
    return unwrapData(await _api.patchMap(config.updatePath(id), payload));
  }

  Future<void> remove(ResourceConfig config, String id) {
    return _api.delete(config.deletePath(id));
  }

  /// Multipart create — used when a resource needs a file upload (e.g. the
  /// letterhead asset file).
  Future<Map<String, dynamic>> createMultipart(
    ResourceConfig config,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    return unwrapData(
      await _api.multipartPost(config.createPath, fields: fields, files: files),
    );
  }

  Future<Map<String, dynamic>> updateMultipart(
    ResourceConfig config,
    String id,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    return unwrapData(
      await _api.multipartPatch(
        config.updatePath(id),
        fields: fields,
        files: files,
      ),
    );
  }
}
