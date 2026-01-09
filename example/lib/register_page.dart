import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _register() async {
    // Loading göstergesi
    setState(() {
      _isLoading = true;
    });

    try {
      // TTLock web kayıt sayfasına yönlendirme
      const ttlockRegisterUrl = 'https://euapi.ttlock.com/register';

      final uri = Uri.parse(ttlockRegisterUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Kullanıcıya bilgi ver
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTLock kayıt sayfası açıldı. Kayıt olduktan sonra uygulamaya geri dönün.'),
            backgroundColor: Color(0xFF1E90FF),
            duration: Duration(seconds: 5),
          ),
        );

        // Kullanıcının geri dönmesi için biraz bekle
        await Future.delayed(Duration(seconds: 2));

        // Giriş sayfasına dön
        Navigator.of(context).pop();

      } else {
        throw Exception('TTLock kayıt sayfası açılamadı');
      }

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TTLock kayıt sayfası açılamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hesap Oluştur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Logo/Icon
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E90FF), Color(0xFF4169E1)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF1E90FF).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'TTLock Hesabı Oluştur',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'TTLock web sitesinde hesap oluşturun',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E90FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF1E90FF).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Kayıt işlemi TTLock\'un resmi web sitesi üzerinden yapılır. '
                              'Kayıt olduktan sonra bu uygulamada giriş yapabilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Bilgilendirme metni
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF1E90FF),
                                  size: 32,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'TTLock Hesap Oluşturma',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Kayıt işlemi TTLock\'un resmi web sitesi üzerinden yapılır.',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1E90FF).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF1E90FF).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Web sitesinde hesap oluşturduktan sonra bu uygulamada giriş yapabilirsiniz.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),

                          // Register button
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E90FF)),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1E90FF),
                                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: Color(0xFF1E90FF).withValues(alpha: 0.3),
                                  ),
                                  icon: Icon(Icons.open_in_browser, color: Colors.white),
                                  label: Text(
                                    'TTLock Kayıt Sayfasına Git',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _register,
                                ),

                          SizedBox(height: 20),

                          // Terms and conditions
                          Text(
                            'Kayıt olarak kullanım koşullarını kabul etmiş olursunuz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
