import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:yavuz_lock/services/passcode_model.dart';
import 'package:equatable/equatable.dart';

part 'passcode_state.dart';

class PasscodeCubit extends Cubit<PasscodeState> {
  final TTLockRepository _repository;

  PasscodeCubit(this._repository) : super(PasscodeInitial());

  Future<void> fetchPasscodes(int lockId, String clientId, String accessToken) async {
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
}
