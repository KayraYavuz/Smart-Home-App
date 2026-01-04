import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/blocs/lock/lock_event.dart';
import 'package:ttlock_flutter_example/blocs/lock/app_lock_state.dart';

class LockBloc extends Bloc<LockEvent, AppLockState> {
  final ApiService _apiService;
  final String? _accessToken;

  LockBloc(this._apiService, {String? accessToken}) : _accessToken = accessToken, super(LockInitial()) {
    on<FetchLocks>(_onFetchLocks);
  }

  void _onFetchLocks(FetchLocks event, Emitter<AppLockState> emit) async {
    emit(LockLoading());
    try {
      if (_accessToken != null) {
        _apiService.setAccessToken(_accessToken);
      }
      final locks = await _apiService.getLockList();
      emit(LockLoaded(locks));
    } catch (e) {
      emit(LockFailure(e.toString()));
    }
  }
}
