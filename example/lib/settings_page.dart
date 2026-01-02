import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  // In a real app, you would pass lockData here
  // final String lockData;
  // const SettingsPage({Key? key, required this.lockData}) : super(key: key);
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _showSnackbar(String message) {
    if (mounted) { // Ensure the widget is still mounted before showing Snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _setLockTime() {
    // TODO: Implement real SDK call: TTLock.setLockTime(DateTime.now().millisecondsSinceEpoch, widget.lockData, ...);
    _showSnackbar('Kilit zamanı ayarlanıyor...');
    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return; // Check if mounted before further operations
      _showSnackbar('Kilit zamanı başarıyla ayarlandı.');
    });
  }

  void _getLockTime() {
    // TODO: Implement real SDK call: TTLock.getLockTime(widget.lockData, (time) { ... });
    _showSnackbar('Kilit zamanı alınıyor...');
    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return; // Check if mounted before further operations
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Kilit Zamanı'),
          content: Text('Kilit zamanı: ${DateTime.now()}'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Tamam'))],
        ),
      );
    });
  }

  void _enterDfuMode() {
    // TODO: Implement real SDK call: TTLock.setLockEnterUpgradeMode(widget.lockData, ...);
    // A full DFU implementation requires a DFU file and a library like flutter_nordic_dfu.
    _showSnackbar('Kilit, DFU (güncelleme) moduna geçiriliyor...');
    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return; // Check if mounted before further operations
      _showSnackbar('Kilit şimdi DFU modunda.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('Ayarlar'),
        backgroundColor: Colors.grey[900],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.timer, color: Colors.white70),
            title: Text('Kilit Zamanını Ayarla', style: TextStyle(color: Colors.white)),
            subtitle: Text('Kilit saatini telefonun saatiyle senkronize et', style: TextStyle(color: Colors.grey[400])),
            onTap: _setLockTime,
          ),
          ListTile(
            leading: Icon(Icons.timelapse, color: Colors.white70),
            title: Text('Kilit Zamanını Oku', style: TextStyle(color: Colors.white)),
            subtitle: Text('Kilidin mevcut saatini oku', style: TextStyle(color: Colors.grey[400])),
            onTap: _getLockTime,
          ),
          Divider(color: Colors.grey[800]),
          ListTile(
            leading: Icon(Icons.volume_up, color: Colors.white70),
            title: Text('Ses Seviyesi', style: TextStyle(color: Colors.white)),
            subtitle: Text('Kilit seslerini ayarla', style: TextStyle(color: Colors.grey[400])),
            onTap: () {
              // TODO: Implement volume control dialog and SDK call
               _showSnackbar('Ses ayarı özelliği henüz eklenmedi.');
            },
          ),
           ListTile(
            leading: Icon(Icons.security_update, color: Colors.orangeAccent),
            title: Text('Firmware Güncelleme (DFU)', style: TextStyle(color: Colors.white)),
            subtitle: Text('Kilidi güncelleme moduna geçir', style: TextStyle(color: Colors.grey[400])),
            onTap: _enterDfuMode,
          ),
        ],
      ),
    );
  }
}