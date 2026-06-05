import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../storage/secure_token_store.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(secureTokenStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] == true) {
          handler.next(options);
          return;
        }
        final token = await tokenStore.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final request = error.requestOptions;
        final isAuthRefresh = request.path.contains('/api/auth/refresh');
        final skipAuth = request.extra['skipAuth'] == true;

        if (response?.statusCode == 401 &&
            !skipAuth &&
            !isAuthRefresh &&
            !request.extra.containsKey('retried')) {
          final refreshed = await _refreshToken(dio, tokenStore);
          if (refreshed) {
            final retry = await dio.fetch<dynamic>(
              request
                ..extra['retried'] = true
                ..headers['Authorization'] =
                    'Bearer ${await tokenStore.readAccessToken()}',
            );
            handler.resolve(retry);
            return;
          }
        }

        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false),
    );
  }

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(extra: {'skipAuth': !authenticated}),
      ),
    );
    return _asMap(response.data);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    final response = await _request<dynamic>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(extra: {'skipAuth': !authenticated}),
      ),
    );
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['results'] is List) {
      return data['results'] as List<dynamic>;
    }
    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return const [];
  }

  Future<Map<String, dynamic>> postMap(
    String path,
    Object? body, {
    bool authenticated = true,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.post<dynamic>(
        path,
        data: body,
        options: Options(extra: {'skipAuth': !authenticated}),
      ),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> patchMap(String path, Object? body) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.patch<dynamic>(path, data: body),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> putMap(String path, Object? body) async {
    final response = await _request<Map<String, dynamic>>(
      () => _dio.put<dynamic>(path, data: body),
    );
    return _asMap(response.data);
  }

  Future<void> delete(String path) async {
    await _request<dynamic>(() => _dio.delete<dynamic>(path));
  }

  Future<Response<List<int>>> download(String path) {
    return _request<List<int>>(
      () => _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      ),
    );
  }

  Future<Response<T>> _request<T>(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return Response<T>(
        data: response.data as T?,
        requestOptions: response.requestOptions,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        extra: response.extra,
        headers: response.headers,
      );
    } on DioException catch (error) {
      throw ApiException(
        _extractMessage(error.response?.data, error.message),
        statusCode: error.response?.statusCode,
        data: error.response?.data,
      );
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _extractMessage(Object? data, String? fallback) {
    if (data is Map) {
      for (final key in ['detail', 'message', 'error']) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      if (data.isNotEmpty) {
        final key = data.keys.first;
        final value = data[key];
        if (value is List) return '$key: ${value.join(', ')}';
        return '$key: $value';
      }
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return fallback ?? 'Request failed. Please try again.';
  }
}

Future<bool> _refreshToken(Dio dio, SecureTokenStore tokenStore) async {
  final refresh = await tokenStore.readRefreshToken();
  if (refresh == null || refresh.isEmpty) return false;

  try {
    final response = await dio.post<dynamic>(
      '/api/auth/refresh/',
      data: {'refresh': refresh},
      options: Options(
        headers: {'Authorization': null},
        extra: {'skipAuth': true},
      ),
    );
    final data = response.data;
    if (data is Map && data['access'] != null) {
      await tokenStore.saveTokens(
        access: data['access'].toString(),
        refresh: refresh,
      );
      return true;
    }
  } catch (_) {
    await tokenStore.clear();
  }
  return false;
}
