import 'package:flutter/material.dart';

class WorkTogetherPage extends StatelessWidget {
  const WorkTogetherPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Birlikte çalışmak',
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildPartnerService(
              icon: Icons.search,
              iconColor: Colors.blue,
              title: 'Kilidi sorgula',
              description: 'Bir kilidin eklenme zamanını sorgula',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kilit sorgulama özelliği yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.electrical_services,
              iconColor: Colors.orange,
              title: 'Utility sayacı',
              description: 'Utility sayacı kullanmak apartman yönetimini daha kolay hale getirir.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utility sayacı özelliği yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.contactless,
              iconColor: Colors.green,
              title: 'Kart kodlayıcı',
              description: 'Ağ geçidi olmadan kart kodlayıcılı sorun kartı',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kart kodlayıcı özelliği yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.hotel,
              iconColor: Colors.purple,
              title: 'Otel PMS',
              description: 'Otel yönetim sistemi',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Otel PMS entegrasyonu yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.devices_other,
              iconColor: Colors.teal,
              title: 'Üçüncü taraf cihaz',
              description: 'Üçüncü taraf cihazlarla kapı aç',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Üçüncü taraf cihaz entegrasyonu yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.home,
              iconColor: Colors.indigo,
              title: 'TTRenting',
              description: 'Long-term Rental Management System',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('TTRenting entegrasyonu yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.code,
              iconColor: Colors.red,
              title: 'Açık platform',
              description: 'APP SDK, Cloud API, DLL',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Açık platform bilgileri yakında eklenecek')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerService({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
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
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}