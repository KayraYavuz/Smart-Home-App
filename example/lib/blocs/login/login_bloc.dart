import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_event.dart';
import 'package:yavuz_lock/blocs/login/login_event.dart';
import 'package:yavuz_lock/blocs/login/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService _apiService;
  final AuthBloc _authBloc;

  LoginBloc(this._apiService, this._authBloc) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  void _onLoginButtonPressed(
      LoginButtonPressed event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      // Pass username and password from the event to ApiService
      final success = await _apiService.getAccessToken(
        username: event.username,
        password: event.password,
      );
      if (success) {
        final accessToken = _apiService.accessToken;
        if (accessToken != null) {
          _authBloc.add(LoggedIn(accessToken));
          emit(LoginSuccess());
        } else {
          emit(const LoginFailure('Giriş başarılı ancak anahtar alınamadı.'));
        }
      } else {
        // success false ise ApiService genellikle hata fırlatmış olmalı,
        // ama fırlatmadıysa genel bir mesaj gösterelim.
        emit(const LoginFailure('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'));
      }
    } catch (e) {
      // API'den gelen asıl hatayı kullanıcıya göster (Örn: "API Error 10007")
      print('Login Error: $e');
      emit(LoginFailure(e.toString().replaceAll('Exception: ', '')));
    }

  }
}
