import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:equatable/equatable.dart';

part 'face_event.dart';
part 'face_state.dart';

class FaceBloc extends Bloc<FaceEvent, FaceState> {
  final TTLockRepository _ttlockRepository;
  final ApiService _apiService;

  FaceBloc(this._ttlockRepository, this._apiService) : super(FaceInitial()) {
    on<LoadFaces>(_onLoadFaces);
    on<AddFace>(_onAddFace);
    on<DeleteFace>(_onDeleteFace);
    on<ClearAllFaces>(_onClearAllFaces);
    on<ChangeFacePeriod>(_onChangeFacePeriod);
    on<RenameFace>(_onRenameFace);
  }

  Future<void> _onLoadFaces(
      LoadFaces event, Emitter<FaceState> emit) async {
    emit(FaceLoading());
    try {
      await _apiService.getAccessToken();
      final faces = await _ttlockRepository.getFaceList(lockId: event.lockId);
      emit(FacesLoaded(faces['list']));
    } catch (e) {
      emit(FaceOperationFailure(e.toString()));
    }
  }

  Future<void> _onAddFace(
      AddFace event, Emitter<FaceState> emit) async {
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.addFace(
        lockId: event.lockId,
        featureData: event.featureData,
        addType: event.addType,
        name: event.name,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(FaceOperationSuccess());
    } catch (e) {
      emit(FaceOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteFace(
      DeleteFace event, Emitter<FaceState> emit) async {
    try {
      await _apiService.getAccessToken();
      // For remote deletion via gateway, type should be 2
      await _ttlockRepository.deleteFace(lockId: event.lockId, faceId: event.faceId, type: 2);
      emit(FaceOperationSuccess());
    } catch (e) {
      emit(FaceOperationFailure(e.toString()));
    }
  }

  Future<void> _onClearAllFaces(
      ClearAllFaces event, Emitter<FaceState> emit) async {
    emit(FaceLoading());
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.clearAllFaces(lockId: event.lockId);
      emit(FaceOperationSuccess());
    } catch (e) {
      emit(FaceOperationFailure(e.toString()));
    }
  }

  Future<void> _onChangeFacePeriod(
      ChangeFacePeriod event, Emitter<FaceState> emit) async {
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.changeFacePeriod(
        lockId: event.lockId,
        faceId: event.faceId,
        startDate: event.startDate,
        endDate: event.endDate,
        type: 2, // Remote change via gateway
      );
      emit(FaceOperationSuccess());
    } catch (e) {
      emit(FaceOperationFailure(e.toString()));
    }
  }

  Future<void> _onRenameFace(
      RenameFace event, Emitter<FaceState> emit) async {
    try {
      await _apiService.getAccessToken();
      await _ttlockRepository.renameFace(
        lockId: event.lockId,
        faceId: event.faceId,
        name: event.name,
      );
      emit(FaceOperationSuccess());
    } catch (e) {
      emit(FaceOperationFailure(e.toString()));
    }
  }
}
