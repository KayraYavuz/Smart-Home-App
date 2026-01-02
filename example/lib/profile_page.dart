import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildProfileHeader(),
          SizedBox(height: 30),
          _buildMenuItems(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Color(0xFF1E90FF),
          child: Icon(Icons.person, color: Colors.white, size: 40),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ahmetkayrayavuz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ahmet@kayrayavuz.com', // Dummy email
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
        Spacer(),
        IconButton(
          icon: Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.message, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {'icon': Icons.account_circle, 'label': 'Hesap bilgisi'},
      {'icon': Icons.room_service, 'label': 'Hizmetler'},
      {'icon': Icons.mic, 'label': 'Sesli Asistan'},
      {'icon': Icons.system_update, 'label': 'Sistem Yönetimi'},
      {'icon': Icons.workspaces, 'label': 'Birlikte çalışmak'},
      {'icon': Icons.settings, 'label': 'Ayarlar'},
    ];

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return ListTile(
            leading: Icon(item['icon'] as IconData, color: Color(0xFF1E90FF)),
            title: Text(item['label'] as String, style: TextStyle(color: Colors.white)),
            trailing: Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              // TODO: Navigate to the respective page for each item
              print('Tapped on ${item['label']}');
            },
          );
        },
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey[800],
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
      ),
    );
  }
}
