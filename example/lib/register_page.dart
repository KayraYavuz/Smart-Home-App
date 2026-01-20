import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
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
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.registerUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(); // Giriş sayfasına dön
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
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
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
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            'Hesap Oluştur',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      
                      // Kullanıcı Adı
                      TextFormField(
                        controller: _usernameController,
                        decoration: _buildInputDecoration('E-posta veya Telefon'),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir kullanıcı adı girin';
                          }
                          if (value.length < 4) {
                            return 'Kullanıcı adı en az 4 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Şifre
                      TextFormField(
                        controller: _passwordController,
                        decoration: _buildInputDecoration(
                          'Şifre',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[400],
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir şifre girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Şifre Tekrar
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _buildInputDecoration(
                          'Şifreyi Onayla',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[400],
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 40),

                      // Kayıt Ol Butonu
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E90FF),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Color(0xFF1E90FF).withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Kayıt Ol',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF1E90FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red),
      ),
    );
  }
}