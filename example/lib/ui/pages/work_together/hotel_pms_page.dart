import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class HotelPMSPage extends StatefulWidget {
  const HotelPMSPage({super.key});

  @override
  _HotelPMSPageState createState() => _HotelPMSPageState();
}

class _HotelPMSPageState extends State<HotelPMSPage> {
  // Demo data for hotel rooms
  final List<Map<String, dynamic>> _rooms = [
    {'number': '101', 'status': 'occupied', 'guest': 'Misafir A'},
    {'number': '102', 'status': 'vacant', 'guest': null},
    {'number': '103', 'status': 'cleaning', 'guest': null},
    {'number': '201', 'status': 'vacant', 'guest': null},
    {'number': '202', 'status': 'occupied', 'guest': 'Misafir B'},
    {'number': '203', 'status': 'vacant', 'guest': null},
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
          l10n.hotelPMS,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return _buildRoomCard(room, l10n);
        },
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room, AppLocalizations l10n) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (room['status']) {
      case 'occupied':
        statusColor = Colors.redAccent;
        statusText = l10n.occupied;
        statusIcon = Icons.person;
        break;
      case 'cleaning':
        statusColor = Colors.orangeAccent;
        statusText = l10n.cleaning;
        statusIcon = Icons.cleaning_services;
        break;
      case 'vacant':
      default:
        statusColor = Colors.green;
        statusText = l10n.vacant;
        statusIcon = Icons.meeting_room;
        break;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _showRoomActionDialog(room, l10n),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room['number'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              if (room['guest'] != null)
                Text(
                  room['guest'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomActionDialog(Map<String, dynamic> room, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        if (room['status'] == 'vacant') {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text('${l10n.checkIn} - ${room['number']}', style: const TextStyle(color: Colors.white)),
            content: Text(l10n.checkInConfirm, style: const TextStyle(color: Colors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    room['status'] = 'occupied';
                    room['guest'] = 'Yeni Misafir';
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.checkInSuccess)),
                  );
                },
                child: Text(l10n.checkIn, style: const TextStyle(color: Colors.blue)),
              ),
            ],
          );
        } else if (room['status'] == 'occupied') {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text('${l10n.checkOut} - ${room['number']}', style: const TextStyle(color: Colors.white)),
            content: Text(l10n.checkOutConfirm, style: const TextStyle(color: Colors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    room['status'] = 'cleaning';
                    room['guest'] = null;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.checkOutSuccess)),
                  );
                },
                child: Text(l10n.checkOut, style: const TextStyle(color: Colors.red)),
              ),
            ],
          );
        } else {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text('${l10n.roomCleaning} - ${room['number']}', style: const TextStyle(color: Colors.white)),
            content: Text(l10n.finishCleaningConfirm, style: const TextStyle(color: Colors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    room['status'] = 'vacant';
                  });
                  Navigator.pop(context);
                },
                child: Text(l10n.finish, style: const TextStyle(color: Colors.green)),
              ),
            ],
          );
        }
      },
    );
  }
}
