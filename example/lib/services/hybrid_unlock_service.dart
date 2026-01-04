import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttlock_flutter/ttlock.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/config.dart';

/// Service that handles hybrid unlocking: tries Bluetooth first, falls back to Gateway API
class HybridUnlockService {
  final ApiService _apiService;
  static const String _baseUrl = 'https://euapi.ttlock.com';
  static const int _bluetoothTimeoutSeconds = 10;

  HybridUnlockService(this._apiService);

  /// Unlock the lock using hybrid approach: Seam API first for Seam devices, then Bluetooth + Gateway
  /// Returns true if successful, false otherwise
  Future<UnlockResult> unlock({
    required String lockData,
    required String lockMac,
    String? lockId,
    String? seamDeviceId,
  }) async {
    // Check if this is a Seam device
    if (seamDeviceId != null && seamDeviceId.isNotEmpty) {
      print('Detected Seam device, attempting Seam API unlock: $seamDeviceId');
      final seamResult = await _trySeamUnlock(seamDeviceId);
      if (seamResult.success) {
        print('Seam API unlock successful');
        return seamResult;
      }
      print('Seam API unlock failed: ${seamResult.error}');
    }

    // For non-Seam devices, use traditional TTLock methods
    // First, try Bluetooth unlock
    print('Attempting Bluetooth unlock for lock: $lockMac');
    final bluetoothResult = await _tryBluetoothUnlock(lockData, lockMac);

    if (bluetoothResult.success) {
      print('Bluetooth unlock successful');
      return bluetoothResult;
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

  /// Lock the lock using hybrid approach: Seam API first for Seam devices, then Bluetooth + Gateway
  Future<UnlockResult> lock({
    required String lockData,
    required String lockMac,
    String? lockId,
    String? seamDeviceId,
  }) async {
    // Check if this is a Seam device
    if (seamDeviceId != null && seamDeviceId.isNotEmpty) {
      print('Detected Seam device, attempting Seam API lock: $seamDeviceId');
      final seamResult = await _trySeamLock(seamDeviceId);
      if (seamResult.success) {
        print('Seam API lock successful');
        return seamResult;
      }
      print('Seam API lock failed: ${seamResult.error}');
    }

    // For non-Seam devices, use traditional TTLock methods
    print('Attempting Bluetooth lock for lock: $lockMac');
    final bluetoothResult = await _tryBluetoothLock(lockData, lockMac);

    if (bluetoothResult.success) {
      return bluetoothResult;
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

  /// Try to unlock via Seam API
  Future<UnlockResult> _trySeamUnlock(String seamDeviceId) async {
    try {
      final url = Uri.parse('${SeamConfig.baseUrl}/devices/$seamDeviceId/unlock_door');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${SeamConfig.seamApiKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final actionResult = responseData['action_attempt'] ?? {};

        if (actionResult['status'] == 'success' || actionResult['status'] == 'pending') {
          return UnlockResult(
            success: true,
            method: 'seam_api',
          );
        } else {
          return UnlockResult(
            success: false,
            error: 'Seam API unlock failed: ${actionResult['error'] ?? 'Unknown error'}',
            method: 'seam_api',
          );
        }
      } else {
        return UnlockResult(
          success: false,
          error: 'Seam API HTTP error: ${response.statusCode}',
          method: 'seam_api',
        );
      }
    } catch (e) {
      return UnlockResult(
        success: false,
        error: 'Seam API exception: $e',
        method: 'seam_api',
      );
    }
  }

  /// Try to lock via Seam API
  Future<UnlockResult> _trySeamLock(String seamDeviceId) async {
    try {
      final url = Uri.parse('${SeamConfig.baseUrl}/devices/$seamDeviceId/lock_door');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${SeamConfig.seamApiKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final actionResult = responseData['action_attempt'] ?? {};

        if (actionResult['status'] == 'success' || actionResult['status'] == 'pending') {
          return UnlockResult(
            success: true,
            method: 'seam_api',
          );
        } else {
          return UnlockResult(
            success: false,
            error: 'Seam API lock failed: ${actionResult['error'] ?? 'Unknown error'}',
            method: 'seam_api',
          );
        }
      } else {
        return UnlockResult(
          success: false,
          error: 'Seam API HTTP error: ${response.statusCode}',
          method: 'seam_api',
        );
      }
    } catch (e) {
      return UnlockResult(
        success: false,
        error: 'Seam API exception: $e',
        method: 'seam_api',
      );
    }
  }

  /// Try to unlock via Bluetooth
  Future<UnlockResult> _tryBluetoothUnlock(String lockData, String lockMac) async {
    try {
      // Use a completer to handle async callback
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
            completer.complete(UnlockResult(
              success: false,
              error: 'Bluetooth error: $errorCode - $errorMsg',
              method: 'bluetooth',
            ));
          }
        },
      );

      // Wait for result with timeout
      return await completer.future.timeout(
        Duration(seconds: _bluetoothTimeoutSeconds),
        onTimeout: () {
          return UnlockResult(
            success: false,
            error: 'Bluetooth unlock timeout',
            method: 'bluetooth',
          );
        },
      );
    } catch (e) {
      return UnlockResult(
        success: false,
        error: 'Bluetooth exception: $e',
        method: 'bluetooth',
      );
    }
  }

  /// Try to lock via Bluetooth
  Future<UnlockResult> _tryBluetoothLock(String lockData, String lockMac) async {
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
            completer.complete(UnlockResult(
              success: false,
              error: 'Bluetooth error: $errorCode - $errorMsg',
              method: 'bluetooth',
            ));
          }
        },
      );

      return await completer.future.timeout(
        Duration(seconds: _bluetoothTimeoutSeconds),
        onTimeout: () {
          return UnlockResult(
            success: false,
            error: 'Bluetooth lock timeout',
            method: 'bluetooth',
          );
        },
      );
    } catch (e) {
      return UnlockResult(
        success: false,
        error: 'Bluetooth exception: $e',
        method: 'bluetooth',
      );
    }
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

