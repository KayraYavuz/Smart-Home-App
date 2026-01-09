import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({Key? key}) : super(key: key);

  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  String _username = 'ahmetkayrayavuz';
  String _email = 'ahmet@example.com';
  String _phone = '+90 555 123 4567';
  String _country = 'Turkey';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('saved_username') ?? 'ahmetkayrayavuz';
      _email = prefs.getString('saved_email') ?? 'ahmet@example.com';
      _phone = prefs.getString('saved_phone') ?? '+90 555 123 4567';
      _country = prefs.getString('saved_country') ?? 'Turkey';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Hesap bilgisi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Avatar ve Kullanıcı Bilgileri
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          child: Text(
                            _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Kullanıcı Bilgileri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _email,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Düzenleme İkonu
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Profil düzenleme sayfası
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profil düzenleme yakında eklenecek')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Hesap Bilgileri Listesi
                  _buildInfoTile(
                    title: 'Rumuz',
                    value: _username,
                    showEditIcon: true,
                  ),
                  _buildInfoTile(
                    title: 'Hesap',
                    value: _email,
                    showEditIcon: true,
                  ),
                  _buildInfoTile(
                    title: 'Telefon',
                    value: _phone,
                    showEditIcon: true,
                  ),
                  _buildInfoTile(
                    title: 'Şifreyi Yenile',
                    value: '',
                    showArrowIcon: true,
                    onTap: () {
                      // Şifre yenileme sayfası
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Şifre yenileme yakında eklenecek')),
                      );
                    },
                  ),
                  _buildInfoTile(
                    title: 'Güvenlik Sorusu',
                    value: '',
                    showNotificationDot: true,
                    onTap: () {
                      // Güvenlik sorusu sayfası
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Güvenlik sorusu ayarı yakında eklenecek')),
                      );
                    },
                  ),
                  _buildInfoTile(
                    title: 'Ülke/Bölge',
                    value: _country,
                    showEditIcon: true,
                  ),
                ],
              ),
            ),

            // Alt Kısım - Linkler ve Copyright
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _launchUrl('https://ttlock.com/terms'),
                        child: const Text(
                          'Kullanıcı koşulları',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _launchUrl('https://ttlock.com/privacy'),
                        child: const Text(
                          'Gizlilik politikası',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copyright © 2026 TTLock',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    bool showEditIcon = false,
    bool showArrowIcon = false,
    bool showNotificationDot = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: value.isNotEmpty
            ? Text(
                value,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showNotificationDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            if (showEditIcon)
              const Icon(
                Icons.edit,
                color: Colors.blue,
                size: 20,
              ),
            if (showArrowIcon)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL açılamadı: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
