import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _linkSent = false;

  final _auth = FirebaseAuth.instance;
  
  // TTLock states
  bool _isTTLockFlow = false;
  bool _codeSent = false;
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _sendResetLink() async {
    final l10n = AppLocalizations.of(context)!;
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usernameRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Şifre Sıfırlama Maili Gönder
      await _auth.sendPasswordResetEmail(
        email: _usernameController.text.trim(),
      );
      
      setState(() {
        _linkSent = true;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.sentLink}. ${l10n.checkInboxForLink}'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = l10n.errorLabel;
      bool showTTLockOption = false;

      if (e.code == 'user-not-found') {
        message = 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı. TTLock üzerinden kayıt olduysanız "Sıfırlama Kodu Gönder" butonunu deneyin.';
        showTTLockOption = true;
        setState(() => _isTTLockFlow = true); // Auto-switch to TTLock flow if not found in Firebase
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.red,
          action: showTTLockOption ? SnackBarAction(
            label: 'Kod Gönder',
            textColor: Colors.white,
            onPressed: _sendTTLockResetCode,
          ) : null,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorLabel}: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendTTLockResetCode() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usernameRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(null); // No auth repository needed for public reset
      final success = await apiService.getResetPasswordCode(username: username);
      
      if (success) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
          _isTTLockFlow = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sıfırlama kodu e-posta adresinize gönderildi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resetTTLockPassword() async {
    final username = _usernameController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (code.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(null);
      await apiService.resetPassword(
        username: username,
        newPassword: newPassword,
        verifyCode: code,
      );
      
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Başarılı'),
          content: const Text('Şifreniz başarıyla sıfırlandı. Şimdi yeni şifrenizle giriş yapabilirsiniz.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı açılamadı: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.forgotPasswordTitle, style: const TextStyle(color: Colors.white)),
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              'Şifre Yenileme',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Güvenliğiniz için şifre yenileme işlemleri TTLock web portalı veya resmi mobil uygulaması üzerinden yapılmaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _launchUrl('https://lock2.ttlock.com/'),
              icon: const Icon(Icons.web),
              label: const Text('TTLock Web Portalı'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchUrl('https://apps.apple.com/app/ttlock/id1095261304'),
              icon: const Icon(Icons.apple),
              label: const Text('App Store\'da Görüntüle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchUrl('https://play.google.com/store/apps/details?id=com.tongtonglock.lock'),
              icon: const Icon(Icons.android),
              label: const Text('Play Store\'da Görüntüle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Giriş Ekranına Dön', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
