import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/services/passcode_model.dart';
import 'package:yavuz_lock/services/ttlock_service.dart';

class TTLockRepository {
  final TTLockService _ttlockService;
  final ApiService _apiService;

  // TTLockService'i dışarıdan alarak bağımlılığı azaltıyoruz (Dependency Injection)
  TTLockRepository({TTLockService? ttlockService, required ApiService apiService})
      : _ttlockService = ttlockService ?? TTLockService(),
        _apiService = apiService;

  // --- FACE MANAGEMENT ---

  Future<Map<String, dynamic>> getFeatureDataByPhoto({
    required int lockId,
    required String imagePath,
  }) {
    return _apiService.getFeatureDataByPhoto(
      lockId: lockId,
      imagePath: imagePath,
    );
  }

  Future<Map<String, dynamic>> addFace({
    required int lockId,
    required String featureData,
    required int addType,
    String? name,
    String? faceNumber,
    int? startDate,
    int? endDate,
    int type = 1,
    List<Map<String, dynamic>>? cyclicConfig,
  }) {
    return _apiService.addFace(
      lockId: lockId,
      featureData: featureData,
      addType: addType,
      name: name,
      faceNumber: faceNumber,
      startDate: startDate,
      endDate: endDate,
      type: type,
      cyclicConfig: cyclicConfig,
    );
  }

  Future<Map<String, dynamic>> getFaceList({
    required int lockId,
    int pageNo = 1,
    int pageSize = 20,
    String? searchStr,
  }) {
    return _apiService.getFaceList(
      lockId: lockId,
      pageNo: pageNo,
      pageSize: pageSize,
      searchStr: searchStr,
    );
  }

  Future<void> deleteFace({
    required int lockId,
    required int faceId,
    required int type,
  }) {
    return _apiService.deleteFace(
      lockId: lockId,
      faceId: faceId,
      type: type,
    );
  }

  /// Change the period of validity of face data
  Future<void> changeFacePeriod({
    required int lockId,
    required int faceId,
    required int startDate,
    required int endDate,
    int type = 2,
    List<Map<String, dynamic>>? cyclicConfig,
  }) {
    return _apiService.changeFacePeriod(
      lockId: lockId,
      faceId: faceId,
      startDate: startDate,
      endDate: endDate,
      type: type,
      cyclicConfig: cyclicConfig,
    );
  }

  /// Clear all face data from the cloud server
  Future<void> clearAllFaces({
    required int lockId,
  }) {
    return _apiService.clearAllFaces(
      lockId: lockId,
    );
  }

  /// Modify the face name
  Future<void> renameFace({
    required int lockId,
    required int faceId,
    required String name,
  }) {
    return _apiService.renameFace(
      lockId: lockId,
      faceId: faceId,
      name: name,
    );
  }

  /// API'den gelen verileri veya hataları iş mantığı katmanına (BLoC) hazırlar.
  Future<List<Passcode>> getPasscodes({
    required String clientId,
    required String accessToken,
    required int lockId,
  }) {
    // Burada gelecekte önbellekleme (caching) gibi mantıklar da eklenebilir.
    return _ttlockService.getPasscodes(
      clientId: clientId,
      accessToken: accessToken,
      lockId: lockId,
    );
  }

  /// Yeni bir özel şifre ekler.
  Future<int?> addCustomPasscode({
    required String clientId,
    required String accessToken,
    required int lockId,
    required String keyboardPwd,
    required String keyboardPwdName,
  }) {
    return _ttlockService.addCustomPasscode(
      clientId: clientId,
      accessToken: accessToken,
      lockId: lockId,
      keyboardPwd: keyboardPwd,
      keyboardPwdName: keyboardPwdName,
    );
  }
  
  /// Bir şifreyi siler.
  Future<bool> deletePasscode({
    required String clientId,
    required String accessToken,
    required int lockId,
    required int keyboardPwdId,
  }) {
    return _ttlockService.deletePasscode(
      clientId: clientId,
      accessToken: accessToken,
      lockId: lockId,
      keyboardPwdId: keyboardPwdId,
    );
  }

  /// Bir şifreyi değiştirir.
  Future<bool> changePasscode({
    required String clientId,
    required String accessToken,
    required int lockId,
    required int keyboardPwdId,
    String? newKeyboardPwd,
    String? keyboardPwdName,
  }) {
    return _ttlockService.changePasscode(
      clientId: clientId,
      accessToken: accessToken,
      lockId: lockId,
      keyboardPwdId: keyboardPwdId,
      newKeyboardPwd: newKeyboardPwd,
      keyboardPwdName: keyboardPwdName,
    );
  }

  /// Get the fingerprint list of a lock
  Future<Map<String, dynamic>> getFingerprintList(String accessToken, int lockId) {
    return _ttlockService.getFingerprintList(
        accessToken: accessToken, lockId: lockId);
  }

  /// Add a fingerprint to the cloud
  Future<void> addFingerprint({
    required String accessToken,
    required int lockId,
    required String fingerprintNumber,
    required String fingerprintName,
    required int startDate,
    required int endDate,
  }) {
    return _ttlockService.addFingerprint(
      accessToken: accessToken,
      lockId: lockId,
      fingerprintNumber: fingerprintNumber,
      fingerprintName: fingerprintName,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Delete a fingerprint
  Future<void> deleteFingerprint(
      String accessToken, int lockId, int fingerprintId) {
    return _ttlockService.deleteFingerprint(
        accessToken: accessToken, lockId: lockId, fingerprintId: fingerprintId);
  }

  Future<void> changeFingerprintPeriod({
    required String accessToken,
    required int lockId,
    required int fingerprintId,
    required int startDate,
    required int endDate,
  }) {
    return _ttlockService.changeFingerprintPeriod(
      accessToken: accessToken,
      lockId: lockId,
      fingerprintId: fingerprintId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> clearAllFingerprints(String accessToken, int lockId) {
    return _ttlockService.clearAllFingerprints(
        accessToken: accessToken, lockId: lockId);
  }

  Future<void> renameFingerprint({
    required String accessToken,
    required int lockId,
    required int fingerprintId,
    required String fingerprintName,
  }) {
    return _ttlockService.renameFingerprint(
      accessToken: accessToken,
      lockId: lockId,
      fingerprintId: fingerprintId,
      fingerprintName: fingerprintName,
    );
  }
}
