import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/lock/lock_event.dart';
import 'package:yavuz_lock/blocs/lock/app_lock_state.dart';

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
      
      List<Map<String, dynamic>> gateways = [];
      try {
        final gatewayResponse = await _apiService.getGatewayList();
        gateways = List<Map<String, dynamic>>.from(gatewayResponse['list'] ?? []);
      } catch (e) {
        // Log the error but don't fail the whole fetch
        print('Error fetching gateways: $e');
      }

      emit(LockLoaded(locks, gateways: gateways));
    } catch (e) {
      emit(LockFailure(e.toString()));
    }
  }
}
