import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'passcode_model.dart';

/// TTLock API'si ile iletişim kurmak için kullanılan servis sınıfı.
/// Bu sınıf Singleton deseni kullanılarak oluşturulmuştur.
class TTLockService {
  // Singleton instance
  static final TTLockService _instance = TTLockService._internal();
  
  /// Servisin tekil örneğine erişim sağlar.
  factory TTLockService() {
    return _instance;
  }

  TTLockService._internal();

  static const String _baseUrl = "https://euapi.ttlock.com/v3";
  static const _headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  /// Bir kilide ait tüm şifreleri listeler.
  /// 
  /// Başarılı olursa [Passcode] listesi, başarısız olursa boş liste döner.
  Future<List<Passcode>> getPasscodes({
    required String clientId,
    required String accessToken,
    required int lockId,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/lock/listKeyboardPwd').replace(
      queryParameters: {
        'clientId': clientId,
        'accessToken': accessToken,
        'lockId': lockId.toString(),
        'pageNo': pageNo.toString(),
        'pageSize': pageSize.toString(),
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          final List<dynamic> passcodesJson = data['list'];
          return passcodesJson.map((json) => Passcode.fromJson(json)).toList();
        }
      }
      // Hata durumunda loglama yapılabilir.
      debugPrint('Error getPasscodes: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Exception in getPasscodes: $e');
      return [];
    }
  }

  /// Uzaktan özel bir şifre oluşturur.
  ///
  /// Başarılı olursa yeni şifrenin ID'sini [int], başarısız olursa `null` döner.
  Future<int?> addCustomPasscode({
    required String clientId,
    required String accessToken,
    required int lockId,
    required String keyboardPwd,
    required String keyboardPwdName,
    int keyboardPwdType = 3, // 2: Permanent, 3: Period
    int? startDate, // Milisaniye cinsinden, periyodik şifre için zorunlu
    int? endDate, // Milisaniye cinsinden, periyodik şifre için zorunlu
    int addType = 2, // 2: Gateway/WiFi üzerinden uzaktan ekleme
  }) async {
    final uri = Uri.parse('$_baseUrl/keyboardPwd/add');
    final body = {
      'clientId': clientId,
      'accessToken': accessToken,
      'lockId': lockId.toString(),
      'keyboardPwd': keyboardPwd,
      'keyboardPwdName': keyboardPwdName,
      'keyboardPwdType': keyboardPwdType.toString(),
      'addType': addType.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (startDate != null) body['startDate'] = startDate.toString();
    if (endDate != null) body['endDate'] = endDate.toString();

    try {
      final response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['keyboardPwdId'] != null) {
          return data['keyboardPwdId'] as int;
        }
      }
      debugPrint('Error addCustomPasscode: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Exception in addCustomPasscode: $e');
      return null;
    }
  }

  /// Bir şifreyi uzaktan siler.
  ///
  /// Başarılı olursa `true`, başarısız olursa `false` döner.
  Future<bool> deletePasscode({
    required String clientId,
    required String accessToken,
    required int lockId,
    required int keyboardPwdId,
    int deleteType = 2, // 2: Gateway/WiFi üzerinden uzaktan silme
  }) async {
    final uri = Uri.parse('$_baseUrl/keyboardPwd/delete');
    final body = {
      'clientId': clientId,
      'accessToken': accessToken,
      'lockId': lockId.toString(),
      'keyboardPwdId': keyboardPwdId.toString(),
      'deleteType': deleteType.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    try {.
      final response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // API, başarılı olduğunda errcode: 0 döner.
        return data['errcode'] == 0;
      }
      debugPrint('Error deletePasscode: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Exception in deletePasscode: $e');
      return false;
    }
  }

  /// Bir şifrenin adını, kendisini veya geçerlilik süresini değiştirir.
  ///
  /// Başarılı olursa `true`, başarısız olursa `false` döner.
  Future<bool> changePasscode({
    required String clientId,
    required String accessToken,
    required int lockId,
    required int keyboardPwdId,
    String? newKeyboardPwd,
    String? keyboardPwdName,
    int? startDate,
    int? endDate,
    int changeType = 2, // 2: Gateway/WiFi üzerinden uzaktan değiştirme
  }) async {
    final uri = Uri.parse('$_baseUrl/keyboardPwd/change');
    final body = {
      'clientId': clientId,
      'accessToken': accessToken,
      'lockId': lockId.toString(),
      'keyboardPwdId': keyboardPwdId.toString(),
      'changeType': changeType.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    // Opsiyonel parametreler sadece null değillerse eklenir.
    if (newKeyboardPwd != null) body['newKeyboardPwd'] = newKeyboardPwd;
    if (keyboardPwdName != null) body['keyboardPwdName'] = keyboardPwdName;
    if (startDate != null) body['startDate'] = startDate.toString();
    if (endDate != null) body['endDate'] = endDate.toString();

    try {
      final response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['errcode'] == 0;
      }
      debugPrint('Error changePasscode: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Exception in changePasscode: $e');
      return false;
    }
  }
}
