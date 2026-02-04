import 'package:flutter/material.dart';

class SystemManagementPage extends StatefulWidget {
  const SystemManagementPage({super.key});

  @override
  State<SystemManagementPage> createState() => _SystemManagementPageState();
}

class _SystemManagementPageState extends State<SystemManagementPage> {
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    // Mock data - gerçek uygulamada API'den gelecek
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _groups = [
        {
          'name': 'Gruplanmamış (1)',
          'members': 1,
          'locks': 0,
          'description': 'Atanmamış kilitler ve kullanıcılar',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Sistem Yönetimi',
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
            // Grup Yönetimi Bölümü
            _buildSectionHeader('Grup Yönetimi'),
            ..._groups.map((group) => _buildGroupTile(group)),

            // Yetkili Yönetici Bölümü
            const SizedBox(height: 24),
            _buildSectionHeader('Yetkili Yönetici'),
            _buildAdminManagementSection(),

            // Diğer Sistem Yönetimi Öğeleri
            const SizedBox(height: 24),
            _buildSectionHeader('Kullanıcı Yönetimi'),
            _buildManagementTile(
              icon: Icons.lock_person,
              title: 'Kullanıcıları kilitle',
              subtitle: 'Kilit erişimini yönet ve kullanıcıları engelle',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kullanıcı kilitleme özelliği yakında eklenecek')),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Ağ Geçidi Yönetimi'),
            _buildManagementTile(
              icon: Icons.swap_horiz,
              title: 'Transfer Kilidi',
              subtitle: 'Kilit sahipliğini başka bir hesaba aktar',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kilit transfer özelliği yakında eklenecek')),
                );
              },
            ),
            _buildManagementTile(
              icon: Icons.wifi_tethering,
              title: 'Aktarım Ağ Geçidi',
              subtitle: 'Ağ geçidi sahipliğini başka bir hesaba aktar',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ağ geçidi transfer özelliği yakında eklenecek')),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Veri Yönetimi'),
            _buildManagementTile(
              icon: Icons.file_download,
              title: 'Dışa Aktar',
              subtitle: 'Verileri dışa aktar veya yedekle',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dışa aktarma özelliği yakında eklenecek')),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni grup oluşturma yakında eklenecek')),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
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
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.group,
            color: Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          group['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${group['members']} üye, ${group['locks']} kilit',
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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${group['name']} grubu düzenleniyor')),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAdminManagementSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Veri yok ikonu ve mesajı
          const Icon(
            Icons.document_scanner,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Veri yok',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Yönetici oluştur butonu
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yönetici oluşturma yakında eklenecek')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Yönetici oluştur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
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
          subtitle,
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
