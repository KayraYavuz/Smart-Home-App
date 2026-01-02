import 'package:flutter/material.dart';

class AddDevicePage extends StatelessWidget {
  const AddDevicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for devices
    final Map<String, List<Map<String, dynamic>>> devices = {
      'Kilitler': [
        {'name': 'Tüm kilitler', 'icon': Icons.lock},
        {'name': 'Kapı kilidi', 'icon': Icons.sensor_door},
        {'name': 'Asma kilit', 'icon': Icons.vpn_key},
                    {'name': 'Kasa', 'icon': Icons.lock_outline},      ],
      'Ağ geçidi': [
        {'name': 'G1 Wi-Fi', 'icon': Icons.router},
        {'name': 'G2 Wi-Fi', 'icon': Icons.wifi},
      ],
       'Kamera': [
        {'name': 'Gözetleme Kamerası', 'icon': Icons.videocam},
      ],
    };

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Cihaz ekle'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              child: Icon(device['icon'] as IconData?, color: Color(0xFF1E90FF), size: 30),
            ),
            Expanded(
              child: Text(
                device['name'],
                style: TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
