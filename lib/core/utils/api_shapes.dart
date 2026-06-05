Map<String, dynamic> unwrapData(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  return response;
}

List<dynamic> normalizeList(Object? data) {
  if (data is List) {
    return data;
  }
  if (data is Map && data['data'] is List) {
    return data['data'] as List<dynamic>;
  }
  if (data is Map && data['results'] is List) {
    return data['results'] as List<dynamic>;
  }
  return const [];
}

String stringValue(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}
