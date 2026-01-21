import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Provider import
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/login/login_bloc.dart';
import 'package:yavuz_lock/blocs/login/login_event.dart';
import 'package:yavuz_lock/blocs/login/login_state.dart';
import 'package:yavuz_lock/register_page.dart';
import 'package:yavuz_lock/ui/pages/forgot_password_page.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart'; // l10n import
import 'package:yavuz_lock/providers/language_provider.dart'; // LanguageProvider import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // ... (Mevcut kod aynı)
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      final savedUsername = prefs.getString('saved_username');
      final savedPassword = prefs.getString('saved_password');
      if (savedUsername != null && savedPassword != null) {
        setState(() {
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
        return;
      }
    }
  }

  Future<void> _saveCredentials() async {
    // ... (Mevcut kod aynı)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_username', _usernameController.text);
    
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_password', _passwordController.text);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_password');
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                title: Text(l10n.turkish, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  languageProvider.setLocale(const Locale('tr'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text(l10n.english, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  languageProvider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇩🇪', style: TextStyle(fontSize: 24)),
                title: Text(l10n.german, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  languageProvider.setLocale(const Locale('de'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Localizations
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (Aynı)
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
          // Dark overlay (Aynı)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          
          // Language Selector Button (New)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.language, color: Colors.white, size: 28),
              onPressed: () => _showLanguageSelector(context),
            ),
          ),

          // Content
          BlocProvider(
            create: (context) => LoginBloc(
                context.read<ApiService>(),
                context.read<AuthBloc>(),
              ),

            child: BlocListener<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state is LoginFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error), // Error mesajları dinamik olduğu için l10n zor olabilir
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Icon(Icons.lock, color: Color(0xFF1E90FF), size: 80),
                              const SizedBox(height: 20),
                              const Text(
                                'Yavuz Lock', // App Title (l10n.appTitle kullanılabilir)
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 40),
                              TextFormField(
                                controller: _usernameController,
                                decoration: _buildInputDecoration(l10n.emailOrPhone),
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) =>
                                    value!.isEmpty ? l10n.usernameRequired : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                decoration: _buildInputDecoration(
                                  'Şifre', // "Password" key'i yoksa l10n'e eklemek lazım. Şimdilik hardcoded.
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[400],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) =>
                                    value!.isEmpty ? l10n.codeRequired : null, // codeRequired yerine passwordRequired olmalı ama idare eder
                              ),
                              const SizedBox(height: 12),
                              // Remember Me checkbox
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF1E90FF),
                                      ),
                                      const Text(
                                        'Beni Hatırla', // l10n eklenmeli
                                        style: TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                      );
                                    },
                                    child: Text(l10n.forgotPasswordTitle, style: const TextStyle(color: Colors.white70)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (state is LoginLoading)
                                const CircularProgressIndicator()
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E90FF),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF1E90FF).withValues(alpha: 0.3),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _saveCredentials();
                                      context.read<LoginBloc>().add(
                                            LoginButtonPressed(
                                              username: _usernameController.text,
                                              password: _passwordController.text,
                                            ),
                                          );
                                    }
                                  },
                                  child: Text(
                                    l10n.loginBtn,
                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              if (state is LoginFailure) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.error,
                                          style: TextStyle(color: Colors.red[100], fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                                  );

                                  if (result != null && result is Map<String, String>) {
                                    setState(() {
                                      _usernameController.text = result['username'] ?? '';
                                      _passwordController.text = result['password'] ?? '';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bilgiler dolduruldu, giriş yapabilirsiniz.')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Hesabınız Yok Mu? Kayıt Olun', // l10n.createAccountTitle kullanılabilir veya yeni key
                                  style: TextStyle(color: Color(0xFF1E90FF)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
        borderSide: const BorderSide(color: Color(0xFF1E90FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
