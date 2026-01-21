import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    
    bool firebaseSuccess = false;
    bool ttlockSuccess = false;
    String loginErrorMsg = '';

    // 1. Firebase Girişi Dene
    User? firebaseUser;
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: event.username.trim(), 
        password: event.password
      );
      firebaseSuccess = true;
      firebaseUser = credential.user;
      print('✅ Firebase login successful');
    } on FirebaseAuthException catch (e) {
      print('Firebase Login Failed: ${e.code} - ${e.message}');
      // Eğer şifre yanlışsa veya kullanıcı adı hatalıysa (ve kullanıcı Firebase'de varsa)
      // TTLock girişine devam etme, çünkü şifre senkronize olmalı.
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
         emit(const LoginFailure('Hatalı şifre. Lütfen bilgilerinizi kontrol edin.'));
         return;
      }
      // Diğer hatalarda (örn: kullanıcı Firebase'de yoksa) TTLock ile devam et (Legacy support)
    } catch (e) {
      print('Firebase Unknown Error: $e');
    }

    // TTLock kullanıcı adını belirle
    // Eğer Firebase'de kayıtlı displayName varsa onu kullan (Prefixli username)
    String ttlockUsernameToTry = event.username;
    if (firebaseUser != null && firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
       ttlockUsernameToTry = firebaseUser.displayName!;
       print('🔄 Using stored TTLock username from Firebase: $ttlockUsernameToTry');
    }

    // 2. TTLock Girişi Dene
    try {
      ttlockSuccess = await _apiService.getAccessToken(
        username: ttlockUsernameToTry,
        password: event.password,
      );
    } catch (e) {
      print('TTLock Login Failed: $e');
      loginErrorMsg = e.toString().replaceAll('Exception: ', '');
    }

    // 3. Durum Analizi ve Aksiyon
    if (ttlockSuccess) {
        // En iyi senaryo: TTLock girişi başarılı.
        final accessToken = _apiService.accessToken;
        if (accessToken != null) {
          _authBloc.add(LoggedIn(accessToken));
          
          // E-postayı kaydet (Profil sayfasında göstermek için)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', event.username);
          
          emit(LoginSuccess());
        } else {
          emit(const LoginFailure('Giriş başarılı ancak anahtar alınamadı.'));
        }
    } else if (firebaseSuccess && !ttlockSuccess) {
        // KRİTİK SENARYO: Firebase şifresi yeni, TTLock şifresi eski (veya kullanıcı TTLock'ta yok).
        // Hesabı senkronize et (Sadece şifreyi güncelle, kilitleri silme!)
        print('⚠️ Password Sync Required: Firebase OK, TTLock Failed. Attempting to update TTLock password...');
        
        try {
          // Kullanıcı adını belirle (Firebase'den gelen öncelikli)
          String targetUsername = ttlockUsernameToTry;
          if (firebaseUser?.displayName == null) {
             // Eğer displayName yoksa manuel sanitize et
             targetUsername = event.username.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          }
          
          // Şifreyi güncelle (Cloud API kullanıcıları için çalışır)
          await _apiService.resetPassword(
            username: targetUsername, 
            newPassword: event.password
          );
          print('✅ TTLock password updated via Cloud API for user: $targetUsername');
          
          // Tekrar giriş yapmayı dene
          final retrySuccess = await _apiService.getAccessToken(
              username: targetUsername,
              password: event.password,
          );
          
          if (retrySuccess) {
              final accessToken = _apiService.accessToken;
              _authBloc.add(LoggedIn(accessToken!));
              
              // E-postayı kaydet
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('saved_email', event.username);
              
              emit(LoginSuccess());
          } else {
              emit(const LoginFailure('Şifre güncellendi ancak giriş yapılamadı.'));
          }
        } catch (e) {
          print('Auto-fix failed: $e');
          emit(LoginFailure('Giriş başarısız. Şifreniz senkronize edilemedi: ${e.toString().replaceAll('Exception: ', '')}'));
        }
    } else {
        // İkisi de başarısız
        emit(LoginFailure(loginErrorMsg.isNotEmpty ? loginErrorMsg : 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'));
    }
  }
}
