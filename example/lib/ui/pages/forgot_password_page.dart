import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;

  Future<void> _getResetCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usernameRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getResetPasswordCode(username: _usernameController.text.trim());
      
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeSent), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorLabel}: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      // Not: TTLock resetPassword API'si 'code' parametresi ister mi?
      // ApiService içindeki resetPassword metodunu kontrol etmeliyim.
      // Eğer code parametresi yoksa, normalde v3/user/resetPassword code ile çalışır.
      // ApiService'i güncellemem gerekebilir. Şimdilik varsayılan metodu kullanıyorum.
      
      // API servisine username, yeni şifre ve doğrulama kodunu gönderiyoruz
      await apiService.resetPassword(
        username: _usernameController.text.trim(),
        newPassword: _passwordController.text,
        verifyCode: _codeController.text.trim(),
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetSuccess), backgroundColor: Colors.green),
      );
      
      Navigator.of(context).pop(); // Giriş ekranına dön

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorLabel}: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              
              // Kullanıcı Adı
              TextFormField(
                controller: _usernameController,
                enabled: !_codeSent,
                decoration: InputDecoration(
                  labelText: l10n.emailOrPhone,
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value!.isEmpty ? l10n.usernameRequired : null,
              ),
              const SizedBox(height: 16),

              // Kod Gönder Butonu (Henüz gönderilmediyse)
              if (!_codeSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _getResetCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l10n.sendCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),

              // Kod ve Yeni Şifre Alanları (Kod gönderildiyse)
              if (_codeSent) ...[
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: l10n.verifyCodeLabel,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.security, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? l10n.codeRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => value!.length < 6 ? 'En az 6 karakter' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l10n.resetPasswordBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
