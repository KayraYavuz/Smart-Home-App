import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart'; // We will create this next

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _login() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Implement actual login logic with an API call.
      // For now, simulate a successful login by navigating to the HomePage.
      print('Logging in with Email: $_email, Password: $_password');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(Icons.lock, color: Color(0xFF1E90FF), size: 80),
                  SizedBox(height: 20),
                  Text(
                    'Baulemente\'e Hoş Geldiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    decoration: _buildInputDecoration('E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen e-postanızı girin' : null,
                    onSaved: (value) => _email = value!,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: _buildInputDecoration('Şifre'),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    validator: (value) =>
                        value!.isEmpty ? 'Lütfen şifrenizi girin' : null,
                    onSaved: (value) => _password = value!,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E90FF),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _login,
                    child: Text(
                      'Giriş Yap',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: Text(
                      'Hesabınız yok mu? Kaydolun',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
