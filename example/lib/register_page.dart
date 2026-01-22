import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ttlockCodeController = TextEditingController(); // TTLock için kod
  
  bool _isLoading = false;
  bool _ttlockCodeSent = false; // TTLock kodu gönderildi mi?
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _verificationEmailSent = false;
  bool _isAgreed = false;
  
  final _auth = FirebaseAuth.instance;

  Future<void> _registerAndSendVerification() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı sözleşmesini ve gizlilik politikasını onaylayın.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // 1. Firebase Kullanıcısı Oluştur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      
      final user = credential.user;

      // 2. Doğrulama Maili Gönder
      await user?.sendEmailVerification();
      
      setState(() {
        _verificationEmailSent = true;
        _isLoading = false;
      });

      if (!mounted) return;
      _showVerificationDialog();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = l10n.errorLabel;
      if (e.code == 'email-already-in-use') message = 'Bu e-posta zaten kullanımda.'; // Bu mesajları da l10n'e eklemek iyi olur ama şimdilik kalsın
      if (e.code == 'weak-password') message = 'Şifre çok zayıf.';
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorLabel}: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showVerificationDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(l10n.verificationEmailSent, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.checkInbox, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'TTLock (Kilit Sistemi) için de bir doğrulama kodu almanız gerekiyor. Böylece e-posta adresinizle giriş yapabilirsiniz.',
                style: TextStyle(color: Colors.blue, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_ttlockCodeSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setModalState(() => _isLoading = true);
                    try {
                      final apiService = ApiService(null);
                      await apiService.getVerifyCode(username: _usernameController.text.trim());
                      setModalState(() {
                         _ttlockCodeSent = true;
                         _isLoading = false;
                      });
                    } catch (e) {
                      setModalState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  },
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('TTLock Kodu Gönder'),
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: _ttlockCodeController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'TTLock Kodu (6 Haneli)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Kod e-posta adresinize (TTLock\'tan) gönderildi.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _checkVerificationAndRegisterInTTLock(),
              child: Text(l10n.checkVerification),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkVerificationAndRegisterInTTLock() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      // Güncel kullanıcı durumunu çek
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // E-posta doğrulandı! Şimdi asıl TTLock kaydını yapalım.
        final apiService = ApiService(context.read<AuthRepository>());
        
        // Artik e-posta adresini oldugu gibi kullanmayi deniyoruz (TTLock kodu ile)
        final username = _usernameController.text.trim();
        final ttlockCode = _ttlockCodeController.text.trim();

        final result = await apiService.registerUser(
          username: username,
          password: _passwordController.text,
          verifyCode: ttlockCode.isNotEmpty ? ttlockCode : null,
        );

        final String prefixedUsername = result['username'] ?? '';
        
        // TTLock tarafından verilen gerçek kullanıcı adını (prefixli) Firebase'e kaydet
        await user.updateDisplayName(prefixedUsername);

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(l10n.registrationSuccess, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.registrationSuccessMsg, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 16),
                Text(l10n.loginIdLabel, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _usernameController.text.trim(),
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginIdNote,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
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
                child: Text(l10n.loginBtn, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.emailNotVerified}. ${l10n.checkInboxForLink}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorLabel}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL açılamadı: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Color(0xFF1E90FF).withOpacity(0.8),
                    const Color(0xFF4169E1).withOpacity(0.6),
                    const Color(0xFF000428).withOpacity(0.9),
                    const Color(0xFF004e92).withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.app_registration, size: 80, color: Colors.white),
                    const SizedBox(height: 32),
                    const Text(
                      'Kayıt İşlemleri',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hesap oluşturma işlemleri TTLock web portalı veya resmi mobil uygulaması üzerinden yapılmaktadır.',
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
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Giriş Ekranına Dön', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, {IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E90FF))),
    );
  }
}
