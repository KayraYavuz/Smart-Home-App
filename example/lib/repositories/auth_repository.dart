import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _baseUrlKey = 'base_url';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
    String? baseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_tokenExpiryKey, expiry.millisecondsSinceEpoch);
    if (baseUrl != null) {
      await prefs.setString(_baseUrlKey, baseUrl);
    }
  }

  Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt(_tokenExpiryKey);
    if (expiryMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(expiryMs);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_baseUrlKey);
  }

}
