import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:yavuz_lock/services/passcode_model.dart';
import 'package:equatable/equatable.dart';

part 'passcode_state.dart';

class PasscodeCubit extends Cubit<PasscodeState> {
  final TTLockRepository _repository;

  PasscodeCubit(this._repository) : super(PasscodeInitial());

  Future<void> fetchPasscodes(
      int lockId, String clientId, String accessToken) async {
    try {
      emit(PasscodeLoading());
      final passcodes = await _repository.getPasscodes(
        clientId: clientId,
        accessToken: accessToken,
        lockId: lockId,
      );
      emit(PasscodeLoadSuccess(passcodes));
    } catch (e) {
      emit(PasscodeLoadFailure("Failed to load passcodes: $e"));
    }
  }

  Future<void> deletePasscode({
    required int lockId,
    required int keyboardPwdId,
    required String clientId,
    required String accessToken,
  }) async {
    try {
      final success = await _repository.deletePasscode(
        clientId: clientId,
        accessToken: accessToken,
        lockId: lockId,
        keyboardPwdId: keyboardPwdId,
      );
      if (success) {
        await fetchPasscodes(lockId, clientId, accessToken);
      } else {
        emit(PasscodeLoadFailure("Failed to delete passcode"));
      }
    } catch (e) {
      emit(PasscodeLoadFailure("Failed to delete passcode: $e"));
    }
  }
}
