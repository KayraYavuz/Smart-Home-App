import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:yavuz_lock/config.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';


// Webhook olayları için model sınıfları
enum TTLockWebhookEventType {
  lockOpened,           // Kilit açıldı
  lockClosed,           // Kilit kapandı
  lockOpenedFromApp,    // Uygulamadan açıldı
  lockOpenedFromKeypad, // Tuş takımıyla açıldı
  lockOpenedFromFingerprint, // Parmak izi ile açıldı
  lockOpenedFromCard,   // Kart ile açıldı
  lowBattery,           // Düşük pil
  lockTampered,         // Kilit manipülasyonu
  unknown
}

/// TTLock Passcode Types for random passcode generation
/// These values correspond to the keyboardPwdType parameter in TTLock API
enum PasscodeType {
  oneTime(1),       // Valid once within 6 hours after start time
  permanent(2),     // Valid forever (must use within 24h of creation)
  timed(3),         // Valid during specific period (must use within 24h)
  delete(4),        // Deletes all used passcodes when entered on lock
  weekendCyclic(5), // Recurring on weekends
  dailyCyclic(6),   // Recurring daily
  mondayCyclic(7),  // Recurring on Monday
  tuesdayCyclic(8), // Recurring on Tuesday
  wednesdayCyclic(9),  // Recurring on Wednesday
  thursdayCyclic(10),  // Recurring on Thursday
  fridayCyclic(11),    // Recurring on Friday
  saturdayCyclic(12),  // Recurring on Saturday
  sundayCyclic(13),    // Recurring on Sunday
  workdayCyclic(14);   // Recurring on workdays (Mon-Fri)

  final int value;
  const PasscodeType(this.value);
}

class TTLockWebhookEvent {
  final String lockId;
  final TTLockWebhookEventType eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? eventData;
  final int? batteryLevel;
  final String? accessMethod; // App, Keypad, Fingerprint, Card vb.

  TTLockWebhookEvent({
    required this.lockId,
    required this.eventType,
    required this.timestamp,
    this.eventData,
    this.batteryLevel,
    this.accessMethod,
  });

  factory TTLockWebhookEvent.fromJson(Map<String, dynamic> json) {
    return TTLockWebhookEvent(
      lockId: json['lockId']?.toString() ?? '',
      eventType: ApiService._parseTTLockEventTypeLocal(json['eventType']?.toString() ?? ''),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['date'] as int?) ?? DateTime.now().millisecondsSinceEpoch
      ),
      eventData: json['data'] as Map<String, dynamic>?,
      batteryLevel: json['battery'] as int?,
      accessMethod: json['accessMethod'] as String?,
    );
  }
}

class ApiService {


  String _baseUrl = 'https://euapi.ttlock.com';
  final AuthRepository _authRepository;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  ApiService(this._authRepository);

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  String _generateMd5(String input) {
    // TTLock requires lowercase MD5 hash. Note: We don't trim() here because
    // spaces can be part of a valid password.
    return md5.convert(utf8.encode(input)).toString().toLowerCase();
  }

  /// Initialize tokens from persistent storage
  Future<void> initializeTokens() async {
    _accessToken = await _authRepository.getAccessToken();
    _refreshToken = await _authRepository.getRefreshToken();
    _tokenExpiry = await _authRepository.getTokenExpiry();
    final savedBaseUrl = await _authRepository.getBaseUrl();
    if (savedBaseUrl != null) {
      _baseUrl = savedBaseUrl;
      print('🌐 Depolanmış bölge sunucusu yüklendi: $_baseUrl');
    }
  }

