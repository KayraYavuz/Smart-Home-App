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
    // First, try to load from storage
    if (_accessToken == null || _tokenExpiry == null) {
      await initializeTokens();
    }

    // If token exists and is valid, no need to fetch a new one
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(Duration(minutes: 5)))) {
      print('Using existing access token');
      return true;
    }

    // Try to refresh token if available
    if (_refreshToken != null && _tokenExpiry != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return true;
      }
    }

    // Otherwise, get new token with username/password
    return await _requestNewAccessToken(
      username: username ?? ApiConfig.username,
      password: password ?? ApiConfig.password,
    );
  }

  /// Request a new access token using username/password
  Future<bool> _requestNewAccessToken({
    required String username,
    required String password,
  }) async {
    print('Fetching new access token...');
    print('Base URL: $_baseUrl');
    print('Username: $username');
    print('Password (plain): ${password.length} characters');
    print('Password (MD5): ${_generateMd5(password)}');
    print('Client ID: ${ApiConfig.clientId}');
    
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
        
        // Check for error in response body (some APIs return 200 with error)
        if (responseData.containsKey('errcode') && responseData['errcode'] != 0) {
          final errorMsg = responseData['errmsg'] ?? 'Unknown error';
          print('API Error: ${responseData['errcode']} - $errorMsg');
          _accessToken = null;
          _refreshToken = null;
          _tokenExpiry = null;
          throw Exception('API Error ${responseData['errcode']}: $errorMsg');
        }
        
        _accessToken = responseData['access_token'];
        _refreshToken = responseData['refresh_token'];
        
        if (_accessToken == null) {
          print('ERROR: access_token is null in response');
          print('Full response: $responseData');
          throw Exception('No access_token in response: ${response.body}');
        }
        
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
        'redirect_uri': ApiConfig.redirectUri,
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

  Future<List<Map<String, dynamic>>> getLockList() async {
    print('Fetching lock list from API...');
    // Ensure we have a valid token
    await getAccessToken();

    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$_baseUrl/v3/lock/list').replace(queryParameters: {
      'clientId': ApiConfig.clientId,
      'accessToken': _accessToken,
      'pageNo': '1',
      'pageSize': '100',
      'date': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['list'] != null) {
        final List<dynamic> locksFromApi = responseData['list'];
        print('Successfully fetched ${locksFromApi.length} locks.');

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
      print('Response: ${response.body}');
      throw Exception('Failed to get lock list');
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
      if (responseData['errcode'] == 0) {
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
      if (responseData['errcode'] == 0) {
        print('TTLock webhook URL başarıyla ayarlandı: $callbackUrl');
        return responseData;
      } else {
        throw Exception('TTLock webhook ayarlama hatası: ${responseData['errmsg']}');
      }
    } else {
      throw Exception('TTLock webhook HTTP hatası: ${response.statusCode}');
    }
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
      if (responseData['errcode'] == 0) {
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

