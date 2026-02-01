import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/config.dart';

/// Service that handles hybrid unlocking: tries Bluetooth first, falls back to Gateway API
class HybridUnlockService {
  final ApiService _apiService;
  static const String _baseUrl = 'https://euapi.ttlock.com';
  static const int _bluetoothTimeoutSeconds = 10;

  HybridUnlockService(this._apiService);

  /// Unlock the lock using TTLock approach: Bluetooth first, then Gateway API (optional)
  /// Returns true if successful, false otherwise
  Future<UnlockResult> unlock({
    required String lockData,
    required String lockMac,
    String? lockId,
    bool onlyBluetooth = false,
  }) async {
    // First, try Bluetooth unlock
    print('Attempting Bluetooth unlock for lock: $lockMac');
    final bluetoothResult = await _tryBluetoothUnlock(lockData, lockMac);

    if (bluetoothResult.success) {
      print('Bluetooth unlock successful');
      return bluetoothResult;
    }

    if (onlyBluetooth) {
      print('Bluetooth unlock failed and fallback is disabled.');
      return UnlockResult(
        success: false,
        error: bluetoothResult.error ?? 'Bluetooth unlock failed',
        method: 'bluetooth',
      );
    }

    // If Bluetooth fails, try Gateway API unlock
    print('Bluetooth unlock failed: ${bluetoothResult.error}. Trying Gateway API...');
    if (lockId != null) {
      final gatewayResult = await _tryGatewayUnlock(lockId);
      if (gatewayResult.success) {
        print('Gateway API unlock successful');
        return gatewayResult;
      }
    }

    // All methods failed
    print('All unlock methods failed');
    return UnlockResult(
      success: false,
      error: bluetoothResult.error ?? 'Unlock failed via all methods',
      method: 'none',
    );
  }

  /// Lock the lock using TTLock approach: Bluetooth first, then Gateway API (optional)
  Future<UnlockResult> lock({
    required String lockData,
    required String lockMac,
    String? lockId,
    bool onlyBluetooth = false,
  }) async {
    print('Attempting Bluetooth lock for lock: $lockMac');
    final bluetoothResult = await _tryBluetoothLock(lockData, lockMac);

    if (bluetoothResult.success) {
      return bluetoothResult;
    }

    if (onlyBluetooth) {
       return UnlockResult(
        success: false,
        error: bluetoothResult.error ?? 'Bluetooth lock failed',
        method: 'bluetooth',
      );
    }

    // If Bluetooth fails, try Gateway API lock
    if (lockId != null) {
      final gatewayResult = await _tryGatewayLock(lockId);
      if (gatewayResult.success) {
        return gatewayResult;
      }
    }

    return UnlockResult(
      success: false,
      error: bluetoothResult.error ?? 'Lock failed via all methods',
      method: 'none',
    );
  }


  /// Try to unlock via Bluetooth
  Future<UnlockResult> _tryBluetoothUnlock(String lockData, String lockMac) async {
    // 1. Bluetooth durum kontrolü
    final Completer<bool> btCheckCompleter = Completer();
    TTLock.getBluetoothState((state) {
      btCheckCompleter.complete(state == TTBluetoothState.turnOn); // 1: PowerOn, 2: PoweredOn
    });
    
    final bool isBtEnabled = await btCheckCompleter.future.timeout(const Duration(seconds: 2), onTimeout: () => false);
    
    if (!isBtEnabled) {
      return UnlockResult(
        success: false,
        error: 'BLUETOOTH_OFF',
        method: 'bluetooth',
      );
    }

    print('📡 Kilide bağlanılıyor (BT)... Lütfen kilidi uyandırmak için tuş takımına dokunun.');

    try {
      final completer = Completer<UnlockResult>();
      
      TTLock.controlLock(
        lockData,
        TTControlAction.unlock,
        (lockTime, electricQuantity, uniqueId, updatedLockData) {
          if (!completer.isCompleted) {
            completer.complete(UnlockResult(
              success: true,
              method: 'bluetooth',
              lockTime: lockTime,
              battery: electricQuantity,
              uniqueId: uniqueId.toString(),
            ));
          }
        },
        (errorCode, errorMsg) {
          if (!completer.isCompleted) {
            print('❌ TTLock BT Hata Kodu: $errorCode - Mesaj: $errorMsg');
            // TTLock hata kodlarına göre mesaj belirle
            String errorType = _getBluetoothErrorType(errorCode, errorMsg);
            completer.complete(UnlockResult(
              success: false,
              error: errorType,
              method: 'bluetooth',
            ));
          }
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: _bluetoothTimeoutSeconds),
        onTimeout: () {
          print('⏳ Bluetooth bağlantı zaman aşımı. Kilit uyuyor olabilir.');
          return UnlockResult(
            success: false,
            error: 'LOCK_OUT_OF_RANGE',
            method: 'bluetooth',
          );
        },
      );
    } catch (e) {
      print('❌ Bluetooth istisnası: $e');
      return UnlockResult(
        success: false,
        error: 'CONNECTION_FAILED:$e',
        method: 'bluetooth',
      );
    }
  }

