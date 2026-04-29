import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _baseUrlKey = 'base_url';
  static const _uidKey = 'uid';
  static const _md5PasswordKey = 'md5_password';

  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
    String? baseUrl,
    int? uid,
    String? md5Password,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(
        key: _tokenExpiryKey, value: expiry.millisecondsSinceEpoch.toString());
    
    if (baseUrl != null) {
      await _secureStorage.write(key: _baseUrlKey, value: baseUrl);
    }
    if (uid != null) {
      await _secureStorage.write(key: _uidKey, value: uid.toString());
    }
    if (md5Password != null) {
      await _secureStorage.write(key: _md5PasswordKey, value: md5Password);
    }
  }

  Future<String?> getBaseUrl() async {
    return await _secureStorage.read(key: _baseUrlKey);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<int?> getUid() async {
    final uidStr = await _secureStorage.read(key: _uidKey);
    return uidStr != null ? int.tryParse(uidStr) : null;
  }

  Future<String?> getMd5Password() async {
    return await _secureStorage.read(key: _md5PasswordKey);
  }

  Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
    if (expiryStr != null) {
      final expiryMs = int.tryParse(expiryStr);
      if (expiryMs != null) {
        return DateTime.fromMillisecondsSinceEpoch(expiryMs);
      }
    }
    return null;
  }

  Future<bool> isTokenValid() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;
    // Check if token expires in more than 5 minutes (safety buffer)
    return DateTime.now().isBefore(expiry.subtract(const Duration(minutes: 5)));
  }

  Future<void> deleteTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
    await _secureStorage.delete(key: _baseUrlKey);
    await _secureStorage.delete(key: _uidKey);
    await _secureStorage.delete(key: _md5PasswordKey);
  }
}
