import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ttlock_flutter_example/config.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';


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

enum SeamWebhookEventType {
  lockUnlocked,
  lockLocked,
  accessCodeCreated,
  accessCodeDeleted,
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

class SeamWebhookEvent {
  final String eventId;
  final SeamWebhookEventType eventType;
  final String deviceId;
  final Map<String, dynamic>? eventData;
  final DateTime timestamp;

  SeamWebhookEvent({
    required this.eventId,
    required this.eventType,
    required this.deviceId,
    this.eventData,
    required this.timestamp,
  });

  factory SeamWebhookEvent.fromJson(Map<String, dynamic> json) {
    return SeamWebhookEvent(
      eventId: json['event_id'] ?? '',
      eventType: _parseEventType(json['event_type']),
      deviceId: json['device_id'] ?? '',
      eventData: json['event_data'],
      timestamp: DateTime.parse(json['occurred_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static TTLockWebhookEventType parseTTLockEventType(String eventType) {
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


  static SeamWebhookEventType _parseEventType(String? eventType) {
    switch (eventType) {
      case 'lock.unlocked':
        return SeamWebhookEventType.lockUnlocked;
      case 'lock.locked':
        return SeamWebhookEventType.lockLocked;
      case 'access_code.created':
        return SeamWebhookEventType.accessCodeCreated;
      case 'access_code.deleted':
        return SeamWebhookEventType.accessCodeDeleted;
      default:
        return SeamWebhookEventType.unknown;
    }
  }
}

class ApiService {
  static const String _baseUrl = 'https://euapi.ttlock.com';
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
    // TTLock requires lowercase MD5 hash
    return md5.convert(utf8.encode(input.trim())).toString().toLowerCase();
  }

  /// Initialize tokens from persistent storage
  Future<void> initializeTokens() async {
    _accessToken = await _authRepository.getAccessToken();
    _refreshToken = await _authRepository.getRefreshToken();
    _tokenExpiry = await _authRepository.getTokenExpiry();
  }

  /// Get access token, using refresh token if available and needed
  Future<bool> getAccessToken({String? username, String? password}) async {
    print('🔑 Access token alma işlemi başladı...');

    // First, try to load from storage
    if (_accessToken == null || _tokenExpiry == null) {
      print('📝 Token bilgilerini yerel depodan yüklüyor...');
      await initializeTokens();
    }

    // If token exists and is valid, no need to fetch a new one
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(Duration(minutes: 5)))) {
      print('✅ Mevcut geçerli token kullanılıyor');
      print('   Token: ${_accessToken!.substring(0, 20)}...');
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

  /// Get user's key list (both owned and shared locks)
  Future<List<Map<String, dynamic>>> getKeyList() async {
    print('🔑 TTLock key listesi çekme işlemi başladı...');

    // Ensure we have a valid token
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/key/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken,
      'pageNo': '1',
      'pageSize': '100',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('📡 Key list API çağrısı: ${url.toString()}');

    final response = await http.get(url);

    print('📨 Key list API yanıtı - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('🔍 TTLock Key List API Full Response: $responseData');

      // Debug: İlk kilit için tüm alanları logla
      if (responseData['list'] != null && (responseData['list'] as List).isNotEmpty) {
        final firstLock = (responseData['list'] as List).first;
        print('🔍 İlk kilit alanları: ${firstLock.keys.join(', ')}');
        print('🔍 lockAlias: ${firstLock['lockAlias']}');
        print('🔍 lockName: ${firstLock['lockName']}');
        print('🔍 lockNickName: ${firstLock['lockNickName']}');
        print('🔍 electricQuantity: ${firstLock['electricQuantity']}');
        print('🔍 battery: ${firstLock['battery']}');
        print('🔍 keyState: ${firstLock['keyState']}');
      }

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
          
          final keyStatus = key['keyStatus'] ?? 0;
          final electricQuantity = key['electricQuantity'] ?? key['battery'] ?? 0;

          // Determine if this is a shared key (keyStatus indicates sharing)
          final isShared = keyStatus == 2 || keyStatus == 3; 

          return {
            'lockId': lockId,
            'keyId': keyId,
            'name': lockAlias, // Orijinal ad
            'lockData': key['lockData'] ?? '',
            'lockMac': key['lockMac'] ?? '',
            'battery': electricQuantity,
            'keyStatus': keyStatus,
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
    required String accessToken,
  }) async {
    print('📡 Gateway listesi çekiliyor');
    final url = Uri.parse('$_baseUrl/v3/gateway/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
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
      throw Exception('Failed to get gateway list');
    }
  }

  /// Send remote unlock command via TTLock API
  Future<Map<String, dynamic>> sendRemoteUnlock({
    required String accessToken,
    required String lockId,
  }) async {
    print('🔓 Uzaktan açma komutu gönderiliyor: $lockId');

    // TTLock API endpoint: /v3/lock/unlock
    final url = Uri.parse('$_baseUrl/v3/lock/unlock');

    // Parametreleri body olarak gönder (application/x-www-form-urlencoded)
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
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
    required String accessToken,
    required String gatewayId,
  }) async {
    print('📋 Gateway detayları alınıyor: $gatewayId');

    final url = Uri.parse('$_baseUrl/v3/gateway/detail').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'gatewayId': gatewayId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Gateway detayları alındı: $gatewayId');
        return responseData;
      } else {
        throw Exception('Gateway detayları alınamadı: ${responseData['errmsg']}');
      }
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

  /// Get locks connected to a gateway
  Future<List<Map<String, dynamic>>> getGatewayLocks({
    required String accessToken,
    required String gatewayId,
  }) async {
    print('🔗 Gateway\'e bağlı kilitler alınıyor: $gatewayId');

    final url = Uri.parse('$_baseUrl/v3/gateway/listLock').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'gatewayId': gatewayId,
      'pageNo': '1',
      'pageSize': '50',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if ((responseData['errcode'] == 0 || responseData['errcode'] == null) && responseData['list'] != null) {
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
  }) async {
    print('🔑 Elektronik anahtarlar çekiliyor: $lockId');
    final url = Uri.parse('$_baseUrl/v3/key/list').replace(queryParameters: {
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
        // Filter only e-keys for this specific lock
        final allKeys = (responseData['list'] as List).cast<Map<String, dynamic>>();
        return allKeys.where((key) => key['lockId'].toString() == lockId).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to get lock e-keys');
    }
  }

  /// Delete a specific e-key
  Future<Map<String, dynamic>> deleteEKey({
    required String accessToken,
    required String keyId,
  }) async {
    print('🗑️ E-key siliniyor: $keyId');
    final url = Uri.parse('$_baseUrl/v3/key/delete').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'keyId': keyId,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        return responseData;
      } else {
        throw Exception('Failed to delete e-key: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('Failed to delete e-key');
    }
  }

  /// Share lock with another user
  Future<Map<String, dynamic>> shareLock({
    required String accessToken,
    required String lockId,
    required String receiverUsername, // Email or phone
    required int keyRight, // 1: Admin, 2: Normal user, 3: Limited user
    DateTime? startDate,
    DateTime? endDate,
    String? remarks,
  }) async {
    print('🔗 Kilit paylaşılıyor: $lockId -> $receiverUsername');

    // TTLock API endpoint: /v3/key/send (e-key gönderme)
    final url = Uri.parse('$_baseUrl/v3/key/send');

    // Parametreleri body olarak gönder (application/x-www-form-urlencoded)
    final Map<String, String> body = {
      'clientId': ApiConfig.clientId,
      'accessToken': accessToken,
      'lockId': lockId,
      'username': receiverUsername, // TTLock API için 'username' parametresi
      'keyRight': keyRight.toString(),
      if (startDate != null) 'startDate': startDate.millisecondsSinceEpoch.toString(),
      if (endDate != null) 'endDate': endDate.millisecondsSinceEpoch.toString(),
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print('📡 Kilit paylaşım API çağrısı: $url');
    print('📝 Body parametreleri: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    print('📨 Paylaşım API yanıtı - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['errcode'] == 0 || responseData['errcode'] == null) {
        print('✅ Kilit başarıyla paylaşıldı: $lockId');
        return responseData;
      } else {
        print('❌ Kilit paylaşımı API hatası: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
        throw Exception('Kilit paylaşımı başarısız: ${responseData['errmsg']} (errcode: ${responseData['errcode']})');
      }
    } else {
      print('❌ HTTP hatası: ${response.statusCode}');
      throw Exception('Kilit paylaşımı başarısız: HTTP ${response.statusCode}');
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
    print('🔐 TTLock OAuth2 token isteği hazırlanıyor...');
    print('   Base URL: $_baseUrl');
    print('   Username: $username');
    print('   Password (uzunluk): ${password.length} karakter');
    print('   Password (MD5): ${_generateMd5(password)}');
    print('   Client ID: ${ApiConfig.clientId}');
    print('   Client Secret: ${ApiConfig.clientSecret.substring(0, 10)}...');
    
    final url = Uri.parse('$_baseUrl/oauth2/token');
    
    // Build form data properly - TTLock uses camelCase
    // Note: Some TTLock portals don't require redirect_uri for password grant
    final bodyParams = <String, String>{
      'clientId': ApiConfig.clientId,
      'clientSecret': ApiConfig.clientSecret,
      'username': username.trim(), // Trim whitespace
      'password': _generateMd5(password),
      'grant_type': 'password',
    };
    
    // Only add redirect_uri if explicitly configured and not empty
    // Many TTLock portals don't require redirect_uri for password grant type
    // If you get error 10007, try removing redirect_uri by setting it to empty string in config.dart
    if (ApiConfig.redirectUri.isNotEmpty && ApiConfig.redirectUri != '') {
      bodyParams['redirect_uri'] = ApiConfig.redirectUri;
      print('Using redirect_uri: ${ApiConfig.redirectUri}');
    } else {
      print('Skipping redirect_uri (not required for password grant)');
    }

    print('Request params: ${bodyParams.map((k, v) => MapEntry(k, k == 'password' || k == 'client_secret' ? '***' : v))}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: bodyParams,
      ).timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('🔍 TTLock API Full Response: $responseData');
        
        // Check for error in response body (some APIs return 200 with error)
        if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
          final errorMsg = responseData['errmsg'] ?? 'Unknown error';
          print('❌ API Error: ${responseData['errcode']} - $errorMsg');
          print('   Error Description: ${responseData['description'] ?? 'No description'}');
          _accessToken = null;
          _refreshToken = null;
          _tokenExpiry = null;
          throw Exception('API Error ${responseData['errcode']}: $errorMsg');
        }
        
        _accessToken = responseData['access_token'];
        _refreshToken = responseData['refresh_token'];
        
        if (_accessToken == null) {
          print('❌ ERROR: access_token is null in response');
          print('Full response: $responseData');
          throw Exception('No access_token in response: ${response.body}');
        }

        print('✅ Token başarıyla alındı: ${_accessToken!.substring(0, 20)}...');
        
        final expiresInValue = responseData['expires_in'];
        int expiresIn;
        if (expiresInValue is int) {
          expiresIn = expiresInValue;
        } else if (expiresInValue is String) {
          expiresIn = int.tryParse(expiresInValue) ?? 3600;
        } else {
          expiresIn = 3600;
        }
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        // Save tokens to persistent storage
        if (_accessToken != null && _refreshToken != null && _tokenExpiry != null) {
          await _authRepository.saveTokens(
            accessToken: _accessToken!,
            refreshToken: _refreshToken!,
            expiry: _tokenExpiry!,
          );
        }

        print('Successfully obtained access token');
        return true;
      } else {
        print('Failed to get access token: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        
        // Try to parse error message
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('errmsg')) {
            errorMessage = errorData['errmsg'];
          } else if (errorData.containsKey('error_description')) {
            errorMessage = errorData['error_description'];
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          errorMessage = response.body;
        }
        
        _accessToken = null;
        _refreshToken = null;
        _tokenExpiry = null;
        throw Exception('Failed to get access token: $errorMessage');
      }
    } on TimeoutException {
      print('Request timeout');
      throw Exception('Request timeout - please check your internet connection');
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Exception in _requestNewAccessToken: $e');
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      return false;
    }

    print('Refreshing access token...');
    final url = Uri.parse('$_baseUrl/oauth2/token');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'clientId': ApiConfig.clientId,
        'clientSecret': ApiConfig.clientSecret,
        'refresh_token': _refreshToken!,
        'grant_type': 'refresh_token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _accessToken = responseData['access_token'];
      _refreshToken = responseData['refresh_token'] ?? _refreshToken; // Keep old refresh token if not provided
      
      final expiresInValue = responseData['expires_in'];
      int expiresIn;
      if (expiresInValue is int) {
        expiresIn = expiresInValue;
      } else if (expiresInValue is String) {
        expiresIn = int.tryParse(expiresInValue) ?? 3600;
      } else {
        expiresIn = 3600;
      }
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      // Save tokens to persistent storage
      if (_accessToken != null && _refreshToken != null && _tokenExpiry != null) {
        await _authRepository.saveTokens(
          accessToken: _accessToken!,
          refreshToken: _refreshToken!,
          expiry: _tokenExpiry!,
        );
      }

      print('Successfully refreshed access token');
      return true;
    } else {
      print('Failed to refresh access token: ${response.statusCode}');
      print('Response: ${response.body}');
      // Clear invalid tokens
      _refreshToken = null;
      _accessToken = null;
      _tokenExpiry = null;
      await _authRepository.deleteTokens();
      return false;
    }
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

  // Seam Sandbox cihazlarını getiren fonksiyon
  static Future<List<dynamic>> getSandboxDevices() async {
    final response = await http.get(
      Uri.parse('${SeamConfig.baseUrl}/devices/list'),
      headers: {
        'Authorization': 'Bearer ${SeamConfig.seamApiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['devices']; // Cihaz listesini döner
    } else {
      print("Seam API Hatası - Kod: ${response.statusCode}");
      print("Seam API Yanıt: ${response.body}");
      throw Exception('Seam cihazları listelenemedi. Kod: ${response.statusCode}');
    }
  }

  // Seam cihazını kilitleme/kilidi açma fonksiyonu
  static Future<Map<String, dynamic>> controlSeamLock({
    required String deviceId,
    required bool lock,
  }) async {
    final endpoint = lock ? 'lock_door' : 'unlock_door';
    final url = Uri.parse('${SeamConfig.baseUrl}/locks/$endpoint');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${SeamConfig.seamApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_id': deviceId,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('Seam $endpoint başarılı: $deviceId');
      return data;
    } else {
      print("Seam $endpoint hatası - Kod: ${response.statusCode}");
      print("Seam $endpoint yanıt: ${response.body}");
      throw Exception('Seam kilidi ${lock ? 'kilitleme' : 'açma'} başarısız. Kod: ${response.statusCode}');
    }
  }

  // TTLock kilidi açma/kapama (Gateway API ile - Callback URL gerekli)
  static Future<Map<String, dynamic>> controlTTLock({
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
  static Future<Map<String, dynamic>> setTTLockWebhook({
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
  static Future<List<dynamic>> getTTLockRecords({
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

  // Seam Webhook signature doğrulama fonksiyonu
  static bool verifySeamWebhookSignature(String payload, String signature, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final expectedSignature = 'sha256=${digest.toString()}';
    return signature == expectedSignature;
  }

  // Webhook olayını işleme fonksiyonu
  static Future<SeamWebhookEvent?> processWebhookEvent(
    Map<String, dynamic> payload,
    String? signature
  ) async {
    try {
      // Signature doğrulama (üretim ortamında aktif edilmeli)
      if (signature != null && SeamConfig.webhookSecret.isNotEmpty) {
        final isValid = verifySeamWebhookSignature(
          jsonEncode(payload),
          signature,
          SeamConfig.webhookSecret
        );
        if (!isValid) {
          print('Webhook signature verification failed');
          return null;
        }
      }

      final event = SeamWebhookEvent.fromJson(payload);
      print('Webhook event received: ${event.eventType} for device ${event.deviceId}');

      return event;
    } catch (e) {
      print('Webhook processing error: $e');
      return null;
    }
  }
}

// Webhook Service - Gerçek zamanlı olayları yönetir
class WebhookService {
  static WebhookService? _instance;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<SeamWebhookEvent> _eventController = StreamController<SeamWebhookEvent>.broadcast();

  // Singleton pattern
  static WebhookService get instance {
    _instance ??= WebhookService._();
    return _instance!;
  }

  WebhookService._();

  // Gerçek zamanlı olayları dinlemek için stream
  Stream<SeamWebhookEvent> get eventStream => _eventController.stream;

  // WebSocket bağlantısı başlat
  void connect(String websocketUrl) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));

      _subscription = _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _reconnect(websocketUrl);
        },
        onDone: () {
          print('WebSocket connection closed');
          _reconnect(websocketUrl);
        },
      );

      print('Webhook WebSocket connected to $websocketUrl');
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }

  // WebSocket mesajını işle
  void _handleIncomingMessage(dynamic message) {
    try {
      final Map<String, dynamic> payload = jsonDecode(message.toString());

      // Webhook event'ini async olarak işle
      processWebhookEventAsync(payload, payload['signature']);
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
  }

  // Bağlantı koparsa yeniden bağlan
  void _reconnect(String websocketUrl) {
    Future.delayed(const Duration(seconds: 5), () {
      print('Attempting to reconnect WebSocket...');
      connect(websocketUrl);
    });
  }

  // Bağlantıyı kapat
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _eventController.close();
    print('Webhook WebSocket disconnected');
  }

  // Webhook olaylarını test için simüle et
  void simulateWebhookEvent(SeamWebhookEvent event) {
    _eventController.add(event);
  }

  // Webhook event'ini async olarak işle
  Future<void> processWebhookEventAsync(Map<String, dynamic> payload, String? signature) async {
    final event = await ApiService.processWebhookEvent(payload, signature);
    if (event != null) {
      _eventController.add(event);
    }
  }
}

