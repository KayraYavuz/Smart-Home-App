import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_event.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_state.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';

class FingerprintBloc extends Bloc<FingerprintEvent, FingerprintState> {
  final TTLockRepository _ttlockRepository;
  final ApiService _apiService;

  FingerprintBloc(this._ttlockRepository, this._apiService) : super(FingerprintInitial()) {
    on<LoadFingerprints>(_onLoadFingerprints);
    on<AddFingerprint>(_onAddFingerprint);
    on<DeleteFingerprint>(_onDeleteFingerprint);
    on<ChangeFingerprintPeriod>(_onChangeFingerprintPeriod);
    on<ClearAllFingerprints>(_onClearAllFingerprints);
    on<RenameFingerprint>(_onRenameFingerprint);
  }

  Future<void> _onLoadFingerprints(
      LoadFingerprints event, Emitter<FingerprintState> emit) async {
    emit(FingerprintLoading());
    try {
      await _apiService.getAccessToken();
      final fingerprints = await _ttlockRepository.getFingerprintList(
          _apiService.accessToken!, event.lockId);
      emit(FingerprintsLoaded(fingerprints['list']));
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddFingerprint(
      AddFingerprint event, Emitter<FingerprintState> emit) async {
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.addFingerprint(
        accessToken: _apiService.accessToken!,
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
      await _apiService.getAccessToken();
      await _ttlockRepository.deleteFingerprint(
          _apiService.accessToken!, event.lockId, event.fingerprintId);
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onChangeFingerprintPeriod(
      ChangeFingerprintPeriod event, Emitter<FingerprintState> emit) async {
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.changeFingerprintPeriod(
        accessToken: _apiService.accessToken!,
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
      await _apiService.getAccessToken();
      await _ttlockRepository.clearAllFingerprints(
          _apiService.accessToken!, event.lockId);
      emit(FingerprintOperationSuccess());
    } catch (e) {
      emit(FingerprintOperationFailure(e.toString()));
    }
  }

  Future<void> _onRenameFingerprint(
      RenameFingerprint event, Emitter<FingerprintState> emit) async {
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.renameFingerprint(
        accessToken: _apiService.accessToken!,
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
