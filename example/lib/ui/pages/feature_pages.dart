import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import '../../api_service.dart';
import '../../repositories/auth_repository.dart';


// --- Base Page Structure ---
class FeatureBasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const FeatureBasePage({super.key, required this.title, required this.body, this.actions});

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
  const RemoteListPage({super.key, required this.lockId});

  @override
  State<RemoteListPage> createState() => _RemoteListPageState();
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
      if (!mounted) return;
      setState(() {
        _remotes = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: AppLocalizations.of(context)!.remoteControls,
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
                    title: Text(remote['remoteName'] ?? AppLocalizations.of(context)!.remoteControl, style: const TextStyle(color: Colors.white)),
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
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteErrorWithMsg(e.toString()))));
                          }
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
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.bluetoothAddInstructions)));
           },
         )
       ],
    );
  }
}

// --- Wireless Keypad Page ---
class WirelessKeypadPage extends StatefulWidget {
  final int lockId;
  const WirelessKeypadPage({super.key, required this.lockId});

  @override
  State<WirelessKeypadPage> createState() => _WirelessKeypadPageState();
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
      if (!mounted) return;
      setState(() {
        _keypads = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: AppLocalizations.of(context)!.wirelessKeypads,
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
                    title: Text(keypad['wirelessKeypadName'] ?? AppLocalizations.of(context)!.wirelessKeypad, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('MAC: ${keypad['wirelessKeypadMac']}', style: const TextStyle(color: Colors.grey)),
                     trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                           final api = ApiService(context.read<AuthRepository>());
                           await api.deleteWirelessKeypad(wirelessKeypadId: keypad['wirelessKeypadId']);
                           _loadKeypads();
                        } catch(e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteErrorWithMsg(e.toString()))));
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
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.bluetoothAddInstructions)));
           },
         )
       ],
    );
  }
}

// --- Door Sensor Page ---
class DoorSensorPage extends StatefulWidget {
  final int lockId;
  const DoorSensorPage({super.key, required this.lockId});

  @override
  State<DoorSensorPage> createState() => _DoorSensorPageState();
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
      if (!mounted) return;
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
      title: AppLocalizations.of(context)!.doorSensor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sensor == null
              ? Center(child: Text(AppLocalizations.of(context)!.sensorNotFound, style: const TextStyle(color: Colors.grey)))
              : ListView(
                children: [
                   Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.doorSensor, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('MAC: ${_sensor!['doorSensorMac'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                         try {
                           final api = ApiService(context.read<AuthRepository>());
                           await api.deleteDoorSensor(doorSensorId: _sensor!['doorSensorId']);
                           if (!mounted) return;
                           setState(() {
                             _sensor = null;
                           });
                        } catch(e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteErrorWithMsg(e.toString()))));
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
  const QrCodePage({super.key, required this.lockId});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
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
      if (!mounted) return;
      setState(() {
        _qrCodes = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: $e')));
      }
    }
  }
  
  void _addQrCode() async {
      try {
           final api = ApiService(context.read<AuthRepository>());
           await api.addQrCode(
               lockId: widget.lockId, 
               type: 1, 
               name: AppLocalizations.of(context)!.newQrWithName("${DateTime.now().minute}"),
               startDate: DateTime.now().millisecondsSinceEpoch,
               endDate: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
           );
           _loadQrCodes();
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.qrCodeCreated)));
        } catch(e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: $e')));
        }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: AppLocalizations.of(context)!.qrCodes,
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
                    title: Text(qr['name'] ?? AppLocalizations.of(context)!.qrCode, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('ID: ${qr['qrCodeId']}', style: const TextStyle(color: Colors.grey)),
                    onTap: () async {
                       // Show QR content
                       try {
                           final api = ApiService(context.read<AuthRepository>());
                           final data = await api.getQrCodeData(qrCodeId: qr['qrCodeId']);
                           if (!context.mounted) return;
                           showDialog(
                               context: context, 
                               builder: (c) => AlertDialog(
                                   title: Text(AppLocalizations.of(context)!.qrContent),
                                   content: Text(data['qrCodeContent'] ?? AppLocalizations.of(context)!.empty),
                                   actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(AppLocalizations.of(context)!.ok))],
                               )
                           );
                       } catch (e) {
                           if (!context.mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLabel}: $e')));
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
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteErrorWithMsg(e.toString()))));
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
  const WifiLockPage({super.key, required this.lockId});

  @override
  State<WifiLockPage> createState() => _WifiLockPageState();
}

class _WifiLockPageState extends State<WifiLockPage> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.getWifiLockDetail(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _detail = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        // Optional: still show snackbar or just show in body
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: AppLocalizations.of(context)!.wifiLockDetails,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null 
             ? Center(
                 child: Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                       const SizedBox(height: 16),
                       Text(
                         "This feature is only for locks with built-in Wi-Fi.",
                         textAlign: TextAlign.center,
                         style: const TextStyle(color: Colors.white, fontSize: 16),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         "If you use a Gateway, please check the Gateway menu.",
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey[400]),
                       ),
                       const SizedBox(height: 16),
                       Text(
                         _errorMessage!,
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey[600], fontSize: 12),
                       ),
                     ],
                   ),
                 ),
               )
             : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   if (_detail != null) ...[
                       _buildInfoRow(AppLocalizations.of(context)!.isOnline, _detail!['isOnline'] == true ? AppLocalizations.of(context)!.online : AppLocalizations.of(context)!.offline),
                       _buildInfoRow(AppLocalizations.of(context)!.networkName, _detail!['networkName'] ?? '-'),
                       _buildInfoRow('MAC', _detail!['wifiMac'] ?? '-'),
                       _buildInfoRow('IP', _detail!['ip'] ?? '-'),
                       _buildInfoRow(AppLocalizations.of(context)!.rssiGrade, '${_detail!['rssiGrade'] ?? '0'}'),
                   ] else 
                       Text(AppLocalizations.of(context)!.detailNotFound, style: const TextStyle(color: Colors.white)),
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
