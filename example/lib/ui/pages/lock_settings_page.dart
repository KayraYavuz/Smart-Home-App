import 'package:flutter/material.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';
import 'package:ttlock_flutter_example/ui/theme.dart';

class LockSettingsPage extends StatefulWidget {
  final Map<String, dynamic> lock;

  const LockSettingsPage({Key? key, required this.lock}) : super(key: key);

  @override
  _LockSettingsPageState createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  late ApiService _apiService;
  bool _isLoading = false;
  
  // Settings values
  bool _passageMode = false;
  String _lockName = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(AuthRepository());
    _lockName = widget.lock['name'] ?? '';
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final lockId = widget.lock['lockId'].toString();
      
      // Fetch Passage Mode
      final passageConfig = await _apiService.getPassageModeConfiguration(lockId: lockId);

      setState(() {
        _passageMode = passageConfig['passageMode'] == 1;
      });
    } catch (e) {
      print('Error fetching settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kilit Ayarları'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Genel'),
              _buildSettingTile(
                icon: Icons.edit,
                title: 'Kilit Adı',
                subtitle: _lockName,
                onTap: _renameLock,
              ),
              _buildSettingTile(
                icon: Icons.battery_charging_full,
                title: 'Batarya Durumunu Güncelle',
                subtitle: 'Sunucu ile senkronize et',
                onTap: _updateBattery,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Kilitlenme Ayarları'),
              _buildSettingTile(
                icon: Icons.timer,
                title: 'Otomatik Kilitlenme',
                subtitle: 'Süre ayarla',
                onTap: _showAutoLockDialog,
              ),
              _buildSwitchTile(
                icon: Icons.door_front_door,
                title: 'Passage Modu',
                subtitle: 'Belirli saatlerde kilit açık kalsın',
                value: _passageMode,
                onChanged: (val) => _togglePassageMode(val),
              ),
              _buildSettingTile(
                icon: Icons.work_history,
                title: 'Çalışma Saatleri',
                subtitle: 'Çalışma/Donma modlarını yapılandır',
                onTap: _showWorkingModeSettings,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Güvenlik'),
              _buildSettingTile(
                icon: Icons.password,
                title: 'Admin Şifresini Değiştir',
                subtitle: 'Super Passcode güncelle',
                onTap: _changeAdminPasscode,
              ),
              _buildSettingTile(
                icon: Icons.swap_horiz,
                title: 'Kilidi Transfer Et',
                subtitle: 'Başka bir kullanıcıya devret',
                onTap: _transferLock,
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: _deleteLock,
                child: const Text('KİLİDİ SİL'),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  // Action Methods
  void _renameLock() {
    final controller = TextEditingController(text: _lockName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilidi Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Yeni İsim'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              final newName = controller.text;
              if (newName.isNotEmpty) {
                await _apiService.renameLock(lockId: widget.lock['lockId'].toString(), newName: newName);
                setState(() => _lockName = newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _updateBattery() async {
    setState(() => _isLoading = true);
    try {
      // Simulation: assuming we read battery via SDK first
      await _apiService.updateElectricQuantity(
        lockId: widget.lock['lockId'].toString(),
        electricQuantity: widget.lock['battery'] ?? 100,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batarya senkronize edildi')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAutoLockDialog() {
    int seconds = 5;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otomatik Kilitlenme Süresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saniye cinsinden süre girin (0 kapatır)'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (val) => seconds = int.tryParse(val) ?? 5,
              decoration: const InputDecoration(suffixText: 'sn'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await _apiService.setAutoLockTime(
                lockId: widget.lock['lockId'].toString(),
                seconds: seconds,
                type: 2, // Gateway/WiFi simulation
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Süre ayarlandı')));
            },
            child: const Text('Ayarla'),
          ),
        ],
      ),
    );
  }

  void _togglePassageMode(bool val) async {
    try {
      await _apiService.configurePassageMode(
        lockId: widget.lock['lockId'].toString(),
        passageMode: val ? 1 : 2,
        type: 2,
      );
      setState(() => _passageMode = val);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _showWorkingModeSettings() {
    // This could be a complex dialog or a separate page. For simplicity, let's show a basic choice.
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Çalışma Modu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Sürekli Çalışır (Default)'),
              onTap: () => _setWorkingMode(1),
            ),
            ListTile(
              title: const Text('Donma Modu (Kilitli Kalır)'),
              onTap: () => _setWorkingMode(2),
            ),
            ListTile(
              title: const Text('Özel Saatler'),
              onTap: () {
                Navigator.pop(context);
                // Implementation for custom hours...
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setWorkingMode(int mode) async {
    try {
      await _apiService.configWorkingMode(
        lockId: widget.lock['lockId'].toString(),
        workingMode: mode,
        type: 2,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mod güncellendi')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _changeAdminPasscode() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Şifresini Değiştir'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Yeni Şifre'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _apiService.changeAdminKeyboardPwd(
                  lockId: widget.lock['lockId'].toString(),
                  password: controller.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre güncellendi')));
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _transferLock() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilidi Transfer Et'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Alıcı Kullanıcı Adı'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _apiService.transferLock(
                  lockIdList: [int.parse(widget.lock['lockId'].toString())],
                  receiverUsername: controller.text,
                );
                Navigator.pop(context);
                Navigator.pop(context); // Close settings page
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer işlemi başlatıldı')));
              }
            },
            child: const Text('Transfer Et'),
          ),
        ],
      ),
    );
  }

  void _deleteLock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilidi Sil?'),
        content: const Text('DİKKAT: Bu işlem kilidi sunucudan tamamen siler. Önce SDK üzerinden donanımsal resetleme yapmanız önerilir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await _apiService.deleteLock(lockId: widget.lock['lockId'].toString());
              Navigator.pop(context);
              Navigator.pop(context, 'deleted'); // Go back to list
            },
            child: const Text('SİL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
