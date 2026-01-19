import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


// --- Base Page Structure ---
class FeatureBasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const FeatureBasePage({Key? key, required this.title, required this.body, this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      body: body,
    );
  }
}

// --- Remote List Page ---
class RemoteListPage extends StatefulWidget {
  final int lockId;
  const RemoteListPage({Key? key, required this.lockId}) : super(key: key);

  @override
  _RemoteListPageState createState() => _RemoteListPageState();
}

class _RemoteListPageState extends State<RemoteListPage> {
  List<dynamic> _remotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRemotes();
  }

  Future<void> _loadRemotes() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.getRemoteList(lockId: widget.lockId);
      setState(() {
        _remotes = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: 'Uzaktan Kumandalar',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _remotes.length,
              itemBuilder: (context, index) {
                final remote = _remotes[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(remote['remoteName'] ?? 'Kumanda', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('ID: ${remote['remoteId']}', style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Implement delete
                        try {
                           final api = ApiService(context.read<AuthRepository>());
                           await api.deleteRemote(remoteId: remote['remoteId']);
                           _loadRemotes();
                        } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
       actions: [
         IconButton(
           icon: const Icon(Icons.add),
           onPressed: () {
             // Add logic would go here (usually needs bluetooth interaction first)
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ekleme işlemi Bluetooth üzerinden başlatılmalı.')));
           },
         )
       ],
    );
  }
}

// --- Wireless Keypad Page ---
class WirelessKeypadPage extends StatefulWidget {
  final int lockId;
  const WirelessKeypadPage({Key? key, required this.lockId}) : super(key: key);

  @override
  _WirelessKeypadPageState createState() => _WirelessKeypadPageState();
}

class _WirelessKeypadPageState extends State<WirelessKeypadPage> {
  List<dynamic> _keypads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeypads();
  }

  Future<void> _loadKeypads() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.getWirelessKeypadList(lockId: widget.lockId);
      setState(() {
        _keypads = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: 'Kablosuz Tuş Takımları',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _keypads.length,
              itemBuilder: (context, index) {
                final keypad = _keypads[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(keypad['wirelessKeypadName'] ?? 'Tuş Takımı', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('MAC: ${keypad['wirelessKeypadMac']}', style: const TextStyle(color: Colors.grey)),
                     trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                           final api = ApiService(context.read<AuthRepository>());
                           await api.deleteWirelessKeypad(wirelessKeypadId: keypad['wirelessKeypadId']);
                           _loadKeypads();
                        } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
             actions: [
         IconButton(
           icon: const Icon(Icons.add),
           onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ekleme işlemi Bluetooth üzerinden başlatılmalı.')));
           },
         )
       ],
    );
  }
}

// --- Door Sensor Page ---
class DoorSensorPage extends StatefulWidget {
  final int lockId;
  const DoorSensorPage({Key? key, required this.lockId}) : super(key: key);

  @override
  _DoorSensorPageState createState() => _DoorSensorPageState();
}

class _DoorSensorPageState extends State<DoorSensorPage> {
  Map<String, dynamic>? _sensor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSensor();
  }

  Future<void> _loadSensor() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.queryDoorSensor(lockId: widget.lockId);
      setState(() {
        _sensor = result; // Assuming result is the sensor object or null if not found (needs proper handling based on API)
        _isLoading = false;
      });
    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
        // API might throw if no sensor, handle gracefully
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: 'Kapı Sensörü',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sensor == null
              ? Center(child: Text('Sensör bulunamadı', style: TextStyle(color: Colors.grey)))
              : ListView(
                children: [
                   Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: const Text('Kapı Sensörü', style: TextStyle(color: Colors.white)),
                    subtitle: Text('MAC: ${_sensor!['doorSensorMac'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                         try {
                           final api = ApiService(context.read<AuthRepository>());
                           await api.deleteDoorSensor(doorSensorId: _sensor!['doorSensorId']);
                           setState(() {
                             _sensor = null;
                           });
                        } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
                        }
                      },
                    ),
                  ),
                )
                ],
              ),
    );
  }
}

// --- QR Code Page ---
class QrCodePage extends StatefulWidget {
  final int lockId;
  const QrCodePage({Key? key, required this.lockId}) : super(key: key);

  @override
  _QrCodePageState createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  List<dynamic> _qrCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQrCodes();
  }

  Future<void> _loadQrCodes() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.getQrCodeList(lockId: widget.lockId);
      setState(() {
        _qrCodes = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
  
  void _addQrCode() async {
      try {
           final api = ApiService(context.read<AuthRepository>());
           await api.addQrCode(
               lockId: widget.lockId, 
               type: 1, 
               name: "Yeni QR (${DateTime.now().minute})",
               startDate: DateTime.now().millisecondsSinceEpoch,
               endDate: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
           );
           _loadQrCodes();
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR Kod oluşturuldu')));
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekleme hatası: $e')));
        }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: 'QR Kodları',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _qrCodes.length,
              itemBuilder: (context, index) {
                final qr = _qrCodes[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(qr['name'] ?? 'QR Kod', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('ID: ${qr['qrCodeId']}', style: const TextStyle(color: Colors.grey)),
                    onTap: () async {
                       // Show QR content
                       try {
                           final api = ApiService(context.read<AuthRepository>());
                           final data = await api.getQrCodeData(qrCodeId: qr['qrCodeId']);
                           showDialog(
                               context: context, 
                               builder: (c) => AlertDialog(
                                   title: const Text('QR İçeriği'),
                                   content: Text(data['qrCodeContent'] ?? 'Boş'),
                                   actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
                               )
                           );
                       } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veri alma hatası: $e')));
                       }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                         try {
                           final api = ApiService(context.read<AuthRepository>());
                           await api.deleteQrCode(lockId: widget.lockId, qrCodeId: qr['qrCodeId']);
                           _loadQrCodes();
                        } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      actions: [
         IconButton(
           icon: const Icon(Icons.add),
           onPressed: _addQrCode,
         )
       ],
    );
  }
}

// --- Wi-Fi Lock Page ---
class WifiLockPage extends StatefulWidget {
  final int lockId;
  const WifiLockPage({Key? key, required this.lockId}) : super(key: key);

  @override
  _WifiLockPageState createState() => _WifiLockPageState();
}

class _WifiLockPageState extends State<WifiLockPage> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.getWifiLockDetail(lockId: widget.lockId);
      setState(() {
        _detail = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: 'Wi-Fi Kilit Detayları',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   if (_detail != null) ...[
                       _buildInfoRow('Online Durumu', _detail!['isOnline'] == true ? 'Online' : 'Offline'),
                       _buildInfoRow('Ağ Adı', _detail!['networkName'] ?? '-'),
                       _buildInfoRow('MAC', _detail!['wifiMac'] ?? '-'),
                       _buildInfoRow('IP', _detail!['ip'] ?? '-'),
                       _buildInfoRow('Sinyal Gücü', '${_detail!['rssiGrade'] ?? '0'}'),
                   ] else 
                       const Text('Detay bulunamadı', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(label, style: const TextStyle(color: Colors.grey)),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }
}
