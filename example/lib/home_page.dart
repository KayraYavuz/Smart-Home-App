import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:ttlock_flutter/ttelectricMeter.dart';
import 'package:ttlock_flutter/ttwaterMeter.dart';
import 'scan_page.dart';
import 'config.dart';
import 'lock_detail_page.dart';
import 'add_device_page.dart'; // New import
import 'profile_page.dart';    // New import

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bottomNavIndex = 0;
  BuildContext? _context;

  // Dummy data for multiple locks
  final List<Map<String, dynamic>> _locks = [
    {'name': 'Haustür', 'status': 'Gesperrt', 'isLocked': true, 'battery': 85},
    {'name': 'Bürotür', 'status': 'Offen', 'isLocked': false, 'battery': 60},
    {'name': 'Garagentor', 'status': 'Gesperrt', 'isLocked': true, 'battery': 95},
    {'name': 'Kellertür', 'status': 'Gesperrt', 'isLocked': true, 'battery': 30},
  ];

  void _startScan(ScanType scanType) {
    Navigator.push(context,
        new MaterialPageRoute(builder: (BuildContext context) {
      return ScanPage(
        scanType: scanType,
      );
    }));
  }

  void _addNewDevice() {
    // Navigates to the new AddDevicePage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDevicePage()),
    );
  }

  // Preserved original methods
  void _startScanGateway() {
    if (GatewayConfig.uid == 0 || GatewayConfig.ttlockLoginPassword.isEmpty) {
      String text = 'Please config the ttlockUid and the ttlockLoginPassword';
      ProgressHud.of(_context!)!.showAndDismiss(ProgressHudType.error, text);
      return;
    }
    _startScan(ScanType.gateway);
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

    // The body of the Scaffold will now be determined by the selected page
    final List<Widget> _pages = [
      _buildMainContent(context),
      ProfilePage(), // Using the new ProfilePage widget
    ];

    return ProgressHud(
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            // The body is now one of the pages from the list
            body: SafeArea(
              child: _pages[_bottomNavIndex],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    // This is the content for the first tab (index 0)
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _locks.length,
            itemBuilder: (context, index) {
              return _buildLockListItem(_locks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tüm Kilitler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: _addNewDevice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockListItem(Map<String, dynamic> lock) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: Color.fromRGBO(50, 50, 50, 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LockDetailPage()),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                lock['isLocked'] ? Icons.lock : Icons.lock_open,
                color: lock['isLocked'] ? Color(0xFF1E90FF) : Colors.amber,
                size: 40,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lock['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      lock['status'],
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.battery_5_bar, color: Colors.green, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '${lock['battery']}%',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) => setState(() => _bottomNavIndex = index),
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: Color(0xFF1E90FF),
      unselectedItemColor: Colors.grey[300],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Cihaz'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Ben'),
      ],
    );
  }

}