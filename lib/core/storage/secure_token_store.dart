import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return const SecureTokenStore(FlutterSecureStorage());
});

class SecureTokenStore {
  const SecureTokenStore(this._storage);

  static const _accessKey = 'topwebsuite_access_token';
  static const _refreshKey = 'topwebsuite_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _read(_accessKey);

  Future<String?> readRefreshToken() => _read(_refreshKey);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _write(_accessKey, access);
    if (refresh != null) await _write(_refreshKey, refresh);
  }

  Future<void> clear() async {
    await _delete(_accessKey);
    await _delete(_refreshKey);
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }
}
