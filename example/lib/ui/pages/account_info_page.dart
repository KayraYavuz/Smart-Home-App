import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  String _username = 'Kullanıcı';
  String _email = 'kullanici@ornek.com';
  String _phone = '+90 5XX XXX XX XX';
  String _country = 'Türkiye';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String loadedEmail = prefs.getString('saved_email') ?? 'kullanici@ornek.com';
    String loadedUsername = prefs.getString('saved_username') ?? '';

    // Eğer kullanıcı adı kayıtlı değilse veya varsayılan ise, e-postadan üret
    if (loadedUsername.isEmpty || loadedUsername == 'Kullanıcı') {
      if (loadedEmail.contains('@')) {
        loadedUsername = loadedEmail.split('@')[0];
      } else {
        loadedUsername = 'Kullanıcı';
      }
    }

    setState(() {
      _username = loadedUsername;
      _email = loadedEmail;
      _phone = prefs.getString('saved_phone') ?? '+90 5XX XXX XX XX';
      _country = prefs.getString('saved_country') ?? 'Türkiye';
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
                          onPressed: () => _editAvatar(context),
                        ),
                      ],
                    ),
                  ),

                  // Hesap Bilgileri Listesi
                  _buildInfoTile(
                    title: 'Rumuz',
                    value: _username,
                    showEditIcon: true,
                    onTap: () => _editField('Rumuz', 'saved_username', _username),
                  ),
                  _buildInfoTile(
                    title: 'Hesap',
                    value: _email,
                    showEditIcon: true,
                    onTap: () => _editField('Email', 'saved_email', _email),
                  ),
                  _buildInfoTile(
                    title: 'Telefon',
                    value: _phone,
                    showEditIcon: true,
                    onTap: () => _editField('Telefon', 'saved_phone', _phone),
                  ),
                  _buildInfoTile(
                    title: 'Şifreyi Yenile',
                    value: '',
                    showArrowIcon: true,
                    onTap: _changePassword,
                  ),
                  _buildInfoTile(
                    title: 'Güvenlik Sorusu',
                    value: 'Ayarlanmadı',
                    showNotificationDot: true,
                    showArrowIcon: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Güvenlik sorusu ayarı yakında eklenecek')),
                      );
                    },
                  ),
                  _buildInfoTile(
                    title: 'Ülke/Bölge',
                    value: _country,
                    showEditIcon: true,
                    onTap: () => _editField('Ülke/Bölge', 'saved_country', _country),
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

  Future<void> _editField(String title, String key, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('$title Düzenle', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Yeni $title girin',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Kaydet', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty && newValue != currentValue) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, newValue);
      
      setState(() {
        if (key == 'saved_username') _username = newValue;
        if (key == 'saved_email') _email = newValue;
        if (key == 'saved_phone') _phone = newValue;
        if (key == 'saved_country') _country = newValue;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Şifreyi Yenile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (newPassController.text != confirmPassController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifreler eşleşmiyor!'), backgroundColor: Colors.red),
                );
                return;
              }
              if (newPassController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifre en az 6 karakter olmalı!'), backgroundColor: Colors.red),
                );
                return;
              }
              // Simüle edilmiş başarı
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre başarıyla güncellendi'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _editAvatar(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar değiştirme özelliği yakında eklenecek')),
    );
  }
}
