import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_event.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_state.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';

class FingerprintBloc extends Bloc<FingerprintEvent, FingerprintState> {
  final TTLockRepository _ttlockRepository;
  final ApiService _apiService;

  FingerprintBloc(this._ttlockRepository, this._apiService)
      : super(FingerprintInitial()) {
    on<LoadFingerprints>(_onLoadFingerprints);
    on<AddFingerprint>(_onAddFingerprint);
    on<DeleteFingerprint>(_onDeleteFingerprint);
    on<ChangeFingerprintPeriod>(_onChangeFingerprintPeriod);
    on<ClearAllFingerprints>(_onClearAllFingerprints);
    on<RenameFingerprint>(_onRenameFingerprint);
  }

  Future<String> _getToken() async {
    final ok = await _apiService.getAccessToken();
    final token = _apiService.accessToken;
    if (!ok || token == null) throw Exception('Not authenticated');
    return token;
  }

  Future<void> _onLoadFingerprints(
      LoadFingerprints event, Emitter<FingerprintState> emit) async {
    emit(FingerprintLoading());
    try {
      final token = await _getToken();
      final fingerprints =
          await _ttlockRepository.getFingerprintList(token, event.lockId);
      emit(FingerprintsLoaded(fingerprints['list']));
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddFingerprint(
      AddFingerprint event, Emitter<FingerprintState> emit) async {
    try {
      final token = await _getToken();
      await _ttlockRepository.addFingerprint(
        accessToken: token,
        lockId: event.lockId,
        fingerprintNumber: event.fingerprintNumber,
        fingerprintName: event.fingerprintName,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteFingerprint(
      DeleteFingerprint event, Emitter<FingerprintState> emit) async {
    try {
      final token = await _getToken();
      await _ttlockRepository.deleteFingerprint(
          token, event.lockId, event.fingerprintId);
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onChangeFingerprintPeriod(
      ChangeFingerprintPeriod event, Emitter<FingerprintState> emit) async {
    try {
      final token = await _getToken();
      await _ttlockRepository.changeFingerprintPeriod(
        accessToken: token,
        lockId: event.lockId,
        fingerprintId: event.fingerprintId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onClearAllFingerprints(
      ClearAllFingerprints event, Emitter<FingerprintState> emit) async {
    try {
      final token = await _getToken();
      await _ttlockRepository.clearAllFingerprints(token, event.lockId);
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onRenameFingerprint(
      RenameFingerprint event, Emitter<FingerprintState> emit) async {
    try {
      final token = await _getToken();
      await _ttlockRepository.renameFingerprint(
        accessToken: token,
        lockId: event.lockId,
        fingerprintId: event.fingerprintId,
        fingerprintName: event.fingerprintName,
      );
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }
}
