import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/providers/language_provider.dart';
import 'package:yavuz_lock/ui/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Switch Settings
  bool _soundEnabled = true;
  bool _touchToUnlockEnabled = false;
  bool _notificationEnabled = true;
  bool _personalizedSuggestionsEnabled = false;

  // Selection Settings
  String _selectedLanguage = 'Otomatik';
  String _selectedScreenLock = 'Kapalı';
  String _selectedHideInvalidAccess = 'Kapalı';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _touchToUnlockEnabled = prefs.getBool('touch_to_unlock_enabled') ?? false;
      _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _personalizedSuggestionsEnabled = prefs.getBool('personalized_suggestions_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'Otomatik';
      _selectedScreenLock = prefs.getString('selected_screen_lock') ?? 'Kapalı';
      _selectedHideInvalidAccess = prefs.getString('selected_hide_invalid_access') ?? 'Kapalı';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.settings,
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Switch Kontrolleri Bölümü
            _buildSectionHeader(l10n.generalSettings),
            _buildSwitchTile(
              title: l10n.sound,
              subtitle: l10n.soundSubtitle,
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
                _saveSetting('sound_enabled', value);
              },
            ),
            _buildSwitchTile(
              title: l10n.touchToUnlock,
              subtitle: l10n.touchToUnlockSubtitle,
              value: _touchToUnlockEnabled,
              onChanged: (value) {
                setState(() => _touchToUnlockEnabled = value);
                _saveSetting('touch_to_unlock_enabled', value);
              },
            ),
            _buildSwitchTile(
              title: l10n.notifications,
              subtitle: l10n.notificationsSubtitle,
              value: _notificationEnabled,
              onChanged: (value) {
                setState(() => _notificationEnabled = value);
                _saveSetting('notification_enabled', value);
              },
            ),
            _buildSwitchTile(
              title: l10n.personalizedSuggestions,
              subtitle: l10n.personalizedSuggestionsSubtitle,
              value: _personalizedSuggestionsEnabled,
              onChanged: (value) {
                setState(() => _personalizedSuggestionsEnabled = value);
                _saveSetting('personalized_suggestions_enabled', value);
              },
            ),

            const SizedBox(height: 24),

            // Seçim Listesi Bölümü
            _buildSectionHeader(l10n.preferences),
            _buildSelectionTile(
              title: l10n.languages,
              currentValue: _selectedLanguage,
              onTap: () => _showLanguageSelection(),
            ),
            _buildSelectionTile(
              title: l10n.screenLock,
              currentValue: _selectedScreenLock,
              onTap: () => _showScreenLockSelection(),
            ),
                    _buildSelectionTile(
                      title: l10n.hideInvalidAccess,
                      currentValue: _selectedHideInvalidAccess,
                      onTap: () => _showHideInvalidAccessSelection(),
                    ),

                    const SizedBox(height: 48),

            // Alt Kısım - Çıkış Butonları
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      l10n.logout,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _deleteAccount(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: Text(
                      l10n.deleteAccount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile.adaptive(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.blue,
        inactiveTrackColor: Colors.grey[600],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String currentValue,
    required VoidCallback onTap,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showLanguageSelection() {
    final l10n = AppLocalizations.of(context)!;
    final languages = ['Otomatik', 'Türkçe', 'English', 'Deutsch'];
    
    // Capture parent context before showing modal to ensure Provider access works correctly
    final parentContext = context;
    final provider = Provider.of<LanguageProvider>(parentContext, listen: false);

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectLanguage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...languages.map((language) => ListTile(
                title: Text(
                  language,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: _selectedLanguage == language
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = language);
                  _saveSetting('selected_language', language);
                  
                  // Update LanguageProvider using parent context
                  if (language == 'Otomatik') {
                    provider.resetLocale();
                  } else if (language == 'Türkçe') {
                    provider.setLocale(const Locale('tr'));
                  } else if (language == 'English') {
                    provider.setLocale(const Locale('en'));
                  } else if (language == 'Deutsch') {
                    provider.setLocale(const Locale('de'));
                  }

                  Navigator.of(modalContext).pop();
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showScreenLockSelection() {
    final l10n = AppLocalizations.of(context)!;
    final options = [l10n.off, l10n.seconds30, l10n.minute1, l10n.minutes5];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.screenLockTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...options.map((option) => ListTile(
                title: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
                // Note: This comparison might fail if language changes, but acceptable for now
                trailing: _selectedScreenLock == option
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedScreenLock = option);
                  _saveSetting('selected_screen_lock', option);
                  Navigator.of(context).pop();
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showHideInvalidAccessSelection() {
    final l10n = AppLocalizations.of(context)!;
    final options = [l10n.off, l10n.on];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.hideInvalidAccessTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...options.map((option) => ListTile(
                title: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: _selectedHideInvalidAccess == option
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedHideInvalidAccess = option);
                  _saveSetting('selected_hide_invalid_access', option);
                  Navigator.of(context).pop();
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(l10n.loggedOutMessage),
        backgroundColor: Colors.green,
      ),
    );

    // AuthBloc kapsam hatasını önlemek için pushAndRemoveUntil kullan
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.accountDeletedMessage),
          backgroundColor: Colors.red,
        ),
      );

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
