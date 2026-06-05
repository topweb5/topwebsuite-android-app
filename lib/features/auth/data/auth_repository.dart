import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiClientProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
    localStore: ref.watch(localStoreProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required this.api,
    required this.tokenStore,
    required this.localStore,
    Random? random,
  }) : _random = random ?? Random();

  final ApiClient api;
  final SecureTokenStore tokenStore;
  final LocalStore localStore;
  final Random _random;

  Future<AppUser?> bootstrap() async {
    final token = await tokenStore.readAccessToken();
    if (token == null || token.isEmpty) return null;
    return me();
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await api.postMap('/api/auth/login/', {
      'email': email,
      'password': password,
    }, authenticated: false);
    await _saveSession(response);
    return AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
  }

  Future<void> signup({
    required String email,
    required String fullName,
    required String password,
  }) async {
    ApiException? lastUsernameError;
    for (var attempt = 0; attempt < 4; attempt += 1) {
      final username = _generateUsername(fullName, email);
      try {
        await api.postMap('/api/auth/signup/', {
          'email': email,
          'username': username,
          'full_name': fullName,
          'password': password,
        }, authenticated: false);
        return;
      } on ApiException catch (error) {
        if (_isUsernameValidationError(error) && attempt < 3) {
          lastUsernameError = error;
          continue;
        }
        rethrow;
      }
    }
    if (lastUsernameError != null) throw lastUsernameError;
  }

  Future<AppUser> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await api.postMap('/api/auth/verify-email-otp/', {
      'email': email,
      'otp': otp,
    }, authenticated: false);
    await _saveSession(response);
    return AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
  }

  Future<void> resendOtp(String email) {
    return api
        .postMap('/api/auth/resend-email-otp/', {
          'email': email,
        }, authenticated: false)
        .then((_) {});
  }

  Future<void> forgotPassword(String email) {
    return api
        .postMap('/api/auth/forgot-password/', {
          'email': email,
        }, authenticated: false)
        .then((_) {});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return api
        .postMap('/api/auth/reset-password/', {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }, authenticated: false)
        .then((_) {});
  }

  Future<AppUser> me() async {
    final response = await api.getMap('/api/auth/me/');
    final user = AppUser.fromJson(response);
    await localStore.writeJson('topwebsuite_user', user.toJson());
    return user;
  }

  Future<void> logout() async {
    try {
      await api.postMap('/api/auth/logout/', {});
    } finally {
      await tokenStore.clear();
      await localStore.remove('topwebsuite_user');
    }
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    final access = response['access']?.toString();
    final refresh = response['refresh']?.toString();
    final user = response['user'];
    if (access == null || access.isEmpty) return;
    await tokenStore.saveTokens(access: access, refresh: refresh);
    if (user is Map) {
      await localStore.writeJson(
        'topwebsuite_user',
        Map<String, dynamic>.from(user),
      );
    }
  }

  String _generateUsername(String fullName, String email) {
    final nameBase = fullName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    final emailBase = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
    final base = nameBase.isNotEmpty
        ? nameBase
        : (emailBase.isNotEmpty ? emailBase : 'user');
    final randomPart = 1000 + _random.nextInt(9000);
    return '$base$randomPart';
  }

  bool _isUsernameValidationError(ApiException error) {
    final data = error.data;
    return error.statusCode == 400 && data is Map && data['username'] != null;
  }
}
