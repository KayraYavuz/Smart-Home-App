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
      print('🚀 [LoginBloc] Firebase girişi deneniyor: ${event.username}');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: event.username.trim(), 
        password: event.password
      );
      firebaseSuccess = true;
      firebaseUser = credential.user;
      print('✅ [LoginBloc] Firebase girişi başarılı: ${firebaseUser?.uid}');
    } on FirebaseAuthException catch (e) {
      print('❌ [LoginBloc] Firebase Girişi Başarısız: ${e.code} - ${e.message}');
      // Eğer şifre yanlışsa bile TTLock ile devam et (Legacy/Sync support)
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
         print('⚠️ [LoginBloc] Firebase şifresi hatalı, TTLock ile devam ediliyor...');
      } else {
         print('⚠️ [LoginBloc] Firebase hatası: ${e.code}. TTLock ile devam ediliyor...');
      }
      // Diğer hatalarda (örn: kullanıcı Firebase'de yoksa) TTLock ile devam et (Legacy support)
    } catch (e) {
      print('❌ [LoginBloc] Firebase Beklenmedik Hata: $e');
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
      print('🚀 [LoginBloc] TTLock girişi deneniyor: $ttlockUsernameToTry');
      ttlockSuccess = await _apiService.getAccessToken(
        username: ttlockUsernameToTry,
        password: event.password,
      );
      print('📋 [LoginBloc] TTLock giriş sonucu: $ttlockSuccess');
    } catch (e) {
      print('❌ [LoginBloc] TTLock Girişi Başarısız: $e');
      loginErrorMsg = e.toString().replaceAll('Exception: ', '');
    }

    // 3. Durum Analizi ve Aksiyon
    if (ttlockSuccess) {
        print('✅ [LoginBloc] TTLock girişi başarılı, login tamamlanıyor.');
        // En iyi senaryo: TTLock girişi başarılı.
        final accessToken = _apiService.accessToken;
        if (accessToken != null) {
          _authBloc.add(LoggedIn(accessToken));
          
          // E-postayı kaydet (Profil sayfasında göstermek için)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', event.username);
          
          print('🎉 [LoginBloc] LoginSuccess emit ediliyor');
          emit(LoginSuccess());
        } else {
          print('❌ [LoginBloc] Token boş çıktı');
          emit(const LoginFailure('Giriş başarılı ancak anahtar alınamadı.'));
        }
    } else if (firebaseSuccess && !ttlockSuccess) {
        // KRİTİK SENARYO: Firebase şifresi yeni, TTLock şifresi eski (veya kullanıcı TTLock'ta yok).
        // Hesabı senkronize et (Sadece şifreyi güncelle, kilitleri silme!)
        print('⚠️ [LoginBloc] Password Sync Gerekli: Firebase OK, TTLock FAILED.');
        
        // Kullanıcı adını belirle (Firebase'den gelen öncelikli)
        String targetUsername = ttlockUsernameToTry;
        if (targetUsername.contains('@')) {
           // Alphanumeric only for TTLock APIs
           targetUsername = targetUsername.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        }

        try {
          print('🔄 [LoginBloc] TTLock şifresi sıfırlanıyor (resetPassword) -> $targetUsername');
          // Şifreyi güncelle (Cloud API kullanıcıları için çalışır)
          await _apiService.resetPassword(
            username: targetUsername, 
            newPassword: event.password
          );
          print('✅ [LoginBloc] TTLock şifresi güncellendi.');
          
          // Tekrar giriş yapmayı dene
          print('🚀 [LoginBloc] Güncel şifre ile tekrar deniyor...');
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
              
              print('🎉 [LoginBloc] LoginSuccess emit ediliyor (Sync sonrası)');
              emit(LoginSuccess());
          } else {
              print('❌ [LoginBloc] Sync sonrası giriş yine başarısız');
              emit(const LoginFailure('Şifre güncellendi ancak giriş yapılamadı.'));
          }
        } catch (e) {
          print('❌ [LoginBloc] Sync başarısız, kullanıcı TTLock\'ta yok olabilir. Kayıt denendi...');
          
          try {
            // Eğer şifre sıfırlama bile başarısızsa, belki kullanıcı TTLock'ta hiç yoktur.
            // Bu durumda kayıt etmeyi deneyelim.
            await _apiService.registerUser(
              username: targetUsername, 
              password: event.password
            );
            print('✅ [LoginBloc] Eksik kullanıcı TTLock\'a kaydedildi.');
            
            // Kayıt sonrası tekrar giriş yapmayı dene
            final finalRetrySuccess = await _apiService.getAccessToken(
                username: targetUsername,
                password: event.password,
            );
            
            if (finalRetrySuccess) {
                final accessToken = _apiService.accessToken;
                _authBloc.add(LoggedIn(accessToken!));
                emit(LoginSuccess());
            } else {
                emit(const LoginFailure('Hesap oluşturuldu ancak giriş yapılamadı.'));
            }
          } catch (registerError) {
             print('❌ [LoginBloc] Kurtarma kaydı da başarısız: $registerError');
             emit(LoginFailure('Giriş başarısız. Hesabınız senkronize edilemedi: ${e.toString().replaceAll('Exception: ', '')}'));
          }
        }
    } else {
        // İkisi de başarısız
        print('❌ [LoginBloc] Tüm giriş yöntemleri başarısız');
        emit(LoginFailure(loginErrorMsg.isNotEmpty ? loginErrorMsg : 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'));
    }
  }
}
