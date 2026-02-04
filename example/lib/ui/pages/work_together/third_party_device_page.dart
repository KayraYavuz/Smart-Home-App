import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class ThirdPartyDevicePage extends StatefulWidget {
  const ThirdPartyDevicePage({super.key});

  @override
  State<ThirdPartyDevicePage> createState() => _ThirdPartyDevicePageState();
}

class _ThirdPartyDevicePageState extends State<ThirdPartyDevicePage> {
  // Demo data for third party devices
  final List<Map<String, dynamic>> _devices = [
    {
      'id': '1',
      'name': 'Salon Işığı',
      'type': 'light',
      'brand': 'Philips Hue',
      'isOn': true,
    },
    {
      'id': '2',
      'name': 'Garaj Kapısı',
      'type': 'garage',
      'brand': 'Nice',
      'isOn': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.thirdPartyDevice,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddDeviceDialog,
          ),
        ],
      ),
      body: _devices.isEmpty
          ? Center(
              child: Text(
                l10n.noDevicesFound,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return _buildDeviceCard(device, l10n);
              },
            ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device, AppLocalizations l10n) {
    IconData icon;
    Color color;

    if (device['type'] == 'light') {
      icon = Icons.lightbulb;
      color = Colors.amber;
    } else if (device['type'] == 'garage') {
      icon = Icons.garage;
      color = Colors.blueGrey;
    } else {
      icon = Icons.device_unknown;
      color = Colors.grey;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          device['name'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          device['brand'],
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Switch.adaptive(
          value: device['isOn'],
          onChanged: (value) {
            setState(() {
              device['isOn'] = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${device['name']} ${value ? l10n.turnedOn : l10n.turnedOff}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          activeTrackColor: Colors.green,
        ),
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(l10n.addDevice, style: const TextStyle(color: Colors.white)),
          content: Text(
            l10n.featureComingSoon,
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok, style: const TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
