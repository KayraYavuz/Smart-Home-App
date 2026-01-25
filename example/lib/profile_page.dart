import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/settings_page.dart';
import 'package:yavuz_lock/ui/pages/account_info_page.dart';
import 'package:yavuz_lock/ui/pages/customer_service_page.dart';
import 'package:yavuz_lock/ui/pages/system_management_page.dart';
import 'package:yavuz_lock/ui/pages/work_together_page.dart';
import 'package:yavuz_lock/ui/pages/group_management_page.dart';
import 'package:yavuz_lock/logs_page.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_event.dart';

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
      });
    } catch (e) {
      // Hata durumunda varsayılan değerler kullanılır
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white54, size: 16),
                              onPressed: _editUsername,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Text(
                          _email,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                    title: l10n.accountInfo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AccountInfoPage()),
                      ).then((_) => _loadUserInfo());
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.diamond,
                    iconColor: Colors.blue,
                    title: l10n.services,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerServicePage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.history,
                    iconColor: Colors.blue,
                    title: l10n.allRecords,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LogsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.blue,
                    title: l10n.systemManagement,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SystemManagementPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.folder_shared,
                    iconColor: Colors.blue,
                    title: l10n.groupManagement,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GroupManagementPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.apps,
                    iconColor: Colors.blue,
                    title: l10n.workTogether,
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
                    title: l10n.settings,
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
                      child: Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      child: Text(
                        l10n.deleteAccount,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
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
    final l10n = AppLocalizations.of(context)!;
    // SharedPreferences temizleme ve AuthService token temizleme işlemi
    // AuthBloc'un LoggedOut eventi içinde yapılıyor (AuthRepository.deleteTokens)
    // Bu yüzden buradaki manuel temizlemeye gerek yok, veya sadece UI state için kalabilir.
    
    // AuthBloc'a çıkış eventi gönder
    context.read<AuthBloc>().add(LoggedOut());
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.loggedOutMessage),
        backgroundColor: Colors.green,
      ),
    );
    
    // Manuel navigasyon kaldırıldı. Main.dart içindeki BlocBuilder durumu dinleyip sayfayı değiştirecek.
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.deleteAccount,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.deleteAccountConfirmation,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // AuthBloc'a çıkış eventi gönder (Hesap silme API'si varsa önce o çağrılmalı)
      // Şimdilik sadece logout gibi davranıyor
      context.read<AuthBloc>().add(LoggedOut());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountDeletedMessage),
          backgroundColor: Colors.red,
        ),
      );
      
      // Manuel navigasyon kaldırıldı. Main.dart içindeki BlocBuilder durumu dinleyip sayfayı değiştirecek.
    }
  }

  Future<void> _editUsername() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(text: _username);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.editName, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.enterNewName,
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save, style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', newName);
      if (!mounted) return;
      setState(() {
        _username = newName;
      });
    }
  }
}
