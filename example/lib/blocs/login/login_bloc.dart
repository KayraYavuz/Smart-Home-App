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
    on<SyncPassword>(_onSyncPassword);
  }

  void _onSyncPassword(SyncPassword event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      // 1. TTLock Şifresini Sıfırla (Kod ile)
      await _apiService.resetPassword(
        username: event.username,
        newPassword: event.password,
        verifyCode: event.code,
      );
      print('✅ [LoginBloc] TTLock şifresi kod ile başarıyla güncellendi.');

      // 2. Yeni şifreyle giriş yap
      final success = await _apiService.getAccessToken(
        username: event.username,
        password: event.password,
      );

      if (success) {
        final accessToken = _apiService.accessToken;
        _authBloc.add(LoggedIn(accessToken!));
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', event.username); // Orijinal email'i kaydetmek isteriz ama burada username var. Neyse.
        
        emit(LoginSuccess());
      } else {
        emit(const LoginFailure('Şifre güncellendi ancak giriş yapılamadı.'));
      }
    } catch (e) {
      print('❌ [LoginBloc] SyncPassword Hatası: $e');
      emit(LoginFailure('Doğrulama başarısız: ${e.toString().replaceAll('Exception: ', '')}'));
    }
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
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
         print('⚠️ [LoginBloc] Firebase şifresi hatalı, TTLock ile devam ediliyor...');
      } else {
         print('⚠️ [LoginBloc] Firebase hatası: ${e.code}. TTLock ile devam ediliyor...');
      }
    } catch (e) {
      print('❌ [LoginBloc] Firebase Beklenmedik Hata: $e');
    }

    // TTLock kullanıcı adlarını hazırla
    final String email = event.username.trim();
    final String emailSmall = email.toLowerCase();
    final String sanitized = emailSmall.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final String prefixed = 'fihbg_$sanitized';
    
    final List<String> usernamesToTry = [
      email, 
      prefixed,
      if (firebaseUser?.displayName != null) firebaseUser!.displayName!,
    ];

    print('👤 Giriş denenecek formatlar: $usernamesToTry');

    // 2. TTLock Girişi Dene
    for (String username in usernamesToTry) {
      if (username.isEmpty) continue;
      try {
        print('🔐 Deneniyor: User="$username"');
        ttlockSuccess = await _apiService.getAccessToken(
          username: username,
          password: event.password,
        );
        if (ttlockSuccess) {
           print('✅ Giriş BAŞARILI! (Format: $username)');
           break;
        }
      } catch (e) {
        print('⚠️  $username başarısız: $e');
      }
    }

    // 3. Durum Analizi ve Aksiyon
    if (ttlockSuccess) {
        print('✅ [LoginBloc] TTLock girişi başarılı, login tamamlanıyor.');
        final accessToken = _apiService.accessToken;
        if (accessToken != null) {
          _authBloc.add(LoggedIn(accessToken));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', event.username);
          print('🎉 [LoginBloc] LoginSuccess emit ediliyor');
          emit(LoginSuccess());
        } else {
          emit(const LoginFailure('Giriş başarılı ancak anahtar alınamadı.'));
        }
                } else if (firebaseSuccess && !ttlockSuccess) {
                    // Şifre uyuşmazlığı durumunda karmaşık süreçler yerine doğrudan Web Portalına yönlendir.
                    print('⚠️ [LoginBloc] Şifre uyuşmazlığı (Firebase OK, TTLock FAIL). Web Portalına yönlendiriliyor...');
                    emit(LoginTTLockWebRedirect());
                } else {
                    print('❌ [LoginBloc] Tüm giriş yöntemleri başarısız');
                    emit(LoginFailure(loginErrorMsg.isNotEmpty ? loginErrorMsg : 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'));
                }
              }
            }
