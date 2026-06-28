import "package:flutter/foundation.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_event.dart';
import 'package:yavuz_lock/blocs/login/login_event.dart';
import 'package:yavuz_lock/blocs/login/login_state.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

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
      debugPrint('🚀 [LoginBloc] Firebase girişi deneniyor: ${event.username}');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: event.username.trim(), password: event.password);
      firebaseSuccess = true;
      firebaseUser = credential.user;
      debugPrint(
          '✅ [LoginBloc] Firebase girişi başarılı: ${firebaseUser?.uid}');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '❌ [LoginBloc] Firebase Girişi Başarısız: ${e.code} - ${e.message}');
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        debugPrint(
            '⚠️ [LoginBloc] Firebase şifresi hatalı, TTLock ile devam ediliyor...');
      } else {
        debugPrint(
            '⚠️ [LoginBloc] Firebase hatası: ${e.code}. TTLock ile devam ediliyor...');
      }
    } catch (e) {
      debugPrint('❌ [LoginBloc] Firebase Beklenmedik Hata: $e');
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

    debugPrint('👤 Giriş denenecek formatlar: $usernamesToTry');

    // 2. TTLock Girişi Dene
    for (String username in usernamesToTry) {
      if (username.isEmpty) continue;
      try {
        debugPrint('🔐 Deneniyor: User="$username"');
        ttlockSuccess = await _apiService.getAccessToken(
          username: username,
          password: event.password,
        );
        if (ttlockSuccess) {
          debugPrint('✅ Giriş BAŞARILI! (Format: $username)');
          break;
        }
      } catch (e) {
        debugPrint('⚠️  $username başarısız: $e');
      }
    }

    // 3. Durum Analizi ve Aksiyon
    if (ttlockSuccess) {
      debugPrint('✅ [LoginBloc] TTLock girişi başarılı, login tamamlanıyor.');
      final accessToken = _apiService.accessToken;
      if (accessToken != null) {
        _authBloc.add(LoggedIn(accessToken));
        final prefs = await SharedPreferences.getInstance();
        // trim'li kaydet — premium docKey de trim'li, aksi halde boşluklu email
        // girişinde anahtarlar uyuşmaz (farklı Firestore belgesi aranır).
        await prefs.setString('saved_email', event.username.trim());
        // Keychain'e de yaz — reinstall'da SharedPreferences silinse bile kalır
        await AuthRepository().saveEmail(event.username.trim());

        // Firestore key: email'den türetilen sabit anahtar
        final docKey = event.username.trim().toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_');
        try {
          await FirebaseFirestore.instance.collection('users').doc(docKey)
              .set({'email': event.username.trim()}, SetOptions(merge: true));
          debugPrint('✅ Firestore user doc yazıldı: $docKey');
        } catch (e) {
          debugPrint('⚠️ Firestore user doc oluşturulamadı: $e');
        }
        debugPrint('🎉 [LoginBloc] LoginSuccess emit ediliyor');
        emit(LoginSuccess());
      } else {
        emit(const LoginFailure('loginSuccessButNoToken'));
      }
    } else if (firebaseSuccess && !ttlockSuccess) {
      debugPrint('⚠️ [LoginBloc] Firebase OK, TTLock FAIL. Web Portalına yönlendiriliyor...');
      emit(LoginTTLockWebRedirect());
    } else {
      debugPrint('❌ [LoginBloc] Tüm giriş yöntemleri başarısız');
      emit(LoginFailure(loginErrorMsg.isNotEmpty
          ? loginErrorMsg
          : 'loginFailedCheckCredentials'));
    }
  }
}
