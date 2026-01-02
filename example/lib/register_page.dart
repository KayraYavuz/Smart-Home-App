import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  void _register() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Implement actual registration logic with an API call.
      // For now, just print the data and navigate back to the login page.
      print('Registering with Email: $_email, Password: $_password');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('Hesap Oluştur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Lütfen bir şifre girin';
                    }
                    _password = value;
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: _buildInputDecoration('Şifreyi Onayla'),
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Lütfen şifrenizi tekrar girin';
                    }
                    if (value != _password) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                  onSaved: (value) => _confirmPassword = value!,
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
                  onPressed: _register,
                  child: Text(
                    'Kaydol',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
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