  /// Try to lock via Bluetooth
  Future<UnlockResult> _tryBluetoothLock(String lockData, String lockMac) async {
    // 1. Bluetooth durum kontrolü
    final Completer<bool> btCheckCompleter = Completer();
    TTLock.getBluetoothState((state) {
      btCheckCompleter.complete(state == TTBluetoothState.turnOn); // 1: PowerOn, 2: PoweredOn
    });
    
    final bool isBtEnabled = await btCheckCompleter.future.timeout(const Duration(seconds: 2), onTimeout: () => false);
    
    if (!isBtEnabled) {
      return UnlockResult(
        success: false,
        error: 'BLUETOOTH_OFF',
        method: 'bluetooth',
      );
    }

    print('📡 Kilide bağlanılıyor (BT)... Lütfen kilidi uyandırmak için tuş takımına dokunun.');

    try {
      final completer = Completer<UnlockResult>();
      
      TTLock.controlLock(
        lockData,
        TTControlAction.lock,
        (lockTime, electricQuantity, uniqueId, updatedLockData) {
          if (!completer.isCompleted) {
            completer.complete(UnlockResult(
              success: true,
              method: 'bluetooth',
              lockTime: lockTime,
              battery: electricQuantity,
              uniqueId: uniqueId.toString(),
            ));
          }
        },
        (errorCode, errorMsg) {
          if (!completer.isCompleted) {
            print('❌ TTLock BT Hata Kodu: $errorCode - Mesaj: $errorMsg');
            String errorType = _getBluetoothErrorType(errorCode, errorMsg);
            completer.complete(UnlockResult(
              success: false,
              error: errorType,
              method: 'bluetooth',
            ));
          }
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: _bluetoothTimeoutSeconds),
        onTimeout: () {
          print('⏳ Bluetooth bağlantı zaman aşımı. Kilit uyuyor olabilir.');
          return UnlockResult(
            success: false,
            error: 'LOCK_OUT_OF_RANGE',
            method: 'bluetooth',
          );
        },
      );
    } catch (e) {
      print('❌ Bluetooth istisnası: $e');
      return UnlockResult(
        success: false,
        error: 'CONNECTION_FAILED:$e',
        method: 'bluetooth',
      );
    }
  }

  /// TTLock hata kodlarına göre hata tipi belirle
  String _getBluetoothErrorType(dynamic errorCode, String errorMsg) {
    final errorMsgLower = errorMsg.toLowerCase();
    
    // Bluetooth durumu hataları
    if (errorMsgLower.contains('bluetooth') && 
        (errorMsgLower.contains('off') || errorMsgLower.contains('disabled') || errorMsgLower.contains('kapalı'))) {
      return 'BLUETOOTH_OFF';
    }
    
    // Bağlantı/aralık hataları
    if (errorMsgLower.contains('connect') || 
        errorMsgLower.contains('timeout') || 
        errorMsgLower.contains('not found') ||
        errorMsgLower.contains('out of range') ||
        errorMsgLower.contains('fail')) {
      return 'LOCK_OUT_OF_RANGE';
    }
    
    // Diğer hatalar için genel bağlantı hatası
    return 'CONNECTION_FAILED:$errorMsg';
  }

  /// Try to unlock via Gateway API
  Future<UnlockResult> _tryGatewayUnlock(String lockId) async {
    try {
      // Ensure we have a valid access token
      await _apiService.getAccessToken();
      final accessToken = _apiService.accessToken;
      
      if (accessToken == null) {
        return UnlockResult(
          success: false,
          error: 'No access token available',
          method: 'gateway',
        );
      }

      final url = Uri.parse('$_baseUrl/v3/lock/unlock').replace(queryParameters: {
        'clientId': ApiConfig.clientId,
        'accessToken': accessToken,
        'lockId': lockId.toString(),
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['errcode'] == 0) {
          return UnlockResult(
            success: true,
            method: 'gateway',
          );
        } else {
          return UnlockResult(
            success: false,
            error: 'Gateway API error: ${responseData['errmsg'] ?? 'Unknown error'}',
            method: 'gateway',
          );
        }
      } else {
        return UnlockResult(
          success: false,
          error: 'Gateway API HTTP error: ${response.statusCode}',
          method: 'gateway',
        );
      }
    } catch (e) {
      return UnlockResult(
        success: false,
        error: 'Gateway API exception: $e',
        method: 'gateway',
      );
    }
  }

  /// Try to lock via Gateway API
  Future<UnlockResult> _tryGatewayLock(String lockId) async {
    try {
      await _apiService.getAccessToken();
      final accessToken = _apiService.accessToken;
      
      if (accessToken == null) {
        return UnlockResult(
          success: false,
          error: 'No access token available',
          method: 'gateway',
        );
      }

      final url = Uri.parse('$_baseUrl/v3/lock/lock').replace(queryParameters: {
        'clientId': ApiConfig.clientId,
        'accessToken': accessToken,
        'lockId': lockId.toString(),
        'date': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['errcode'] == 0) {
          return UnlockResult(
            success: true,
            method: 'gateway',
          );
        } else {
          return UnlockResult(
            success: false,
            error: 'Gateway API error: ${responseData['errmsg'] ?? 'Unknown error'}',
            method: 'gateway',
          );
        }
      } else {
        return UnlockResult(
          success: false,
          error: 'Gateway API HTTP error: ${response.statusCode}',
          method: 'gateway',
        );
      }
    } catch (e) {
      return UnlockResult(
        success: false,
        error: 'Gateway API exception: $e',
        method: 'gateway',
      );
    }
  }
}

/// Result of unlock/lock operation
class UnlockResult {
  final bool success;
  final String? error;
  final String method; // 'bluetooth', 'gateway', or 'none'
  final int? lockTime;
  final int? battery;
  final String? uniqueId;

  UnlockResult({
    required this.success,
    this.error,
    required this.method,
    this.lockTime,
    this.battery,
    this.uniqueId,
  });
}

