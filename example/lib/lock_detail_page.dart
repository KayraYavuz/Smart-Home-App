import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ttlock_flutter/ttlock.dart';
import 'logs_page.dart';
import 'passcode_page.dart';
import 'card_page.dart';
import 'settings_page.dart'; // To be created

class LockDetailPage extends StatefulWidget {
  const LockDetailPage({Key? key}) : super(key: key);

  @override
  _LockDetailPageState createState() => _LockDetailPageState();
}

class _LockDetailPageState extends State<LockDetailPage> {
  bool isLocked = true;

  void _unlock() {
    setState(() {
      isLocked = false;
    });
    print("Unlock action triggered");
  }

  void _lock() {
    setState(() {
      isLocked = true;
    });
    print("Lock action triggered");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('TTLock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMainControlButton(),
          ),
          _buildBottomActionMenu(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Text(
            'Digital zylinder',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.battery_charging_full, color: Colors.orange, size: 20),
              SizedBox(width: 4),
              Text('%25', style: TextStyle(color: Colors.orange, fontSize: 14)),
              SizedBox(width: 8),
              Icon(Icons.help_outline, color: Colors.white70, size: 22),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMainControlButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _unlock,
          onLongPress: _lock,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E90FF).withOpacity(0.6),
                  blurRadius: 30.0,
                  spreadRadius: 5.0,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF1E90FF).withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: Color(0xFF1E90FF),
                      size: 80,
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF1E90FF),
                    child: Icon(Icons.bluetooth, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Açmak için dokunun, kilitlemek için uzun basın',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBottomActionMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0, top: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.grey[800], height: 1),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.history,
                label: 'Kayıtlar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LogsPage()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.password,
                label: 'Şifreler',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PasscodePage()),
                  );
                },
              ),
               _buildMenuItem(
                context,
                icon: Icons.credit_card,
                label: 'Kartlar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CardPage()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.settings,
                label: 'Ayarlar',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF1E90FF), size: 28),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Color(0xFF1E90FF), fontSize: 14)),
        ],
      ),
    );
  }
}
