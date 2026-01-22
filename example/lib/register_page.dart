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
  
  bool _isLoading = false;
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
        SnackBar(
          content: Text(l10n.pleaseAgreeToTerms),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.verificationEmailSent}. ${l10n.checkInbox}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = l10n.errorLabel;
      if (e.code == 'email-already-in-use') message = l10n.emailAlreadyInUse;
      if (e.code == 'weak-password') message = l10n.weakPassword;
      
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
        
        // TTLock API v3/user/register sadece harf ve rakam kabul eder.
        // E-postadaki @ ve . gibi karakterleri temizleyerek gönderiyoruz.
        final sanitizedUsername = _usernameController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

        final result = await apiService.registerUser(
          username: sanitizedUsername,
          password: _passwordController.text,
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
                child: Form(
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
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_verificationEmailSent,
                        decoration: _buildInputDecoration(l10n.emailOrPhone, prefixIcon: Icons.email),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty ? l10n.usernameRequired : null,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        enabled: !_verificationEmailSent,
                        decoration: _buildInputDecoration(
                          l10n.newPassword,
                          prefixIcon: Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.newPassword; // Reusing 'New Password' as 'Password required' label isn't explicit, but commonly used or could add a specific required key. Better to use a generic or existing empty check if available, or just keep it simple. Actually l10n.usernameRequired is for username. Let's look at existing keys. 'passwordMinLength' etc are new.
                          // Wait, looking at previous code it was "Şifre gerekli". I don't have a 'passwordRequired' key. 
                          // I'll stick to logic: if empty, show something standard or reuse a key?
                          // Let's check if there is a 'required' key. There is 'usernameRequired'.
                          // I will use 'l10n.newPassword' as a placeholder or better: 
                          // actually, let's just check length directly. If empty, length is 0 < 8, so it hits min length error.
                          // But nicer to have "required". 
                          // I'll just use "En az 8 karakter" logic for empty too or create a new key? 
                          // I'll leave the first check as "En az 8 karakter" (l10n.passwordMinLength) effectively cover empty? 
                          // No, typically field required is separate. 
                          // I will use l10n.passwordMinLength for empty case too for now as it's technically true (0 < 8).
                          
                          if (value == null || value.isEmpty) return l10n.passwordMinLength;
                          if (value.length < 8) return l10n.passwordMinLength;
                          if (!RegExp(r'[0-9]').hasMatch(value)) return l10n.passwordDigitRequired;
                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return l10n.passwordSymbolRequired;
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !_verificationEmailSent,
                        decoration: _buildInputDecoration(l10n.confirmPassword, prefixIcon: Icons.lock_clock),
                        style: const TextStyle(color: Colors.white),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value != _passwordController.text) return l10n.passwordMismatch;
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      if (!_verificationEmailSent)
                        Row(
                          children: [
                            Checkbox(
                              value: _isAgreed,
                              activeColor: const Color(0xFF1E90FF),
                              side: const BorderSide(color: Colors.white70),
                              onChanged: (value) {
                                setState(() {
                                  _isAgreed = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: l10n.userAgreement,
                                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => _launchUrl('https://sites.google.com/view/terms-yavuz-lock/ana-sayfa'),
                                    ),
                                    TextSpan(text: ' ${l10n.and} '),
                                    TextSpan(
                                      text: l10n.privacyPolicy,
                                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => _launchUrl('https://sites.google.com/view/yavuz-lock-privacy/ana-sayfa'),
                                    ),
                                    TextSpan(text: ' ${l10n.readAndApprove}.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      if (!_verificationEmailSent) ...[
                        ElevatedButton(
                          onPressed: _isLoading ? null : _registerAndSendVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E90FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(l10n.registerBtn, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => _launchUrl('https://lock2.ttlock.com/'),
                          icon: const Icon(Icons.language, color: Colors.blue, size: 20),
                          label: const Text(
                            '${l10n.ttlockWebPortalRegister}',
                            style: TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],

                      if (_verificationEmailSent) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.mark_email_read, color: Colors.green, size: 48),
                              SizedBox(height: 16),
                              Text(
                                l10n.verificationEmailSentMsg,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.verificationEmailInstruction,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _checkVerificationAndRegisterInTTLock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(l10n.checkVerificationAndComplete, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _verificationEmailSent = false),
                          child: Text(l10n.changeEmailAddress, style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ],
                  ),
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