  /// Clear tokens from memory (used during logout)
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _baseUrl = 'https://euapi.ttlock.com'; // Reset to default
    print('🧹 ApiService in-memory tokens cleared.');
  }

  /// Get access token, using refresh token if available and needed
  Future<bool> getAccessToken({String? username, String? password}) async {
    print('🔑 Access token alma işlemi başladı...');

    // If username is provided, we are performing a manual login.
    // In this case, we MUST ignore the cache/refresh token and request a new one.
    if (username == null) {
      // First, try to load from storage if not in memory
      if (_accessToken == null || _tokenExpiry == null) {
        print('📝 Token bilgilerini yerel depodan yüklüyor...');
        await initializeTokens();
      }

      // If token exists and is valid, no need to fetch a new one
      if (_accessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
        print('✅ Mevcut geçerli token kullanılıyor');
        print('   Token: ${_accessToken!.substring(0, 10)}...');
        return true;
      }

      // Try to refresh token if available
      if (_refreshToken != null && _tokenExpiry != null) {
        print('🔄 Refresh token ile yeni token alınıyor...');
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          print('✅ Token başarıyla yenilendi');
          return true;
        }
        print('❌ Token yenileme başarısız');
      }
    } else {
      print('🆕 Manuel giriş algılandı, cache atlanıyor...');
      clearTokens(); // Log out current state first
    }


    // Otherwise, get new token with username/password
    print('🆕 Yeni access token isteniyor...');
    final success = await _requestNewAccessToken(
      username: username ?? ApiConfig.username,
      password: password ?? ApiConfig.password,
    );

    if (success) {
      print('✅ Yeni token başarıyla alındı');
    } else {
      print('❌ Yeni token alınamadı');
    }

    return success;
  }

  // --- FINGERPRINT MANAGEMENT ---

  /// Add a fingerprint to the cloud after adding it via APP SDK
  Future<Map<String, dynamic>> addFingerprint({
    required int lockId,
    required String fingerprintNumber,
    required int fingerprintType, // 1-normal, 4-recurring
    String? fingerprintName,
    int? startDate, // timestamp in millisecond
    int? endDate, // timestamp in millisecond
    List<Map<String, dynamic>>? cyclicConfig,
  }) async {
    print('👆 Parmak izi buluta ekleniyor: $fingerprintNumber');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/fingerprint/add');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId.toString(),
      'fingerprintNumber': fingerprintNumber,
      'fingerprintType': fingerprintType.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (fingerprintName != null) {
      body['fingerprintName'] = fingerprintName;
    }
    if (startDate != null) {
      body['startDate'] = startDate.toString();
    }
    if (endDate != null) {
      body['endDate'] = endDate.toString();
    }
    if (cyclicConfig != null) {
      body['cyclicConfig'] = jsonEncode(cyclicConfig);
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData.containsKey('fingerprintId')) {
      print('✅ Parmak izi başarıyla eklendi: ${responseData['fingerprintId']}');
      return responseData;
    } else {
      print('❌ Parmak izi ekleme hatası: ${responseData['errmsg']}');
      throw Exception('Parmak izi eklenemedi: ${responseData['errmsg']}');
    }
  }

  /// Get the fingerprint list of a lock
  Future<Map<String, dynamic>> getFingerprintList({
    required int lockId,
    int pageNo = 1,
    int pageSize = 20,
    String? searchStr,
    int orderBy = 1, // 0-by name, 1-reverse order by time, 2-reverse order by name
  }) async {
    print('📋 Parmak izi listesi çekiliyor: $lockId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/fingerprint/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId.toString(),
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
      if (searchStr != null) 'searchStr': searchStr,
      'orderBy': orderBy.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        throw Exception('Parmak izi listesi alınamadı: ${responseData['errmsg']}');
      }
      return responseData;
    } else {
      throw Exception('Parmak izi listesi alınamadı: HTTP ${response.statusCode}');
    }
  }

  Future<void> changeFingerprintPeriod({
    required int lockId,
    required int fingerprintId,
    required int startDate,
    required int endDate,
    int changeType = 1,
  }) async {
    print('🔄 Parmak izi geçerlilik süresi değiştiriliyor: $fingerprintId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/fingerprint/changePeriod');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId.toString(),
      'fingerprintId': fingerprintId.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'changeType': changeType.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] != 0 && responseData['errcode'] != null) {
      throw Exception(
          'Parmak izi geçerlilik süresi değiştirilemedi: ${responseData['errmsg']}');
    }
    print('✅ Parmak izi geçerlilik süresi değiştirildi');
  }

  Future<void> clearAllFingerprints(int lockId) async {
    print('🗑️ Tüm parmak izleri siliniyor');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/fingerprint/clear');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] != 0 && responseData['errcode'] != null) {
      throw Exception('Tüm parmak izleri silinemedi: ${responseData['errmsg']}');
    }
    print('✅ Tüm parmak izleri silindi');
  }

  Future<void> renameFingerprint({
    required int lockId,
    required int fingerprintId,
    required String fingerprintName,
  }) async {
    print('✏️ Parmak izi yeniden adlandırılıyor: $fingerprintId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/fingerprint/rename');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId.toString(),
      'fingerprintId': fingerprintId.toString(),
      'fingerprintName': fingerprintName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] != 0 && responseData['errcode'] != null) {
      throw Exception(
          'Parmak izi yeniden adlandırılamadı: ${responseData['errmsg']}');
    }
    print('✅ Parmak izi yeniden adlandırıldı');
  }



  /// Get user's key list (both owned and shared locks)
  Future<List<Map<String, dynamic>>> getKeyList({
    int pageNo = 1,
    int pageSize = 100,
    String? lockAlias,
    int? groupId,
  }) async {
    print('🔑 TTLock key listesi çekme işlemi başladı...');

    // Ensure we have a valid token
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    // TTLock API endpoint: /v3/key/list
    final url = Uri.parse('$_baseUrl/v3/key/list');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (lockAlias != null) {
      body['lockAlias'] = lockAlias;
    }
    
    if (groupId != null) {
      body['groupId'] = groupId.toString();
    }

    print('📡 Key list API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Key list API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Key List API Full Response: $responseData');

      // Check for error in response body
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Key List API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Key List API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData['list'] != null) {
        final List<dynamic> keysFromApi = responseData['list'];
        print('✅ Successfully fetched ${keysFromApi.length} keys from TTLock API.');

        // Debug: Her key'in detaylarını logla
        for (var i = 0; i < keysFromApi.length; i++) {
          final key = keysFromApi[i];
          print('  🔑 Key ${i + 1}: ID=${key['keyId']}, LockID=${key['lockId']}, Name=${key['lockName'] ?? key['lockAlias'] ?? key['lockNickName'] ?? key['name'] ?? 'Unknown'}, Status=${key['keyStatus']}');
          print('     🔍 API Fields: lockName=${key['lockName']}, lockAlias=${key['lockAlias']}, lockNickName=${key['lockNickName']}, name=${key['name']}');
          print('     📋 Raw key data: ${key.keys.join(', ')}'); // Tüm alanları listele
        }

        // Map to lock format for UI compatibility
        final locks = keysFromApi.map((key) {
          final lockId = key['lockId']?.toString() ?? '';
          final keyId = key['keyId']?.toString() ?? '';
          
          // TTLock Cloud API'de lockAlias orijinal adı temsil eder.
          // Eğer lockAlias yoksa lockName, o da yoksa diğer alanları kullan.
          final lockAlias = key['lockAlias'] ?? key['lockName'] ?? key['lockNickName'] ?? key['name'] ?? 'TTLock Kilidi';
          
          final keyStatus = key['keyStatus']; // Keep raw value
          final electricQuantity = key['electricQuantity'] ?? key['battery'] ?? 0;
          final userType = key['userType']; // "110301"-admin, "110302"-common

          // Determine if this is a shared key
          // Logic update: Check userType or keyStatus if available
          // userType "110302" is common user (likely shared)
          // keyStatus "110405" or similar might mean something else
          // For backwards compatibility, we try to interpret keyStatus as int if possible, 
          // but relying on userType "110302" for shared status is safer if available.
          
          bool isShared = false;
          if (userType != null) {
             isShared = userType.toString() == '110302';
          } else if (keyStatus is int) {
             isShared = keyStatus == 2 || keyStatus == 3;
          }

          return {
            'lockId': lockId,
            'keyId': keyId,
            'name': lockAlias, // Orijinal ad
            'lockData': key['lockData'] ?? '',
            'lockMac': key['lockMac'] ?? '',
            'battery': electricQuantity,
            'keyStatus': keyStatus,
            'userType': userType,
            'source': isShared ? 'ttlock_shared' : 'ttlock',
            'shared': isShared,
            // Orijinal alanları da sakla (lazım olursa)
            'lockAlias': key['lockAlias'],
            'lockName': key['lockName'],
          };
        }).toList();

        print('🎯 Dönüştürülen kilit sayısı: ${locks.length}');
        return locks;
      } else {
        print('⚠️  API response does not contain a key list.');
        return [];
      }
    } else {
      print('❌ Failed to get key list: ${response.statusCode}');
      print('Response: ${response.body}');
      throw Exception('Failed to get key list from TTLock API');
    }
  }

  /// Get one ekey
  Future<Map<String, dynamic>> getEKey({
    required int lockId,
  }) async {
    print('🔑 Tekil e-key çekiliyor: $lockId');

    // Ensure we have a valid token
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/key/get').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken,
      'lockId': lockId.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Get eKey API çağrısı: $url');

    final response = await http.get(url);

    print('📨 Get eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Get eKey API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Get eKey API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Get eKey API Error ${responseData['errcode']}: $errorMsg');
      }

      // Successful response returns the key object directly
      return responseData;
    } else {
      print('❌ Failed to get eKey: ${response.statusCode}');
      throw Exception('Failed to get eKey from TTLock API');
    }
  }

  /// Get the open state of a lock
  /// Returns 0-locked, 1-unlocked, 2-unknown
  Future<int> queryLockOpenState({
    required String lockId,
  }) async {
    print('🔍 Kilit açık durumu sorgulanıyor: $lockId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/queryOpenState').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Query Lock Open State API çağrısı: $url');

    final response = await http.get(url);

    print('📨 Query Lock Open State API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Query Lock Open State API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Query Lock Open State API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Query Lock Open State API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData.containsKey('state')) {
        print('✅ Kilit durumu alındı: ${responseData['state']}');
        return responseData['state'] as int;
      } else {
        print('⚠️ API response does not contain lock state.');
        throw Exception('API response does not contain lock state.');
      }
    } else {
      print('❌ Failed to get lock open state: ${response.statusCode}');
      throw Exception('Failed to get lock open state from TTLock API');
    }
  }

  /// Get lock time (timestamp in millisecond)
  Future<int> queryLockTime({
    required String lockId,
  }) async {
    print('⏰ Kilit zamanı sorgulanıyor: $lockId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/queryDate').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Query Lock Time API çağrısı: $url');

    final response = await http.get(url);

    print('📨 Query Lock Time API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Query Lock Time API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Query Lock Time API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Query Lock Time API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData.containsKey('date')) {
        print('✅ Kilit zamanı alındı: ${responseData['date']}');
        return responseData['date'] as int;
      } else {
        print('⚠️ API response does not contain lock time.');
        throw Exception('API response does not contain lock time.');
      }
    } else {
      print('❌ Failed to get lock time: ${response.statusCode}');
      throw Exception('Failed to get lock time from TTLock API');
    }
  }

  /// Adjust lock time
  /// Returns the lock time after adjusting (timestamp in millisecond)
  Future<int> updateLockTime({
    required String lockId,
    required int newDate, // Timestamp in millisecond
  }) async {
    print('🔄 Kilit zamanı ayarlanıyor: $lockId, yeni zaman: $newDate');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/updateDate');

    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': newDate.toString(), // Use newDate for the request body
    };

    print('📡 Update Lock Time API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Update Lock Time API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Update Lock Time API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Update Lock Time API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Update Lock Time API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData.containsKey('date')) {
        print('✅ Kilit zamanı başarıyla ayarlandı: ${responseData['date']}');
        return responseData['date'] as int;
      } else {
        print('⚠️ API response does not contain adjusted lock time.');
        throw Exception('API response does not contain adjusted lock time.');
      }
    } else {
      print('❌ Failed to adjust lock time: ${response.statusCode}');
      throw Exception('Failed to adjust lock time from TTLock API');
    }
  }

  /// Get lock battery (percentage)
  Future<int> queryLockBattery({
    required String lockId,
  }) async {
    print('🔋 Kilit pil seviyesi sorgulanıyor: $lockId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/queryElectricQuantity').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Query Lock Battery API çağrısı: $url');

    final response = await http.get(url);

    print('📨 Query Lock Battery API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Query Lock Battery API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Query Lock Battery API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Query Lock Battery API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData.containsKey('electricQuantity')) {
        print('✅ Kilit pil seviyesi alındı: ${responseData['electricQuantity']}%');
        return responseData['electricQuantity'] as int;
      } else {
        print('⚠️ API response does not contain lock battery quantity.');
        throw Exception('API response does not contain lock battery quantity.');
      }
    } else {
      print('❌ Failed to get lock battery: ${response.statusCode}');
      throw Exception('Failed to get lock battery from TTLock API');
    }
  }

  /// Get passwords for a specific lock
  Future<List<Map<String, dynamic>>> getLockPasswords({
    required String accessToken,
    required String lockId,
  }) async {
    print('🔑 Kilit şifreleri çekiliyor: $lockId');
    final url = Uri.parse('$_baseUrl/v3/lock/listKeyboardPwd').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'pageNo': '1',
      'pageSize': '50',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to get lock passwords');
    }
  }

  /// Get access records for a specific lock
  Future<List<Map<String, dynamic>>> getLockRecords({
    required String accessToken,
    required String lockId,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    print('📋 Kilit kayıtları çekiliyor: $lockId');
    final url = Uri.parse('$_baseUrl/v3/lockRecord/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('📝 Lock Records Response: $responseData');
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        print('⚠️ Lock Records Error or Empty: errcode=${responseData['errcode']}, errmsg=${responseData['errmsg']}');
        return [];
      }
    } else {
          print('❌ Lock Records HTTP Error: ${response.statusCode}');
          throw Exception('Failed to get lock records: ${response.statusCode}');
    }
  }

  /// Get lock cards (RFID cards)
  Future<List<Map<String, dynamic>>> getLockCards({
    required String accessToken,
    required String lockId,
  }) async {
    print('💳 Kilit kartları çekiliyor: $lockId');
    final url = Uri.parse('$_baseUrl/v3/lock/listICCard').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'pageNo': '1',
      'pageSize': '50',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to get lock cards');
    }
  }

  /// Get a list of Identity Cards (IC Cards) for a specific lock from the cloud API.
  Future<List<Map<String, dynamic>>> listIdentityCards({
    required String lockId,
    int pageNo = 1,
    int pageSize = 20, // Max 200 as per documentation
    int orderBy = 1, // 0-by name, 1-reverse order by time, 2-reverse order by name
    String? searchStr,
  }) async {
    print('💳 Kimlik Kartları listesi çekiliyor: $lockId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final Map<String, dynamic> queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'orderBy': orderBy.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (searchStr != null && searchStr.isNotEmpty) {
      queryParams['searchStr'] = searchStr;
    }

    final url = Uri.parse('$_baseUrl/v3/identityCard/list').replace(queryParameters: queryParams.cast<String, String>());

    print('📡 List Identity Cards API çağrısı: $url');

    final response = await http.get(url);

    print('📨 List Identity Cards API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Kimlik Kartları listeleme API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Kimlik Kartları listelenemedi: ${responseData['errmsg']}');
      }

      if (responseData['list'] != null) {
        print('✅ ${responseData['list'].length} Kimlik Kartı bulundu');
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kimlik Kartları listelenemedi: HTTP ${response.statusCode}');
    }
  }

  /// Get lock fingerprints
  Future<List<Map<String, dynamic>>> getLockFingerprints({
    required String accessToken,
    required String lockId,
  }) async {
    print('👆 Kilit parmak izleri çekiliyor: $lockId');
    final url = Uri.parse('$_baseUrl/v3/lock/listFingerprint').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'pageNo': '1',
      'pageSize': '50',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to get lock fingerprints');
    }
  }

  /// Get gateway list for remote control
  Future<List<Map<String, dynamic>>> getGatewayList({
    int pageNo = 1,
    int pageSize = 50,
    int orderBy = 0, // 0-by name, 1-reverse order by time, 2-reverse order by name
  }) async {
    print('📡 Gateway listesi çekiliyor');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final Map<String, dynamic> queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'orderBy': orderBy.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final url = Uri.parse('$_baseUrl/v3/gateway/list').replace(queryParameters: queryParams.cast<String, String>());

    print('📡 Gateway list API çağrısı: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to get gateway list');
    }
  }

  /// Send remote unlock command via TTLock API
  Future<Map<String, dynamic>> sendRemoteUnlock({
    required String lockId,
  }) async {
    print('🔓 Uzaktan açma komutu gönderiliyor: $lockId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    // TTLock API endpoint: /v3/lock/unlock
    final url = Uri.parse('$_baseUrl/v3/lock/unlock');

    // Parametreleri body olarak gönder (application/x-www-form-urlencoded)
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Remote unlock API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Remote unlock başarılı');
        return responseData;
      } else {
        print('❌ Remote unlock API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Remote unlock failed: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  /// Initialize (Register) lock on TTLock cloud
  Future<Map<String, dynamic>> initializeLock({
    required String lockData,
    String? lockAlias,
    int? groupId,
    int? nbInitSuccess, // 1-yes, 0-no (Only for NB-IoT locks)
  }) async {
    print('🏗️ Kilidi TTLock bulutuna kaydediyor...');

    // Ensure we have a valid token
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/initialize');

    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockData': lockData,
      'lockAlias': lockAlias ?? 'TTLock Kilidi',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (groupId != null) {
      body['groupId'] = groupId.toString();
    }
    
    if (nbInitSuccess != null) {
      body['nbInitSuccess'] = nbInitSuccess.toString();
    }

    print('📡 Lock init API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Lock init API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Check for both errcode (standard) or direct lockId return
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
           print('❌ Kilit kaydı API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Lock init failed: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        }
        
        // Successful response should contain lockId
        if (responseData.containsKey('lockId')) {
           print('✅ Kilit başarıyla kaydedildi: ${responseData['lockId']}');
           return responseData;
        } else if ((responseData['errcode'] == 0 || responseData['errcode'] == null) || responseData.containsKey('lockId')) {
           // Some APIs might return just success without lockId if already handled? 
           // But spec says it returns lockId. 
           return responseData;
        }
      }
      return responseData;
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  /// Connect to a gateway
  Future<Map<String, dynamic>> connectGateway({
    required String accessToken,
    required String gatewayId,
  }) async {
    print('🔗 Gateway\'e bağlanılıyor: $gatewayId');

    final url = Uri.parse('$_baseUrl/v3/gateway/connect').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Gateway bağlantısı başarılı: $gatewayId');
        return responseData;
      } else {
        throw Exception('Gateway bağlantısı başarısız: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('Gateway bağlantısı başarısız: HTTP ${response.statusCode}');
    }
  }

  /// Disconnect from a gateway
  Future<Map<String, dynamic>> disconnectGateway({
    required String accessToken,
    required String gatewayId,
  }) async {
    print('🔌 Gateway bağlantısı kesiliyor: $gatewayId');

    final url = Uri.parse('$_baseUrl/v3/gateway/disconnect').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Gateway bağlantısı kesildi: $gatewayId');
        return responseData;
      } else {
        throw Exception('Gateway bağlantı kesme başarısız: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('Gateway bağlantı kesme başarısız: HTTP ${response.statusCode}');
    }
  }

  /// Get gateway details
  Future<Map<String, dynamic>> getGatewayDetail({
    required String gatewayId,
  }) async {
    print('📋 Gateway detayları alınıyor: $gatewayId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/detail').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Gateway detayları API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Gateway detayları alınamadı: ${responseData['errmsg']}');
      }
      print('✅ Gateway detayları alındı: $gatewayId');
      return responseData;
    } else {
      throw Exception('Gateway detayları alınamadı: HTTP ${response.statusCode}');
    }
  }

  /// Update gateway settings
  Future<Map<String, dynamic>> updateGateway({
    required String accessToken,
    required String gatewayId,
    String? gatewayName,
    String? networkName,
    String? networkPassword,
  }) async {
    print('⚙️ Gateway ayarları güncelleniyor: $gatewayId');

    final url = Uri.parse('$_baseUrl/v3/gateway/update').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'gatewayId': gatewayId,
      if (gatewayName != null) 'gatewayName': gatewayName,
      if (networkName != null) 'networkName': networkName,
      if (networkPassword != null) 'networkPassword': networkPassword,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Gateway ayarları güncellendi: $gatewayId');
        return responseData;
      } else {
        throw Exception('Gateway güncelleme başarısız: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('Gateway güncelleme başarısız: HTTP ${response.statusCode}');
    }
  }

  /// Get the gateway list of a lock
  Future<List<Map<String, dynamic>>> getGatewaysByLock({
    required String lockId,
  }) async {
    print('📡 Bir kilide bağlı gateway listesi çekiliyor: lockId=$lockId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/listByLock').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Get Gateways by Lock API çağrısı: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData.containsKey('errcode') && responseData['errcode'] != 0)) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Get Gateways by Lock API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Get Gateways by Lock API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to get gateways by lock');
    }
  }

  /// Get locks connected to a gateway
  Future<List<Map<String, dynamic>>> getGatewayLocks({
    required String gatewayId,
  }) async {
    print('🔗 Gateway\'e bağlı kilitler alınıyor: $gatewayId');
    
    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/listLock').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData.containsKey('errcode') && responseData['errcode'] != 0)) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Get Gateway Locks API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Get Gateway Locks API Error ${responseData['errcode']}: $errorMsg');
      }
      
      if (responseData['list'] != null) {
        print('✅ Gateway kilitleri alındı: ${responseData['list'].length} kilit');
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Gateway kilitleri alınamadı: HTTP ${response.statusCode}');
    }
  }

  /// Get e-keys (electronic keys) for a lock
  Future<List<Map<String, dynamic>>> getLockEKeys({
    required String accessToken,
    required String lockId,
    int pageNo = 1,
    int pageSize = 200,
    String? searchStr,
    int? keyRight, // 0: No, 1: Yes
    int? orderBy, // 0: by name, 1: reverse by time, 2: reverse by name
  }) async {
    print('🔑 Kilit için e-key listesi çekiliyor: $lockId');
    
    final Map<String, dynamic> queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (searchStr != null && searchStr.isNotEmpty) {
      queryParams['searchStr'] = searchStr;
    }

    if (keyRight != null) {
      queryParams['keyRight'] = keyRight.toString();
    }

    if (orderBy != null) {
      queryParams['orderBy'] = orderBy.toString();
    }

    // TTLock API endpoint: /v3/lock/listKey
    final url = Uri.parse('$_baseUrl/v3/lock/listKey').replace(queryParameters: queryParams);

    print('📡 Lock Key List API çağrısı: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Lock Key List Response: $responseData');
      
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        print('⚠️ Lock Key List Error: ${responseData['errmsg']}');
        return [];
      }
    } else {
      print('❌ Lock Key List HTTP Error: ${response.statusCode}');
      throw Exception('Failed to get lock e-keys');
    }
  }

  /// Delete a specific e-key
  Future<Map<String, dynamic>> deleteEKey({
    required String accessToken,
    required String keyId,
  }) async {
    print('🗑️ E-key siliniyor: $keyId');
    
    // TTLock API endpoint: /v3/key/delete
    final url = Uri.parse('$_baseUrl/v3/key/delete');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Delete eKey API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Delete eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Delete eKey Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key başarıyla silindi: $keyId');
        return responseData;
      } else {
        print('❌ E-key silme API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to delete e-key: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to delete e-key: HTTP ${response.statusCode}');
    }
  }

  /// Freeze the ekey
  Future<Map<String, dynamic>> freezeEKey({
    required String accessToken,
    required String keyId,
  }) async {
    print('❄️ E-key donduruluyor: $keyId');
    
    // TTLock API endpoint: /v3/key/freeze
    final url = Uri.parse('$_baseUrl/v3/key/freeze');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Freeze eKey API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Freeze eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Freeze eKey Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key başarıyla donduruldu: $keyId');
        return responseData;
      } else {
        print('❌ E-key dondurma API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to freeze e-key: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to freeze e-key: HTTP ${response.statusCode}');
    }
  }

  /// Unfreeze the ekey
  Future<Map<String, dynamic>> unfreezeEKey({
    required String accessToken,
    required String keyId,
  }) async {
    print('🔥 E-key dondurması kaldırılıyor (unfreeze): $keyId');
    
    // TTLock API endpoint: /v3/key/unfreeze
    final url = Uri.parse('$_baseUrl/v3/key/unfreeze');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Unfreeze eKey API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Unfreeze eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Unfreeze eKey Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key başarıyla dondurmadan kurtarıldı: $keyId');
        return responseData;
      } else {
        print('❌ E-key unfreeze API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to unfreeze e-key: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to unfreeze e-key: HTTP ${response.statusCode}');
    }
  }

  /// Modify ekey (rename or change remote enable)
  Future<Map<String, dynamic>> updateEKey({
    required String accessToken,
    required String keyId,
    String? keyName,
    int? remoteEnable, // 1-yes, 2-no
  }) async {
    print('✏️ E-key güncelleniyor: $keyId');
    
    // TTLock API endpoint: /v3/key/update
    final url = Uri.parse('$_baseUrl/v3/key/update');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (keyName != null && keyName.isNotEmpty) {
      body['keyName'] = keyName;
    }

    if (remoteEnable != null) {
      body['remoteEnable'] = remoteEnable.toString();
    }

    print('📡 Update eKey API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Update eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Update eKey Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key başarıyla güncellendi: $keyId');
        return responseData;
      } else {
        print('❌ E-key güncelleme API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to update e-key: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to update e-key: HTTP ${response.statusCode}');
    }
  }

  /// Change the valid time of the ekey
  Future<Map<String, dynamic>> changeEKeyPeriod({
    required String accessToken,
    required String keyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    print('🕒 E-key süresi değiştiriliyor: $keyId');
    
    // TTLock API endpoint: /v3/key/changePeriod
    final url = Uri.parse('$_baseUrl/v3/key/changePeriod');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'startDate': startDate.millisecondsSinceEpoch.toString(),
      'endDate': endDate.millisecondsSinceEpoch.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Change eKey Period API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Change eKey Period API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Change eKey Period Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key süresi başarıyla güncellendi: $keyId');
        return responseData;
      } else {
        print('❌ E-key süre güncelleme API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to change e-key period: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to change e-key period: HTTP ${response.statusCode}');
    }
  }

  /// Authorize ekey (Grant management rights)
  Future<Map<String, dynamic>> authorizeEKey({
    required String accessToken,
    required String lockId,
    required String keyId,
  }) async {
    print('👮 E-key yetkilendiriliyor: $keyId');
    
    // TTLock API endpoint: /v3/key/authorize
    final url = Uri.parse('$_baseUrl/v3/key/authorize');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Authorize eKey API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Authorize eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Authorize eKey Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key başarıyla yetkilendirildi: $keyId');
        return responseData;
      } else {
        print('❌ E-key yetkilendirme API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to authorize e-key: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to authorize e-key: HTTP ${response.statusCode}');
    }
  }

  /// Cancel key authorization
  Future<Map<String, dynamic>> unauthorizeEKey({
    required String accessToken,
    required String lockId,
    required String keyId,
  }) async {
    print('🚫 E-key yetkisi iptal ediliyor: $keyId');
    
    // TTLock API endpoint: /v3/key/unauthorize
    final url = Uri.parse('$_baseUrl/v3/key/unauthorize');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Unauthorize eKey API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Unauthorize eKey API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Unauthorize eKey Response: $responseData');
      
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key yetkisi başarıyla iptal edildi: $keyId');
        return responseData;
      } else {
        print('❌ E-key yetki iptali API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Failed to unauthorize e-key: ${responseData['errmsg']}');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to unauthorize e-key: HTTP ${response.statusCode}');
    }
  }

  /// Get the eKey unlocking link
  Future<Map<String, dynamic>> getUnlockLink({
    required String accessToken,
    required String keyId,
  }) async {
    print('🔗 E-key kilit açma linki alınıyor: $keyId');
    
    // TTLock API endpoint: /v3/key/getUnlockLink
    final url = Uri.parse('$_baseUrl/v3/key/getUnlockLink');

    // Make parameters part of the body for POST request
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Get Unlock Link API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Get Unlock Link API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 Get Unlock Link Response: $responseData');
      
      if (responseData.containsKey('link') && responseData['link'] != null) {
        print('✅ Link başarıyla alındı: ${responseData['link']}');
        return responseData;
      } else if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
         print('❌ Link alma API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
         throw Exception('Failed to get unlock link: ${responseData['errmsg']}');
      } else {
        // Fallback for success case where maybe errcode is 0?
        return responseData;
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Failed to get unlock link: HTTP ${response.statusCode}');
    }
  }

  /// Send eKey (Share lock)
  Future<Map<String, dynamic>> sendEKey({
    required String accessToken,
    required String lockId,
    required String receiverUsername, // Email or phone
    required String keyName, // Required by API
    required DateTime startDate, // Required by API
    required DateTime endDate, // Required by API
    int keyRight = 0, // 0: Normal user (default), 1: Admin
    String? remarks,
    int? remoteEnable, // 1-yes, 2-no
    int createUser = 2, // 1-yes, 2-no (default)
  }) async {
    print('🔗 E-key gönderiliyor: $lockId -> $receiverUsername');

    // TTLock API endpoint: /v3/key/send
    final url = Uri.parse('$_baseUrl/v3/key/send');

    // Parametreleri body olarak gönder (application/x-www-form-urlencoded)
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'receiverUsername': receiverUsername,
      'keyName': keyName,
      'startDate': startDate.millisecondsSinceEpoch.toString(),
      'endDate': endDate.millisecondsSinceEpoch.toString(),
      'createUser': createUser.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (keyRight != 0) {
      body['keyRight'] = keyRight.toString();
    }
    
    if (remarks != null && remarks.isNotEmpty) {
      body['remarks'] = remarks;
    }

    if (remoteEnable != null) {
      body['remoteEnable'] = remoteEnable.toString();
    }

    print('📡 Send eKey API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Send eKey API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ E-key başarıyla gönderildi: $lockId');
        return responseData;
      } else {
        print('❌ E-key gönderme API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('E-key gönderme başarısız: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('E-key gönderm başarısız: HTTP ${response.statusCode}');
    }
  }

  /// Cancel lock sharing
  Future<Map<String, dynamic>> cancelLockShare({
    required String accessToken,
    required String lockId,
    required String username,
  }) async {
    print('🚫 Kilit paylaşımı iptal ediliyor: $lockId <- $username');

    final url = Uri.parse('$_baseUrl/v3/lock/cancelShare').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'username': username,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Kilit paylaşımı iptal edildi: $lockId');
        return responseData;
      } else {
        throw Exception('Paylaşım iptali başarısız: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('Paylaşım iptali başarısız: HTTP ${response.statusCode}');
    }
  }



  // --- ŞİFRE, KART VE PARMAK İZİ YÖNETİMİ ---

  /// Add a custom passcode to a lock
  Future<Map<String, dynamic>> addPasscode({
    required String lockId,
    required String passcodeName,
    required String passcode,
    required int startDate, // timestamp ms
    required int endDate,   // timestamp ms
  }) async {
    print('🔑 Yeni şifre ekleniyor: $passcodeName');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/keyboardPwd/add');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'keyboardPwd': passcode,
      'keyboardPwdName': passcodeName,
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Şifre başarıyla eklendi');
      return responseData;
    } else {
      print('❌ Şifre ekleme hatası: ${responseData['errmsg']}');
      throw Exception('Şifre eklenemedi: ${responseData['errmsg']}');
    }
  }

  /// Delete a passcode
  Future<void> deletePasscode({
    required String lockId,
    required int keyboardPwdId,
  }) async {
    print('🗑️ Şifre siliniyor: $keyboardPwdId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/keyboardPwd/delete');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'keyboardPwdId': keyboardPwdId.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] != 0 && responseData['errcode'] != null) {
      throw Exception('Şifre silinemedi: ${responseData['errmsg']}');
    }
    print('✅ Şifre silindi');
  }

  /// Get a random passcode from TTLock cloud API
  /// The passcode is generated by the server based on lock's internal algorithm
  /// 
  /// [lockId] The lock ID
  /// [passcodeType] Type of passcode to generate (see PasscodeType enum)
  /// [startDate] Start time in milliseconds (required for all types)
  /// [endDate] End time in milliseconds (required for timed types)
  /// [passcodeName] Optional name for the passcode
  Future<Map<String, dynamic>> getRandomPasscode({
    required String lockId,
    required PasscodeType passcodeType,
    required int startDate,
    int? endDate,
    String? passcodeName,
  }) async {
    print('🎲 Rastgele şifre oluşturuluyor: tip=${passcodeType.name}');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/keyboardPwd/get');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'keyboardPwdType': passcodeType.value.toString(),
      'startDate': startDate.toString(),
      if (endDate != null) 'endDate': endDate.toString(),
      if (passcodeName != null) 'keyboardPwdName': passcodeName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Rastgele şifre oluşturuldu: ${responseData['keyboardPwd']}');
      return responseData;
    } else {
      print('❌ Rastgele şifre oluşturulamadı: ${responseData['errmsg']}');
      throw Exception('Rastgele şifre oluşturulamadı: ${responseData['errmsg']}');
    }
  }

  /// Get all passcodes for a lock from cloud
  /// Returns list of passcode records with type, validity, status
  Future<List<Map<String, dynamic>>> getPasscodeList({
    required String lockId,
    int pageNo = 1,
    int pageSize = 100,
  }) async {
    print('📋 Şifre listesi çekiliyor: $lockId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/keyboardPwd/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
        print('✅ ${responseData['list'].length} şifre bulundu');
        return (responseData['list'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Şifre listesi alınamadı: HTTP ${response.statusCode}');
    }
  }

  /// Modify a passcode remotely via gateway
  /// changeType=2 means modification via gateway (requires lock to be connected to gateway)
  Future<void> modifyPasscodeViaGateway({
    required String lockId,
    required int keyboardPwdId,
    String? newPasscode,
    int? startDate,
    int? endDate,
  }) async {
    print('🔄 Şifre gateway üzerinden değiştiriliyor: $keyboardPwdId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/keyboardPwd/change');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'keyboardPwdId': keyboardPwdId.toString(),
      'changeType': '2', // 2 = via gateway
      if (newPasscode != null) 'newKeyboardPwd': newPasscode,
      if (startDate != null) 'startDate': startDate.toString(),
      if (endDate != null) 'endDate': endDate.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Şifre gateway üzerinden değiştirildi');
    } else {
      print('❌ Şifre değiştirilemedi: ${responseData['errmsg']}');
      throw Exception('Şifre değiştirilemedi: ${responseData['errmsg']}');
    }
  }


  /// Add IC Card remotely via gateway
  /// Requires lock to be connected to a gateway
  Future<Map<String, dynamic>> addICCardViaGateway({
    required String lockId,
    required String cardNumber,
    required int startDate,
    required int endDate,
    String? cardName,
  }) async {
    print('💳 IC Kart gateway üzerinden ekleniyor: $cardNumber');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/lock/addICCard');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardNumber': cardNumber,
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'addType': '2', // 2 = via gateway
      if (cardName != null) 'cardName': cardName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ IC Kart gateway üzerinden eklendi');
      return responseData;
    } else {
      print('❌ IC Kart eklenemedi: ${responseData['errmsg']}');
      throw Exception('IC Kart eklenemedi: ${responseData['errmsg']}');
    }
  }

  /// Add an Identity Card (IC Card) to a lock via the cloud API.
  /// This method uses the `addForReversedCardNumber` endpoint, which is suitable
  /// for cards where the number might be reversed depending on the card reader.
  /// The `addType` is set to 2, indicating addition via gateway or WiFi lock.
  Future<Map<String, dynamic>> addIdentityCard({
    required String lockId,
    required String cardNumber,
    required int startDate,
    required int endDate,
    String? cardName,
    int cardType = 1, // Default to normal card
  }) async {
    print('💳 Kimlik Kartı cloud üzerinden ekleniyor: $cardNumber');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/identityCard/addForReversedCardNumber');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardNumber': cardNumber,
      'cardName': cardName ?? 'New Card',
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'cardType': cardType.toString(),
      'addType': '2', // 2 = via gateway or WiFi lock
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Add Identity Card API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Add Identity Card API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Kimlik Kartı ekleme API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Kimlik Kartı eklenemedi: ${responseData['errmsg']}');
      }
      print('✅ Kimlik Kartı başarıyla eklendi');
      return responseData;
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kimlik Kartı eklenemedi: HTTP ${response.statusCode}');
    }
  }

  /// Delete an Identity Card (IC Card) from a lock via the cloud API.
  /// The `deleteType` is set to 2, indicating deletion via gateway or WiFi lock.
  Future<void> deleteIdentityCard({
    required String lockId,
    required int cardId,
  }) async {
    print('🗑️ Kimlik Kartı cloud üzerinden siliniyor: $cardId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/identityCard/delete');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardId': cardId.toString(),
      'deleteType': '2', // 2 = via gateway or WiFi lock
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Delete Identity Card API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Delete Identity Card API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Kimlik Kartı silme API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Kimlik Kartı silinemedi: ${responseData['errmsg']}');
      }
      print('✅ Kimlik Kartı başarıyla silindi');
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kimlik Kartı silinemedi: HTTP ${response.statusCode}');
    }
  }

  /// Change the validity period of an Identity Card (IC Card) via the cloud API.
  /// The `changeType` is set to 2, indicating modification via gateway or WiFi lock.
  Future<void> changeIdentityCardPeriod({
    required String lockId,
    required int cardId,
    required int startDate,
    required int endDate,
  }) async {
    print('🕒 Kimlik Kartı periyodu cloud üzerinden değiştiriliyor: $cardId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/identityCard/changePeriod');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardId': cardId.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'changeType': '2', // 2 = via gateway or WiFi lock
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Change Identity Card Period API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Change Identity Card Period API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Kimlik Kartı periyodu değiştirme API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Kimlik Kartı periyodu değiştirilemedi: ${responseData['errmsg']}');
      }
      print('✅ Kimlik Kartı periyodu başarıyla değiştirildi');
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kimlik Kartı periyodu değiştirilemedi: HTTP ${response.statusCode}');
    }
  }

  /// Rename an Identity Card (IC Card) via the cloud API.
  Future<void> renameIdentityCard({
    required String lockId,
    required int cardId,
    required String cardName,
  }) async {
    print('✏️ Kimlik Kartı cloud üzerinden yeniden adlandırılıyor: $cardId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/identityCard/rename');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardId': cardId.toString(),
      'cardName': cardName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Rename Identity Card API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Rename Identity Card API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Kimlik Kartı yeniden adlandırma API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Kimlik Kartı yeniden adlandırılamadı: ${responseData['errmsg']}');
      }
      print('✅ Kimlik Kartı başarıyla yeniden adlandırıldı');
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kimlik Kartı yeniden adlandırılamadı: HTTP ${response.statusCode}');
    }
  }

  /// Clear all Identity Cards (IC Cards) from a lock on the cloud server.
  /// NOTE: As per documentation, you should clear cards from the lock via SDK first.
  /// This API call only syncs the clearance with the server.
  Future<void> clearIdentityCards({
    required String lockId,
  }) async {
    print('🔥 Tüm Kimlik Kartları cloud üzerinden temizleniyor: $lockId');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/identityCard/clear');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Clear Identity Cards API çağrısı: $url');
    print('📝 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Clear Identity Cards API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Kimlik Kartları temizleme API hatası: ${responseData['errcode']} - $errorMsg');
        throw Exception('Kimlik Kartları temizlenemedi: ${responseData['errmsg']}');
      }
      print('✅ Kimlik Kartları başarıyla temizlendi');
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kimlik Kartları temizlenemedi: HTTP ${response.statusCode}');
    }
  }

  /// Modify IC Card validity period via gateway
  Future<void> modifyICCardViaGateway({
    required String lockId,
    required int cardId,
    required int startDate,
    required int endDate,
  }) async {
    print('🔄 IC Kart geçerlilik süresi gateway üzerinden değiştiriliyor: $cardId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/lock/changeICCard');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardId': cardId.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'changeType': '2', // 2 = via gateway
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ IC Kart geçerlilik süresi değiştirildi');
    } else {
      print('❌ IC Kart değiştirilemedi: ${responseData['errmsg']}');
      throw Exception('IC Kart değiştirilemedi: ${responseData['errmsg']}');
    }
  }

  /// Add Fingerprint remotely via gateway
  /// Note: Some locks may not support remote fingerprint adding
  Future<Map<String, dynamic>> addFingerprintViaGateway({
    required String lockId,
    required int startDate,
    required int endDate,
    String? fingerprintName,
  }) async {
    print('👆 Parmak izi gateway üzerinden ekleniyor');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/lock/addFingerprint');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'addType': '2', // 2 = via gateway
      if (fingerprintName != null) 'fingerprintName': fingerprintName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Parmak izi gateway üzerinden eklendi');
      return responseData;
    } else {
      print('❌ Parmak izi eklenemedi: ${responseData['errmsg']}');
      throw Exception('Parmak izi eklenemedi: ${responseData['errmsg']}');
    }
  }

  /// Modify Fingerprint validity period via gateway
  Future<void> modifyFingerprintViaGateway({
    required String lockId,
    required int fingerprintId,
    required int startDate,
    required int endDate,
  }) async {
    print('🔄 Parmak izi geçerlilik süresi gateway üzerinden değiştiriliyor: $fingerprintId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/lock/changeFingerprint');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'fingerprintId': fingerprintId.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'changeType': '2', // 2 = via gateway
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Parmak izi geçerlilik süresi değiştirildi');
    } else {
      print('❌ Parmak izi değiştirilemedi: ${responseData['errmsg']}');
      throw Exception('Parmak izi değiştirilemedi: ${responseData['errmsg']}');
    }
  }

  /// Initialize/Register gateway to cloud
  /// Call this after successfully initializing gateway via SDK
  Future<Map<String, dynamic>> initGateway({
    required String gatewayNetMac,
    required String modelNum,
    required String hardwareRevision,
    required String firmwareRevision,
  }) async {
    print('🌐 Gateway cloud\'a kaydediliyor: $gatewayNetMac');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/gateway/init');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayNetMac': gatewayNetMac,
      'modelNum': modelNum,
      'hardwareRevision': hardwareRevision,
      'firmwareRevision': firmwareRevision,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Gateway cloud\'a kaydedildi: ${responseData['gatewayId']}');
      return responseData;
    } else {
      print('❌ Gateway kaydedilemedi: ${responseData['errmsg']}');
      throw Exception('Gateway kaydedilemedi: ${responseData['errmsg']}');
    }
  }

  /// Delete gateway from cloud
  Future<void> deleteGateway({
    required String gatewayId,
  }) async {
    print('🗑️ Gateway siliniyor: $gatewayId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/gateway/delete');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
      print('✅ Gateway silindi');
    } else {
      print('❌ Gateway silinemedi: ${responseData['errmsg']}');
      throw Exception('Gateway silinemedi: ${responseData['errmsg']}');
    }
  }

  /// Rename gateway
  Future<Map<String, dynamic>> renameGateway({
    required String gatewayId,
    required String gatewayName,
  }) async {
    print('✏️ Gateway yeniden adlandırılıyor: $gatewayId, yeni ad: $gatewayName');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/rename');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'gatewayName': gatewayName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Rename Gateway API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Rename Gateway API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Rename Gateway API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Rename Gateway API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Rename Gateway API Error ${responseData['errcode']}: $errorMsg');
      }

      print('✅ Gateway başarıyla yeniden adlandırıldı');
      return responseData;
    } else {
      print('❌ Failed to rename gateway: ${response.statusCode}');
      throw Exception('Failed to rename gateway from TTLock API');
    }
  }

  /// Transfer gateway to another account
  Future<Map<String, dynamic>> transferGateway({
    required String receiverUsername,
    required List<int> gatewayIdList,
  }) async {
    print('🔄 Gateway transfer ediliyor: alıcı=$receiverUsername, gatewayler=$gatewayIdList');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/transfer');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'receiverUsername': receiverUsername,
      'gatewayIdList': json.encode(gatewayIdList), // Convert list to JSON string
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Transfer Gateway API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Transfer Gateway API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Transfer Gateway API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Transfer Gateway API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Transfer Gateway API Error ${responseData['errcode']}: $errorMsg');
      }

      print('✅ Gateway başarıyla transfer edildi');
      return responseData;
    } else {
      print('❌ Failed to transfer gateway: ${response.statusCode}');
      throw Exception('Failed to transfer gateway from TTLock API');
    }
  }

  /// Query the init status of the gateway
  /// Returns the gatewayId if successfully initialized.
  Future<int> queryGatewayInitStatus({
    required String gatewayNetMac,
  }) async {
    print('🔍 Gateway başlangıç durumu sorgulanıyor: $gatewayNetMac');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/isInitSuccess');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayNetMac': gatewayNetMac,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Query Gateway Init Status API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Query Gateway Init Status API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Query Gateway Init Status API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Query Gateway Init Status API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Query Gateway Init Status API Error ${responseData['errcode']}: $errorMsg');
      }

      if (responseData.containsKey('gatewayId')) {
        print('✅ Gateway başarıyla başlatıldı, ID: ${responseData['gatewayId']}');
        return responseData['gatewayId'] as int;
      } else {
        print('⚠️ API response does not contain gatewayId.');
        throw Exception('API response does not contain gatewayId.');
      }
    } else {
      print('❌ Failed to query gateway init status: ${response.statusCode}');
      throw Exception('Failed to query gateway init status from TTLock API');
    }
  }

  /// Upload the gateway's firmware version info and network name to the cloud server
  Future<Map<String, dynamic>> uploadGatewayDetail({
    required String gatewayId,
    required String modelNum,
    required String hardwareRevision,
    required String firmwareRevision,
    required String networkName,
  }) async {
    print('⬆️ Gateway detayları yükleniyor: $gatewayId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/uploadDetail');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'modelNum': modelNum,
      'hardwareRevision': hardwareRevision,
      'firmwareRevision': firmwareRevision,
      'networkName': networkName,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Upload Gateway Detail API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Upload Gateway Detail API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Upload Gateway Detail API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Upload Gateway Detail API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Upload Gateway Detail API Error ${responseData['errcode']}: $errorMsg');
      }

      print('✅ Gateway detayları başarıyla yüklendi');
      return responseData;
    } else {
      print('❌ Failed to upload gateway detail: ${response.statusCode}');
      throw Exception('Failed to upload gateway detail from TTLock API');
    }
  }

  /// Check if the gateway have a new version of firmware
  Future<Map<String, dynamic>> gatewayUpgradeCheck({
    required String gatewayId,
  }) async {
    print('🔍 Gateway güncellemesi kontrol ediliyor: $gatewayId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/upgradeCheck').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Gateway Upgrade Check API çağrısı: $url');

    final response = await http.get(url);

    print('📨 Gateway Upgrade Check API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Gateway Upgrade Check API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Gateway Upgrade Check API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Gateway Upgrade Check API Error ${responseData['errcode']}: $errorMsg');
      }

      print('✅ Gateway güncelleme kontrolü başarılı');
      return responseData;
    } else {
      print('❌ Failed to check gateway upgrade: ${response.statusCode}');
      throw Exception('Failed to check gateway upgrade from TTLock API');
    }
  }

  /// Set gateway into upgrade mode
  Future<Map<String, dynamic>> setGatewayUpgradeMode({
    required String gatewayId,
  }) async {
    print('🔄 Gateway güncelleme moduna alınıyor: $gatewayId');

    await getAccessToken(); // Ensure we have a valid token

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/gateway/setUpgradeMode');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Set Gateway Upgrade Mode API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Set Gateway Upgrade Mode API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Set Gateway Upgrade Mode API Full Response: $responseData');

      if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
        final errorMsg = responseData['errmsg'] ?? 'Unknown error';
        print('❌ Set Gateway Upgrade Mode API Error: ${responseData['errcode']} - $errorMsg');
        throw Exception('Set Gateway Upgrade Mode API Error ${responseData['errcode']}: $errorMsg');
      }

      print('✅ Gateway başarıyla güncelleme moduna alındı');
      return responseData;
    } else {
      print('❌ Failed to set gateway upgrade mode: ${response.statusCode}');
      throw Exception('Failed to set gateway upgrade mode from TTLock API');
    }
  }

  /// Delete an IC Card
  Future<void> deleteCard({
    required String lockId,
    required int cardId,
  }) async {
    print('🗑️ Kart siliniyor: $cardId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/lock/deleteICCard');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'cardId': cardId.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] != 0 && responseData['errcode'] != null) {
      throw Exception('Kart silinemedi: ${responseData['errmsg']}');
    }
    print('✅ Kart silindi');
  }

  /// Delete a Fingerprint
  Future<void> deleteFingerprint({
    required String lockId,
    required int fingerprintId,
  }) async {
    print('🗑️ Parmak izi siliniyor: $fingerprintId');
    await getAccessToken();

    final url = Uri.parse('$_baseUrl/v3/lock/deleteFingerprint');
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'fingerprintId': fingerprintId.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData['errcode'] != 0 && responseData['errcode'] != null) {
      throw Exception('Parmak izi silinemedi: ${responseData['errmsg']}');
    }
    print('✅ Parmak izi silindi');
  }

  /// Check device connectivity status
  Future<bool> checkDeviceConnectivity({
    required String accessToken,
    required String lockId,
  }) async {
    print('🔍 Connectivity kontrolü başlatılıyor: $lockId');

    // Birden fazla yöntem dene
    final methods = [
      () => _checkConnectivityWithQueryOpenState(accessToken, lockId),
      () => _checkConnectivityWithLockDetail(accessToken, lockId),
      () => _checkConnectivityWithLockRecords(accessToken, lockId),
    ];

    for (final method in methods) {
      try {
        final result = await method();
        if (result) {
          print('✅ Connectivity kontrolü başarılı');
          return true;
        }
      } catch (e) {
        print('⚠️ Connectivity yöntemi başarısız: $e');
        continue;
      }
    }

    print('❌ Tüm connectivity yöntemleri başarısız, offline kabul ediliyor');
    return false;
  }

  Future<bool> _checkConnectivityWithQueryOpenState(String accessToken, String lockId) async {
    final url = Uri.parse('$_baseUrl/v3/lock/queryOpenState').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 queryOpenState ile kontrol ediliyor...');
    final response = await http.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('📶 queryOpenState yanıtı: errcode=${responseData['errcode']}');
      return responseData['errcode'] == 0 || responseData['errcode'] == null;
    }
    return false;
  }

  Future<bool> _checkConnectivityWithLockDetail(String accessToken, String lockId) async {
    final url = Uri.parse('$_baseUrl/v3/lock/detail').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📋 lock detail ile kontrol ediliyor...');
    final response = await http.get(url).timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('📋 lock detail yanıtı: errcode=${responseData['errcode']}');
      return responseData['errcode'] == 0 || responseData['errcode'] == null;
    }
    return false;
  }

  Future<bool> _checkConnectivityWithLockRecords(String accessToken, String lockId) async {
    final url = Uri.parse('$_baseUrl/v3/lockRecord/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'pageNo': '1',
      'pageSize': '1',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📝 lock records ile kontrol ediliyor...');
    final response = await http.get(url).timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('📝 lock records yanıtı: errcode=${responseData['errcode']}');
      // Records API'si errcode=0 dönmese bile API erişilebilir durumda
      return response.statusCode == 200;
    }
    return false;
  }

  /// Request a new access token using username/password
  Future<bool> _requestNewAccessToken({
    required String username,
    required String password,
  }) async {
    final regions = ['https://euapi.ttlock.com', 'https://api.ttlock.com'];
    
    for (var regionBaseUrl in regions) {
      print('🔐 TTLock OAuth2 token isteği deneniyor ($regionBaseUrl)...');
      
      final url = Uri.parse('$regionBaseUrl/oauth2/token');
      // Send both snake_case and camelCase for maximum compatibility
      final bodyParams = <String, String>{
        'client_id': ApiConfig.clientId, 
        'clientId': ApiConfig.clientId,
        'client_secret': ApiConfig.clientSecret, 
        'clientSecret': ApiConfig.clientSecret,
        'username': username.trim(),
        'password': _generateMd5(password),
        'grant_type': 'password',
        'date': DateTime.now().millisecondsSinceEpoch.toString(), 
      };

      print('📡 OAuth2 isteği gönderiliyor ($regionBaseUrl)...');
      bodyParams.forEach((key, value) {
        if (key != 'password' && key != 'client_secret' && key != 'clientSecret') {
          print('   $key: $value');
        }
      });

      if (ApiConfig.redirectUri.isNotEmpty) {
        bodyParams['redirect_uri'] = ApiConfig.redirectUri;
      }

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: bodyParams,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
            final rawErrcode = responseData['errcode'];
            final errcode = (rawErrcode is int) ? rawErrcode : (int.tryParse(rawErrcode.toString()) ?? -1);
            
            print('⚠️  API Hata Yanıtı: errcode=$errcode (${responseData['errmsg'] ?? 'Mesaj yok'})');
            
            // If it's an error and not the last region, try next region
            // Region switch is usually for 10003 (Account not found) or 10005 (Password error in some regions)
            if (regionBaseUrl != regions.last) {
              print('⚠️  Bölge hatası veya hesap bulunamadı ($errcode), diğer bölge deneniyor...');
              continue; 
            }
            
            final errorMsg = responseData['errmsg'] ?? 'Unknown error';
            throw Exception('API Error $errcode: $errorMsg');
          }
          
          _accessToken = responseData['access_token'];
          _refreshToken = responseData['refresh_token'];
          
          final expiresInValue = responseData['expires_in'];
          int expiresIn = (expiresInValue is int) ? expiresInValue : (int.tryParse(expiresInValue?.toString() ?? '3600') ?? 3600);
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

          if (_accessToken != null && _refreshToken != null) {
            _baseUrl = regionBaseUrl; // Store the working region
            await _authRepository.saveTokens(
              accessToken: _accessToken!,
              refreshToken: _refreshToken!,
              expiry: _tokenExpiry!,
              baseUrl: _baseUrl,
            );
            print('✅ Token başarıyla alındı ($regionBaseUrl)');
            return true;
          }
        } else {
          print('❌ HTTP ${response.statusCode} from $regionBaseUrl: ${response.body}');
          print('   Response Headers: ${response.headers}');
          if (regionBaseUrl == regions.last) {
            String errorInfo = 'Bilinmeyen sunucu hatası (HTTP ${response.statusCode})';
            try {
              final data = json.decode(response.body);
              errorInfo = data['errmsg'] ?? data['error_description'] ?? data['error'] ?? response.body;
            } catch (_) {}
            throw Exception('Giriş başarısız ($regionBaseUrl): $errorInfo');
          }
        }
      } catch (e) {
        print('⚠️  $regionBaseUrl denemesinde hata: $e');
        if (regionBaseUrl == regions.last) rethrow;
      }
    }
    return false;
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    print('Refreshing access token...');
    final regions = [_baseUrl, 'https://euapi.ttlock.com', 'https://api.ttlock.com'];
    
    for (var regionBaseUrl in Set.from(regions)) { // Set to avoid duplicate checks
      final url = Uri.parse('$regionBaseUrl/oauth2/token');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'client_id': ApiConfig.clientId,
            'clientId': ApiConfig.clientId,
            'client_secret': ApiConfig.clientSecret,
            'clientSecret': ApiConfig.clientSecret,
            'refresh_token': _refreshToken!,
            'grant_type': 'refresh_token',
            'date': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
            continue; // Try next region if current fails
          }
          
          _accessToken = responseData['access_token'];
          _refreshToken = responseData['refresh_token'] ?? _refreshToken;
          
          final expiresInValue = responseData['expires_in'];
          int expiresIn = (expiresInValue is int) ? expiresInValue : (int.tryParse(expiresInValue?.toString() ?? '3600') ?? 3600);
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
          _baseUrl = regionBaseUrl; // Update working baseUrl

          if (_accessToken != null && _refreshToken != null) {
            await _authRepository.saveTokens(
              accessToken: _accessToken!,
              refreshToken: _refreshToken!,
              expiry: _tokenExpiry!,
              baseUrl: _baseUrl,
            );
            return true;
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    // If all regions fail, clear tokens
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    await _authRepository.deleteTokens();
    return false;
  }

  /// Register a new user in TTLock cloud
  /// Returns the prefixed username from the API response
  Future<String> registerUser({
    required String username,
    required String password,
  }) async {
    print('👤 Kullanıcı kaydı yapılıyor: $username');
    
    final url = Uri.parse('$_baseUrl/v3/user/register');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'clientSecret': ApiConfig.clientSecret,
      'username': username,
      'password': _generateMd5(password), // Password must be MD5 encrypted
      'date': now.toString(),
    };

    print('📡 Register API çağrısı: $url');
    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Register API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // TTLock API error handling
        if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
           print('❌ Register API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Registration failed: ${responseData['errmsg']}');
        }

        if (responseData.containsKey('username')) {
          final prefixedUsername = responseData['username'];
          print('✅ Kullanıcı başarıyla kaydedildi. Yeni kullanıcı adı: $prefixedUsername');
          return prefixedUsername;
        } else {
           throw Exception('Registration success but username missing in response');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kayıt işlemi istisnası: $e');
      rethrow;
    }
  }

  /// Reset password for a cloud-registered user
  /// Returns true if successful
  Future<bool> resetPassword({
    required String username,
    required String newPassword,
  }) async {
    print('🔐 Şifre sıfırlama işlemi: $username');
    
    final url = Uri.parse('$_baseUrl/v3/user/resetPassword');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'clientSecret': ApiConfig.clientSecret,
      'username': username,
      'password': _generateMd5(newPassword), // Password must be MD5 encrypted
      'date': now.toString(),
    };

    print('📡 Reset Password API çağrısı: $url');
    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Reset Password API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Şifre başarıyla sıfırlandı');
          return true;
        } else {
           print('❌ Reset Password API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Password reset failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Şifre sıfırlama istisnası: $e');
      rethrow;
    }
  }

  /// Get list of users registered via cloud API
  Future<Map<String, dynamic>> getUserList({
    int pageNo = 1,
    int pageSize = 20,
    int? startDate,
    int? endDate,
  }) async {
    print('👥 Kullanıcı listesi çekiliyor...');
    
    final url = Uri.parse('$_baseUrl/v3/user/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'clientSecret': ApiConfig.clientSecret,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
      if (startDate != null) 'startDate': startDate.toString(),
      if (endDate != null) 'endDate': endDate.toString(),
    });

    print('📡 User List API çağrısı: $url');

    try {
      final response = await http.get(url);

      print('📨 User List API yanıtı - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('🔍 User List: $responseData');
        return responseData;
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kullanıcı listesi alma istisnası: $e');
      rethrow;
    }
  }

  /// Delete a user registered/created by the cloud API
  Future<bool> deleteUser({
    required String username,
  }) async {
    print('🗑️ Kullanıcı siliniyor: $username');
    
    final url = Uri.parse('$_baseUrl/v3/user/delete');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'clientSecret': ApiConfig.clientSecret,
      'username': username,
      'date': now.toString(),
    };

    print('📡 Delete User API çağrısı: $url');
    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Delete User API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Kullanıcı başarıyla silindi');
          return true;
        } else {
           print('❌ Delete User API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('User deletion failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kullanıcı silme istisnası: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLockList({
    int pageNo = 1,
    int pageSize = 20,
    String? lockAlias,
    int? groupId,
  }) async {
    print('Fetching lock list from API...');
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'pageNo': pageNo.toString(),
      'pageSize': pageSize.toString(),
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (lockAlias != null) {
      queryParams['lockAlias'] = lockAlias;
    }

    if (groupId != null) {
      queryParams['groupId'] = groupId.toString();
    }

    final url = Uri.parse('$_baseUrl/v3/lock/list').replace(queryParameters: queryParams);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock API Full Response: $responseData'); // Debug için tüm yanıtı logla
      print('🔍 Response Code: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');

      if (responseData['list'] != null) {
        final List<dynamic> locksFromApi = responseData['list'];
        print('✅ Successfully fetched ${locksFromApi.length} locks from TTLock API.');

        // Debug: Her kilidin detaylarını detaylı logla
        for (var lock in locksFromApi) {
          print('🔐 Lock Details:');
          print('  - ID: ${lock['lockId']}');
          print('  - Name: ${lock['lockAlias']}');
          print('  - UserType: ${lock['userType'] ?? 'null'} (1=sahip, 2+=paylaşılmış)');
          print('  - LockData: ${lock['lockData'] != null ? '✅' : '❌'}');
          print('  - KeyState: ${lock['keyState']}');
          print('  - ElectricQuantity: ${lock['electricQuantity']}');
          print('  - LockMac: ${lock['lockMac']}');
          print('  - IsShared: ${lock['userType'] != 1 ? '✅' : '❌'}');
          print('  ---');
        }
        
        // Map the API data to the format our UI expects
        return locksFromApi.map((lock) {
          // Determine lock status based on 'lockState' if available, otherwise default
          // Note: The API might use different keys for lock state ('keyState', 'lockState', etc.)
          // This is a common mapping, adjust if needed based on actual API response.
          bool isLocked = lock['keyState'] == 0 || lock['keyState'] == 2;
          String status = isLocked ? 'Kilitli' : 'Açık';

          return {
            'lockId': lock['lockId'],
            'name': lock['lockAlias'] ?? 'İsimsiz Kilit',
            'status': status,
            'isLocked': isLocked,
            'battery': lock['electricQuantity'] ?? 0,
            'lockData': lock['lockData'],
            'lockMac': lock['lockMac'],
          };
        }).toList();

      } else {
         print('API response does not contain a lock list.');
         return [];
      }
    } else {
      print('Failed to get lock list: ${response.statusCode}');
      return [];
    }
  }

  /// Get detailed information about a specific lock
  Future<Map<String, dynamic>> getLockDetail({required String lockId}) async {
    print('🔍 Kilit detayları çekiliyor: $lockId');
    await getAccessToken();

    final Map<String, String> queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final url = Uri.parse('$_baseUrl/v3/lock/detail').replace(queryParameters: queryParams);

    print('📡 Lock Detail API çağrısı: $url');

    try {
      final response = await http.get(url);

      print('📨 Lock Detail API yanıtı - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // TTLock API error handling
        if (responseData.containsKey('errcode')) {
           if (responseData['errcode'] != 0) {
              print('❌ Lock Detail API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
              throw Exception('Get lock detail failed: ${responseData['errmsg']}');
           }
        }
        
        print('✅ Kilit detayları alındı');
        return responseData;
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kilit detayları alma istisnası: $e');
      rethrow;
    }
  }

  /// Delete a lock from the account
  /// WARNING: You must reset the lock via APP SDK before requesting this API,
  /// otherwise you'll lose the lockData of the lock.
  Future<bool> deleteLock({
    required String lockId,
  }) async {
    print('🗑️ Kilit siliniyor: $lockId');
    print('⚠️ UYARI: Kilit silinmeden önce APP SDK ile resetlenmiş olmalıdır!');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/delete');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Delete Lock API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Delete Lock API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Kilit başarıyla silindi');
          return true;
        } else {
           print('❌ Delete Lock API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Lock deletion failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kilit silme istisnası: $e');
      rethrow;
    }
  }

  /// Upload renewed lock data to cloud server
  /// Call this if you modified feature value, reset ekey, or reset passcode via SDK.
  Future<bool> updateLockData({
    required String lockId,
    required String lockData,
  }) async {
    print('🔄 Kilit verisi güncelleniyor: $lockId');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/updateLockData');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'lockData': lockData,
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Update Lock Data API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Update Lock Data API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Kilit verisi başarıyla güncellendi');
          return true;
        } else {
           print('❌ Update Lock Data API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Update lock data failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kilit verisi güncelleme istisnası: $e');
      rethrow;
    }
  }

  /// Rename a lock
  Future<bool> renameLock({
    required String lockId,
    required String newName,
  }) async {
    print('✏️ Kilit yeniden adlandırılıyor: $lockId -> $newName');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/rename');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'lockAlias': newName,
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Rename Lock API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Rename Lock API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Kilit başarıyla yeniden adlandırıldı');
          return true;
        } else {
           print('❌ Rename Lock API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Rename lock failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kilit yeniden adlandırma istisnası: $e');
      rethrow;
    }
  }

  /// Change the super passcode of the lock
  /// [changeType]: 1-via phone bluetooth (must call APP SDK first), 2-via gateway/WiFi
  Future<bool> changeAdminKeyboardPwd({
    required String lockId,
    required String password,
    int changeType = 1,
  }) async {
    print('🔑 Süper şifre değiştiriliyor: $lockId');
    if (changeType == 1) {
      print('⚠️ UYARI: Bluetooth ile değişim için önce APP SDK methodu çağrılmalıdır!');
    }
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/changeAdminKeyboardPwd');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'password': password,
      'changeType': changeType.toString(),
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Change Admin Pwd API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Change Admin Pwd API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Süper şifre başarıyla değiştirildi');
          return true;
        } else {
           print('❌ Change Admin Pwd API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Change admin password failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Süper şifre değiştirme istisnası: $e');
      rethrow;
    }
  }

  /// Transfer one or more locks to another account
  /// [lockIdList]: List of lock IDs to transfer
  Future<bool> transferLock({
    required String receiverUsername,
    required List<int> lockIdList,
  }) async {
    print('🔄 Kilitler transfer ediliyor: $lockIdList -> $receiverUsername');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/transfer');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'receiverUsername': receiverUsername,
      'lockIdList': jsonEncode(lockIdList),
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Transfer Lock API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Transfer Lock API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Kilitler başarıyla transfer edildi');
          return true;
        } else {
           print('❌ Transfer Lock API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Transfer lock failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kilit transfer istisnası: $e');
      rethrow;
    }
  }

  /// Upload lock battery level to server
  /// Call this when unlocking the lock via SDK to sync battery status
  Future<bool> updateElectricQuantity({
    required String lockId,
    required int electricQuantity,
  }) async {
    print('🔋 Batarya seviyesi güncelleniyor: $lockId -> $electricQuantity%');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/updateElectricQuantity');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'electricQuantity': electricQuantity.toString(),
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Update Battery API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Update Battery API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Batarya seviyesi başarıyla güncellendi');
          return true;
        } else {
           print('❌ Update Battery API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Update battery failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Batarya güncelleme istisnası: $e');
      rethrow;
    }
  }

  /// Set the auto lock time of a lock
  /// [seconds]: The lock will automatically locked after the specific seconds. 0 or -1 means close auto lock.
  /// [type]: 1-via phone bluetooth (must call APP SDK first), 2-via gateway/WiFi
  Future<bool> setAutoLockTime({
    required String lockId,
    required int seconds,
    int type = 1,
  }) async {
    print('⏱️ Otomatik kilitlenme süresi ayarlanıyor: $lockId -> ${seconds}s (Type: $type)');
    if (type == 1) {
      print('⚠️ UYARI: Bluetooth ile ayar için önce APP SDK methodu çağrılmalıdır!');
    }
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/setAutoLockTime');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'seconds': seconds.toString(),
      'type': type.toString(),
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Set Auto Lock Time API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Set Auto Lock Time API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Otomatik kilitlenme süresi başarıyla ayarlandı');
          return true;
        } else {
           print('❌ Set Auto Lock Time API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Set auto lock time failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Otomatik kilitlenme süresi ayarlama istisnası: $e');
      rethrow;
    }
  }

  /// Configure the passage mode of a lock
  /// [passageMode]: 1-on, 2-off
  /// [cyclicConfig]: List of cyclic configurations (see API docs)
  /// [type]: 1-via phone bluetooth (must call APP SDK first), 2-via gateway/WiFi
  Future<bool> configurePassageMode({
    required String lockId,
    required int passageMode,
    List<Map<String, dynamic>>? cyclicConfig,
    int type = 1,
  }) async {
    print('🔓 Passage modu ayarlanıyor: $lockId -> Mode: $passageMode (Type: $type)');
    if (type == 1) {
      print('⚠️ UYARI: Bluetooth ile ayar için önce APP SDK methodu çağrılmalıdır!');
    }
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/configurePassageMode');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'passageMode': passageMode.toString(),
      'type': type.toString(),
      'date': now.toString(),
    };

    if (cyclicConfig != null) {
      body['cyclicConfig'] = jsonEncode(cyclicConfig);
    }

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Config Passage Mode API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Config Passage Mode API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Passage modu başarıyla ayarlandı');
          return true;
        } else {
           print('❌ Config Passage Mode API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Config passage mode failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Passage modu ayarlama istisnası: $e');
      rethrow;
    }
  }

  /// Get the passage mode configuration of a lock
  Future<Map<String, dynamic>> getPassageModeConfiguration({
    required String lockId,
  }) async {
    print('🧐 Passage modu konfigürasyonu çekiliyor: $lockId');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final url = Uri.parse('$_baseUrl/v3/lock/getPassageModeConfiguration').replace(queryParameters: queryParams);

    print('📡 Get Passage Mode Config API çağrısı: $url');

    try {
      final response = await http.get(url);

      print('📨 Get Passage Mode Config API yanıtı - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // TTLock API error handling
        if (responseData.containsKey('errcode')) {
           // errcode is present in success response too? The example doesn't show it in success JSON but description mentions it.
           // Usually GET requests return data directly or with errcode.
           // Let's check if there is an error code that is NOT 0.
           if ((responseData['errcode'] == 0 || responseData['errcode'] == null) || (responseData['errcode'] != null && responseData['errcode'] != 0)) {
              // This is a GET config, if it's not a non-zero error, consider it okay or check for error specifically
              if (responseData['errcode'] != null && responseData['errcode'] != 0) {
                 print('❌ Get Passage Mode Config API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
                 throw Exception('Get passage mode config failed: ${responseData['errmsg']}');
              }
           }
        }
        
        print('✅ Passage modu konfigürasyonu alındı');
        return responseData;
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Passage modu konfigürasyonu alma istisnası: $e');
      rethrow;
    }
  }

  /// Set the hotel card sector of a lock
  /// [sector]: Hotel card sector, e.g., "1,2,3,4,5,6,7,8,9,10"
  /// WARNING: You must firstly modify the hotel card sector by APP SDK before you request this API
  Future<bool> setHotelCardSector({
    required String lockId,
    required String sector,
  }) async {
    print('🏨 Hotel kart sektörü ayarlanıyor: $lockId -> $sector');
    print('⚠️ UYARI: Bu API çağrılmadan önce APP SDK ile sektör ayarı yapılmalıdır!');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/setHotelCardSector');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'sector': sector,
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Set Hotel Card Sector API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Set Hotel Card Sector API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Hotel kart sektörü başarıyla ayarlandı');
          return true;
        } else {
           print('❌ Set Hotel Card Sector API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Set hotel card sector failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Hotel kart sektörü ayarlama istisnası: $e');
      rethrow;
    }
  }

  /// Query lock settings (Privacy lock, Tamper alert, Reset button, Open direction)
  /// [type]: 2-Privacy lock, 3-Tamper alert, 4-Reset button, 7-Open direction
  Future<int> queryLockSetting({
    required String lockId,
    required int type,
  }) async {
    print('❓ Kilit ayarı sorgulanıyor: $lockId -> Type: $type');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/querySetting');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'type': type.toString(),
      'date': now.toString(),
    };

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Query Lock Setting API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Query Lock Setting API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData.containsKey('errcode') && responseData['errcode'] != 0 && responseData['errcode'] != null) {
           print('❌ Query Lock Setting API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Query lock setting failed: ${responseData['errmsg']}');
        }
        
        // Success response contains "value"
        if (responseData.containsKey('value')) {
           print('✅ Kilit ayarı sorgulandı: ${responseData['value']}');
           return responseData['value'];
        } else {
           throw Exception('Unexpected response format: no value field');
        }

      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Kilit ayarı sorgulama istisnası: $e');
      rethrow;
    }
  }

  /// Get the working mode configuration of a lock
  Future<Map<String, dynamic>> getWorkingMode({
    required String lockId,
  }) async {
    print('🧐 Çalışma modu çekiliyor: $lockId');
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final queryParams = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final url = Uri.parse('$_baseUrl/v3/lock/getWorkingMode');

    print('📡 Get Working Mode API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: queryParams,
      );

      print('📨 Get Working Mode API yanıtı - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData.containsKey('errcode') && responseData['errcode'] != 0 && responseData['errcode'] != null) {
           print('❌ Get Working Mode API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Get working mode failed: ${responseData['errmsg']}');
        }
        
        print('✅ Çalışma modu alındı');
        return responseData;
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Çalışma modu alma istisnası: $e');
      rethrow;
    }
  }

  /// Configure the working mode of a lock
  /// [workingMode]: 1: working all day, 2: not working all day, 3: custom
  /// [type]: 1-via phone bluetooth (must call APP SDK first), 2-via gateway/WiFi
  /// [cyclicConfig]: List of cyclic configurations (see API docs)
  Future<bool> configWorkingMode({
    required String lockId,
    required int workingMode,
    required int type,
    List<Map<String, dynamic>>? cyclicConfig,
  }) async {
    print('⚙️ Çalışma modu ayarlanıyor: $lockId -> Mode: $workingMode (Type: $type)');
    if (type == 1) {
      print('⚠️ UYARI: Bluetooth ile ayar için önce APP SDK methodu çağrılmalıdır!');
    }
    
    // Ensure we have a valid token
    await getAccessToken();
    
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/configWorkingMode');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final body = {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken!,
      'lockId': lockId,
      'workingMode': workingMode.toString(),
      'type': type.toString(),
      'date': now.toString(),
    };

    if (cyclicConfig != null) {
      body['cyclicConfig'] = jsonEncode(cyclicConfig);
    }

    // Ensure all values are strings
    final formBody = body.map((key, value) => MapEntry(key, value.toString()));

    print('📡 Config Working Mode API çağrısı: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      );

      print('📨 Config Working Mode API yanıtı - Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
          print('✅ Çalışma modu başarıyla ayarlandı');
          return true;
        } else {
           print('❌ Config Working Mode API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
           throw Exception('Config working mode failed: ${responseData['errmsg']}');
        }
      } else {
        print('❌ HTTP hatası: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Çalışma modu ayarlama istisnası: $e');
      rethrow;
    }
  }


  // TTLock kilidi açma/kapama (Gateway API ile - Callback URL gerekli)

  // TTLock kilidi açma/kapama (Gateway API ile - Callback URL gerekli)
  Future<Map<String, dynamic>> controlTTLock({
    required String lockId,
    required bool lock, // true: kilitle, false: aç
    required String accessToken,
  }) async {
    final url = Uri.parse('$_baseUrl/v3/lock/${lock ? 'lock' : 'unlock'}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'clientId': ApiConfig.clientId,
        'accessToken': accessToken,
        'lockId': lockId,
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('TTLock ${lock ? 'kilitleme' : 'açma'} başarılı: $lockId');
        return responseData;
      } else {
        throw Exception('TTLock API hatası: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('TTLock HTTP hatası: ${response.statusCode}');
    }
  }

  // TTLock Webhook callback URL'ini ayarlama
  Future<Map<String, dynamic>> setTTLockWebhook({
    required String accessToken,
    required String callbackUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/v3/setting/webhook');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'clientId': ApiConfig.clientId,
        'accessToken': accessToken,
        'url': callbackUrl,
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('TTLock webhook URL başarıyla ayarlandı: $callbackUrl');
        return responseData;
      } else {
        throw Exception('TTLock webhook ayarlama hatası: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('TTLock webhook HTTP hatası: ${response.statusCode}');
    }
  }

  // TTLock paylaşılmış kilitleri alma - farklı endpoint'leri dene
  Future<List<Map<String, dynamic>>> getSharedLockList() async {
    print('🔍 TTLock paylaşılmış kilitleri çekmeye çalışıyorum...');
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    // Farklı endpoint'leri sırayla dene
    final endpoints = [
      '$_baseUrl/v3/lock/listShared',  // Paylaşılmış kilitler için özel endpoint
      '$_baseUrl/v3/lock/listAll',     // Tüm kilitler için
      '$_baseUrl/v3/lock/list',        // Normal endpoint (farklı parametrelerle)
    ];

    for (final endpoint in endpoints) {
      print('🔄 Endpoint deneniyor: $endpoint');

      try {
        final url = Uri.parse(endpoint).replace(queryParameters: {
          'clientId': ApiConfig.clientId,
          'accessToken': _accessToken,
          'pageNo': '1',
          'pageSize': '100',
          'date': DateTime.now().millisecondsSinceEpoch.toString(),
        });

        final response = await http.get(url);

        print('📡 Endpoint: $endpoint - Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('✅ $endpoint başarılı yanıt verdi: $responseData');

          if (responseData['list'] != null) {
            final List<dynamic> locksFromApi = responseData['list'];
            print('📋 $endpoint\'den ${locksFromApi.length} kilit çekildi.');

            // Tüm kilitleri işle (hem kendi hem paylaşılmış)
            final allLocks = locksFromApi.map((lock) {
              bool isLocked = lock['keyState'] == 1 || lock['keyState'] == 2;
              String status = isLocked ? 'Kilitli' : 'Açık';
              bool isShared = lock['userType'] != 1; // 1: sahip, diğer: paylaşılmış

              return {
                'lockId': lock['lockId'],
                'name': lock['lockAlias'] ?? (isShared ? 'Paylaşılmış Kilit' : 'TTLock Kilit'),
                'status': status,
                'isLocked': isLocked,
                'battery': lock['electricQuantity'] ?? 0,
                'lockData': lock['lockData'],
                'lockMac': lock['lockMac'],
                'userType': lock['userType'] ?? 1,
                'shared': isShared,
              };
            }).toList();

            // Başarılı endpoint bulundu, sonucu döndür
            return allLocks;
          } else {
            print('❌ $endpoint yanıtında list bulunamadı');
            continue; // Sonraki endpoint'i dene
          }
        } else {
          print('❌ $endpoint başarısız: ${response.statusCode} - ${response.body}');
          continue; // Sonraki endpoint'i dene
        }
      } catch (e) {
        print('❌ $endpoint hatası: $e');
        continue; // Sonraki endpoint'i dene
      }
    }

    // Hiçbir endpoint çalışmadıysa normal list endpoint'ini son çare olarak dene
    print('⚠️ Özel endpoint\'ler çalışmadı, normal endpoint deneniyor...');
    return getLockList();
  }

  // TTLock olay geçmişini alma (webhook yerine alternatif)
  Future<List<dynamic>> getTTLockRecords({
    required String accessToken,
    required String lockId,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final url = Uri.parse('$_baseUrl/v3/lockRecord/list');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'clientId': ApiConfig.clientId,
        'accessToken': accessToken,
        'lockId': lockId,
        'pageNo': pageNo.toString(),
        'pageSize': pageSize.toString(),
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        return responseData['list'] ?? [];
      } else {
        throw Exception('TTLock kayıt alma hatası: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('TTLock kayıt HTTP hatası: ${response.statusCode}');
    }
  }

  // TTLock Webhook olaylarını işleme
  static TTLockWebhookEvent? processTTLockWebhookEvent(Map<String, dynamic> payload) {
    try {
      final event = TTLockWebhookEvent.fromJson(payload);
      print('TTLock webhook olayı alındı: ${event.eventType} - Kilit: ${event.lockId}');
      return event;
    } catch (e) {
      print('TTLock webhook işleme hatası: $e');
      return null;
    }
  }

  // TTLock event type parser (yerel fonksiyon)
  static TTLockWebhookEventType _parseTTLockEventTypeLocal(String eventType) {
    switch (eventType) {
      case '1':
      case 'lockOpened':
        return TTLockWebhookEventType.lockOpened;
      case '2':
      case 'lockClosed':
        return TTLockWebhookEventType.lockClosed;
      case '3':
      case 'lockOpenedFromApp':
        return TTLockWebhookEventType.lockOpenedFromApp;
      case '4':
      case 'lockOpenedFromKeypad':
        return TTLockWebhookEventType.lockOpenedFromKeypad;
      case '5':
      case 'lockOpenedFromFingerprint':
        return TTLockWebhookEventType.lockOpenedFromFingerprint;
      case '6':
      case 'lockOpenedFromCard':
        return TTLockWebhookEventType.lockOpenedFromCard;
      case '7':
      case 'lowBattery':
        return TTLockWebhookEventType.lowBattery;
      case '8':
      case 'lockTampered':
        return TTLockWebhookEventType.lockTampered;
      default:
        return TTLockWebhookEventType.unknown;
    }
  }


}


