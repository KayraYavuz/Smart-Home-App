import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_event.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_state.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Check if we have a valid token in storage
      final isValid = await _authRepository.isTokenValid();
      if (isValid) {
        final accessToken = await _authRepository.getAccessToken();
        if (accessToken != null) {
          emit(Authenticated(accessToken));
          return;
        }
      }
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Tokens are already saved by ApiService, just emit authenticated state
      emit(Authenticated(event.accessToken));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.deleteTokens();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
