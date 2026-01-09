import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter_example/blocs/device/device_event.dart';
import 'package:ttlock_flutter_example/blocs/device/device_state.dart';
import 'package:ttlock_flutter_example/services/hybrid_unlock_service.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final HybridUnlockService _unlockService;

  DeviceBloc() 
      : _unlockService = HybridUnlockService(ApiService(AuthRepository())),
        super(DeviceInitial()) {
    on<UnlockDevice>(_onUnlockDevice);
    on<LockDevice>(_onLockDevice);
  }

  void _onUnlockDevice(UnlockDevice event, Emitter<DeviceState> emit) async {
    emit(DeviceLoading());
    try {
      final String lockData = event.lock['lockData'] ?? '';
      final String lockMac = event.lock['lockMac'] ?? '';
      final String? lockId = event.lock['lockId']?.toString();

      final result = await _unlockService.unlock(
        lockData: lockData,
        lockMac: lockMac,
        lockId: lockId,
      );

      if (result.success) {
        emit(DeviceSuccess(
          method: result.method,
          battery: result.battery,
          newLockState: false, // Açma işlemi başarılı, kilit artık açık
        ));
      } else {
        emit(DeviceFailure(result.error ?? 'Unlock failed'));
      }
    } catch (e) {
      emit(DeviceFailure(e.toString()));
    }
  }

  void _onLockDevice(LockDevice event, Emitter<DeviceState> emit) async {
    emit(DeviceLoading());
    try {
      final String lockData = event.lock['lockData'] ?? '';
      final String lockMac = event.lock['lockMac'] ?? '';
      final String? lockId = event.lock['lockId']?.toString();

      final result = await _unlockService.lock(
        lockData: lockData,
        lockMac: lockMac,
        lockId: lockId,
      );

      if (result.success) {
        emit(DeviceSuccess(
          method: result.method,
          battery: result.battery,
          newLockState: true, // Kilitleme işlemi başarılı, kilit artık kilitli
        ));
      } else {
        emit(DeviceFailure(result.error ?? 'Lock failed'));
      }
    } catch (e) {
      emit(DeviceFailure(e.toString()));
    }
  }
}
