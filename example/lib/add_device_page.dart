import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class AddDevicePage extends StatelessWidget {
  const AddDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Localized data for devices
    final Map<String, List<Map<String, dynamic>>> devices = {
      l10n.categoryLocks: [
        {'name': l10n.deviceAllLocks, 'icon': Icons.lock},
        {'name': l10n.deviceDoorLock, 'icon': Icons.sensor_door},
        {'name': l10n.devicePadlock, 'icon': Icons.vpn_key},
        {'name': l10n.deviceSafe, 'icon': Icons.lock_outline},
      ],
      l10n.categoryGateways: [
        {'name': l10n.deviceGatewayWifi, 'icon': Icons.router},
        {'name': 'G3 Wi-Fi', 'icon': Icons.wifi}, // Assuming this is a model name, kept as is or add translation if needed
      ],
       l10n.categoryCameras: [
        {'name': l10n.deviceCameraSurveillance, 'icon': Icons.videocam},
      ],
    };

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.addDeviceTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: devices.entries.map((entry) {
              return _buildCategorySection(context, entry.key, entry.value);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildDeviceCard(context, items[index]);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, Map<String, dynamic> device) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to specific device scanning page
        print('Tapped on ${device['name']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(device['icon'] as IconData?, color: const Color(0xFF1E90FF), size: 30),
            ),
            Expanded(
              child: Text(
                device['name'],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
