import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  String _username = '';
  String _email = '';
  String _phone = '';
  String _country = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('saved_email') ?? '';
      _username = prefs.getString('saved_username') ?? '';
      _phone = prefs.getString('saved_phone') ?? '';
      _country = prefs.getString('saved_country') ?? 'Türkiye';
      
      // Eski hardcoded veya istenmeyen verileri temizle
      if (_phone.contains('5XX XXX') || _phone.contains('05316305072') || _phone.contains('05326305072')) {
         _phone = '';
         prefs.remove('saved_phone');
      }
      
      // Eğer username boşsa ve email varsa, email'in başını kullan
      if (_username.isEmpty && _email.contains('@')) {
        _username = _email.split('@')[0];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.accountInfo,
          style: const TextStyle(
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
                          backgroundColor: Colors.blue.withOpacity(0.2),
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
                    title: l10n.accountInfoUsername,
                    value: _username,
                    showEditIcon: true,
                    onTap: () => _editField(l10n.accountInfoUsername, 'saved_username', _username),
                  ),
                  _buildInfoTile(
                    title: l10n.accountInfoEmail,
                    value: _email,
                    showEditIcon: true,
                    onTap: () => _editField(l10n.accountInfoEmail, 'saved_email', _email),
                  ),
                  _buildInfoTile(
                    title: l10n.accountInfoPhone,
                    value: _phone,
                    showEditIcon: true,
                    onTap: () => _editField(l10n.accountInfoPhone, 'saved_phone', _phone),
                  ),
                  _buildInfoTile(
                    title: l10n.resetPasswordBtn,
                    value: '',
                    showArrowIcon: true,
                    onTap: _changePassword,
                  ),
                  _buildInfoTile(
                    title: 'Güvenlik Sorusu', // Henüz l10n'de yok
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
                    title: 'Ülke/Bölge', // Henüz l10n'de yok
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
                        onPressed: () => _launchUrl('https://sites.google.com/view/terms-yavuz-lock/ana-sayfa'),
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
                        onPressed: () => _launchUrl('https://sites.google.com/view/yavuz-lock-privacy/ana-sayfa'),
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
                    'Copyright © 2026 Yavuz Lock',
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
            : const Text(
                'Ekle',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
      if (!mounted) return;
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
    // Burada şifre değiştirme dialogu olabilir veya Firebase'e yönlendirilebilir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Şifre değiştirme işlemi için giriş sayfasındaki "Şifremi Unuttum" özelliğini kullanın.')),
    );
  }

  Future<void> _editAvatar(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar değiştirme özelliği yakında eklenecek')),
    );
  }
}
