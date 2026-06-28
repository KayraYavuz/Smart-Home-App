import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/config.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/services/email_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(); // e-posta (TTLock kimliği + doğrulama)
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isAgreed = false;
  bool _otpSent = false;
  String _verificationCode = '';

  final _auth = FirebaseAuth.instance;
  final _emailService = EmailService();

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl('https://sites.google.com/view/terms-yavuz-lock/ana-sayfa');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl('https://sites.google.com/view/yavuz-lock-privacy/ana-sayfa');
  }

  // Adım 1: OTP gönder
  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseAgreeToTerms), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final code = _emailService.generateVerificationCode();
    final lang = Localizations.localeOf(context).languageCode;
    final sent = await _emailService.sendVerificationEmail(
      _usernameController.text.trim(),
      code,
      languageCode: lang,
    );

    if (!mounted) return;

    if (!sent) {
      // SMTP yapılandırılmamışsa doğrulama olmadan devam et
      await _createAccounts();
      return;
    }

    _verificationCode = code;
    setState(() {
      _otpSent = true;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Doğrulama kodu ${_usernameController.text.trim()} adresine gönderildi.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Adım 2: OTP doğrula → hesap oluştur
  Future<void> _verifyOtpAndComplete() async {
    if (_otpController.text.trim() != _verificationCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yanlış doğrulama kodu.'), backgroundColor: Colors.red),
      );
      return;
    }
    await _createAccounts();
  }

  Future<void> _createAccounts() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      // 1. Firebase hesabı oluştur — e-posta ile (doğrulama e-postaya gider).
      //    Firebase OPSİYONELDİR: e-posta zaten kayıtlı + şifre uyuşmazsa
      //    (invalid-credential) kayıt çökmemeli, TTLock kaydıyla devam etmeli.
      final email = _usernameController.text.trim();
      final password = _passwordController.text;
      User? user;
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = cred.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          try {
            final cred = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            user = cred.user;
          } catch (_) {
            // Firebase şifresi uyuşmuyor — sessizce devam et (Firebase opsiyonel)
          }
        }
        // Diğer Firebase hataları da kayıt akışını bozmasın
      } catch (_) {
        // Beklenmedik Firebase hatası — TTLock kaydıyla devam et
      }

      // 2. TTLock'a kayıt ol — kimlik e-posta (fihbg_<email>)
      final apiService = ApiService(context.read<AuthRepository>());
      final sanitizedUsername =
          email.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final fallback = '${ApiConfig.ttlockUsernamePrefix}$sanitizedUsername';

      String prefixedUsername = fallback;
      try {
        final result = await apiService.registerUser(
          username: sanitizedUsername,
          password: password,
        );
        prefixedUsername = result['username'] ?? fallback;
      } catch (ttlockErr) {
        if (!ttlockErr.toString().contains('apiUsernameAlreadyTaken')) {
          rethrow;
        }
        // TTLock hesabı zaten var — aynı şifre ile giriş dene
        final loginOk = await apiService.getAccessToken(
          username: sanitizedUsername,
          password: password,
        );
        if (!loginOk) {
          // Şifre uyuşmuyor — kullanıcıya bilgi ver ama Firebase hesabını tamamla
          // Şifre uyuşmazlığı — sessizce devam et, kullanıcı giriş sonrası "Şifremi Unuttum" ile sıfırlayabilir
        }
      }

      // 3. TTLock kullanıcı adını Firebase'e kaydet (Firebase varsa)
      await user?.updateDisplayName(prefixedUsername);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(l10n.registrationSuccess,
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.registrationSuccessMsg,
                  style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 16),
              Text(l10n.loginIdLabel,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _usernameController.text.trim(),
                  style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.loginIdNote,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop({
                  'username': _usernameController.text.trim(),
                  'password': _passwordController.text,
                });
              },
              child: Text(l10n.loginBtn,
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = l10n.emailAlreadyInUse;
        case 'weak-password':
          message = l10n.weakPassword;
        case 'invalid-email':
          message = l10n.invalidEmail;
        case 'network-request-failed':
          message = l10n.networkError;
        case 'too-many-requests':
          message = l10n.tooManyRequests;
        case 'operation-not-allowed':
          message = 'E-posta/şifre girişi etkin değil.';
        default:
          message = '${l10n.errorLabel}: ${e.code}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg == 'apiUsernameAlreadyTaken') {
        errorMsg = l10n.apiUsernameAlreadyTaken;
      } else if (errorMsg.startsWith('apiRegistrationFailed:')) {
        errorMsg = '${l10n.registrationFailed}: ${errorMsg.substring('apiRegistrationFailed:'.length)}';
      } else if (errorMsg.startsWith('apiRegistrationHttpError:')) {
        errorMsg = '${l10n.registrationFailed}: HTTP ${errorMsg.substring('apiRegistrationHttpError:'.length)}';
      } else if (errorMsg == 'apiRegistrationUnexpectedResponse') {
        errorMsg = l10n.apiRegistrationUnexpectedResponse;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorLabel}: $errorMsg'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.urlOpenError(url)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E90FF).withValues(alpha: 0.8),
                    const Color(0xFF4169E1).withValues(alpha: 0.6),
                    const Color(0xFF000428).withValues(alpha: 0.9),
                    const Color(0xFF004e92).withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.5))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _otpSent ? _buildOtpStep(l10n) : _buildRegistrationForm(l10n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                l10n.createAccountTitle,
                style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _usernameController,
            decoration: _buildInputDecoration(
                l10n.localeName == 'tr' ? 'E-posta' : 'Email',
                prefixIcon: Icons.email),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return l10n.usernameRequired;
              if (!v.contains('@')) return l10n.invalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: _buildInputDecoration(
              l10n.newPassword,
              prefixIcon: Icons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400]),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.passwordRequired;
              if (value.length < 8) return l10n.passwordMinLength;
              if (!RegExp(r'[0-9]').hasMatch(value)) return l10n.passwordDigitRequired;
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return l10n.passwordSymbolRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _buildInputDecoration(
              l10n.confirmPassword,
              prefixIcon: Icons.lock_clock,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400]),
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value != _passwordController.text) return l10n.passwordMismatch;
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _isAgreed,
                activeColor: const Color(0xFF1E90FF),
                side: const BorderSide(color: Colors.white70),
                onChanged: (value) => setState(() => _isAgreed = value ?? false),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                        text: l10n.userAgreement,
                        style: const TextStyle(
                            color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: _termsRecognizer,
                      ),
                      TextSpan(text: ' ${l10n.and} '),
                      TextSpan(
                        text: l10n.privacyPolicy,
                        style: const TextStyle(
                            color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: _privacyRecognizer,
                      ),
                      TextSpan(text: ' ${l10n.readAndApprove}.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E90FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(l10n.registerBtn,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() {
                _otpSent = false;
                _verificationCode = '';
                _otpController.clear();
              }),
            ),
            const Text(
              'Email Doğrulama',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mark_email_read, color: Colors.blue, size: 48),
              const SizedBox(height: 12),
              const Text(
                '6 haneli doğrulama kodu gönderildi.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _usernameController.text.trim(),
                style: const TextStyle(color: Colors.blue, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          decoration: _buildInputDecoration('Doğrulama Kodu', prefixIcon: Icons.pin),
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtpAndComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Doğrula ve Hesap Oluştur',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: const Text('Kodu tekrar gönder', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label,
      {IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E90FF))),
    );
  }
}
