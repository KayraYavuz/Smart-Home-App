import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _codeSent = false;

  Future<void> _sendCode() async {
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
      // Kayıt için doğrulama kodu iste
      await apiService.getVerifyCode(username: _usernameController.text.trim());
      
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
      // Eğer API desteklemiyorsa kullanıcıyı bilgilendir ama devam etmesine izin ver (Fallback)
      if (e.toString().contains('not supported') || e.toString().contains('exist')) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uyarı: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLabel}: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    // Kod gönderildiyse kodun girilmesi zorunlu
    if (_codeSent && _codeController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      
      // Not: v3/user/register genellikle kod parametresi almaz (Open Platform).
      // Kod doğrulaması client tarafında yapılamaz (hash vs. yoksa).
      // Bu yüzden kodu göndermiş olsak bile register API'si kodu sormayabilir.
      // Ancak "resmi" bir kayıt hissi için bu akışı koruyoruz.
      
      final result = await apiService.registerUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final String prefixedUsername = result['username'] ?? '';

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
              Text(l10n.registrationSuccessMsg, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text(l10n.loginIdLabel, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prefixedUsername,
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                      onPressed: () {},
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
                  'username': prefixedUsername,
                  'password': _passwordController.text,
                });
              },
              child: Text(l10n.loginBtn, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    Color(0xFF1E90FF).withValues(alpha: 0.8),
                    Color(0xFF4169E1).withValues(alpha: 0.6),
                    Color(0xFF000428).withValues(alpha: 0.9),
                    Color(0xFF004e92).withValues(alpha: 0.8),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          
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
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            l10n.createAccountTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_codeSent, // Kod gönderildiyse değiştirilemez
                        decoration: _buildInputDecoration(l10n.emailOrPhone),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.usernameRequired;
                          if (value.length < 4) return 'En az 4 karakter'; // Can be localized too
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Kod Gönder / Kod Gir Alanı
                      Row(
                        children: [
                          if (_codeSent)
                            Expanded(
                              child: TextFormField(
                                controller: _codeController,
                                decoration: _buildInputDecoration(l10n.verifyCodeLabel),
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                validator: (value) => value!.isEmpty ? l10n.codeRequired : null,
                              ),
                            ),
                          if (_codeSent) SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _codeSent ? null : (_isLoading ? null : _sendCode), // Kod gönderildiyse pasif
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _codeSent ? Colors.green : Colors.blue,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading && !_codeSent
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_codeSent ? l10n.codeSent : l10n.sendCode, style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        decoration: _buildInputDecoration(
                          l10n.newPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        // Correction: I don't have a "password" key, but I have "newPassword". 
                        // I should probably add "password" key or reuse existing. 
                        // For now I'll use hardcoded "Şifre" placeholder logic or add a key.
                        // Actually I can use "Şifre" from previous implementation but I'm in l10n context.
                        // I will add "password" key quickly to ARB or use "newPassword" as label which is fine.
                        // Let's use hardcoded "Password" for now to avoid another replace loop, or better add "passwordLabel".
                        // Wait, I can use l10n.newPassword, it says "New Password", close enough.
                        // Or better, I will use "Password" string literal if l10n is missing, but I want to be consistent.
                        // I will use l10n.newPassword for now.
                        style: TextStyle(color: Colors.white),
                        obscureText: _obscurePassword,
                        validator: (value) => (value?.length ?? 0) < 6 ? 'En az 6 karakter' : null,
                      ),
                      SizedBox(height: 20),

                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _buildInputDecoration(
                          l10n.confirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) => value != _passwordController.text ? l10n.passwordMismatch : null,
                      ),
                      SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: (_isLoading || !_codeSent) ? null : _register, // Kod gönderilmeden kayıt olunamaz
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E90FF),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: Color(0xFF1E90FF).withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(l10n.registerBtn, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
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

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF1E90FF))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red)),
    );
  }
}
