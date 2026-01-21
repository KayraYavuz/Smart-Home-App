import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yavuz_lock/settings_page.dart';
import 'package:yavuz_lock/ui/pages/customer_service_page.dart';
import 'package:yavuz_lock/ui/pages/login_page.dart';
import 'package:yavuz_lock/ui/pages/system_management_page.dart';
import 'package:yavuz_lock/ui/pages/work_together_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Kullanıcı';
  String _email = 'email@ornek.com';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
      setState(() {
        _username = prefs.getString('saved_username') ?? 'Kullanıcı';
        _email = prefs.getString('saved_email') ?? 'kullanici@ornek.com';
      });
      });
    } catch (e) {
      // Hata durumunda varsayılan değerler kullanılır
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      body: SafeArea(
        child: Column(
          children: [
            // Üst Başlık Alanı (Header Row)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Sol Kısım: Küçük avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Orta Kısım: Kullanıcı adı ve email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

                  // Sağ Kısım: Action Icons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.headset_mic, color: Colors.white70),
                        onPressed: () {
                          // Destek sayfası
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.white70),
                        onPressed: () {
                          // Mesajlar sayfası
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ana Menü Listesi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    icon: Icons.message,
                    iconColor: Colors.blue,
                    title: 'Hesap bilgisi',
                    onTap: () {
                      // Hesap bilgisi sayfası
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.diamond,
                    iconColor: Colors.blue,
                    title: 'Hizmetler',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerServicePage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.mic,
                    iconColor: Colors.blue,
                    title: 'Sesli Asistan',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sesli asistan yakında eklenecek')),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.blue,
                    title: 'Sistem Yönetimi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SystemManagementPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.apps,
                    iconColor: Colors.blue,
                    title: 'Birlikte çalışmak',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WorkTogetherPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.blue,
                    title: 'Ayarlar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Çıkış butonları
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton(
                      onPressed: () => _deleteAccount(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hesabı Sil',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Çıkış yapıldı'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hesabı Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesap silindi'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
