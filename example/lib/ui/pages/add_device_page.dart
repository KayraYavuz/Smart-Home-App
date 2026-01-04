import 'package:flutter/material.dart';
import 'package:ttlock_flutter_example/ui/pages/scan_page.dart';
import 'package:ttlock_flutter_example/api_service.dart';

class AddDevicePage extends StatefulWidget {
  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  bool _isLoadingSeamDevices = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Cihaz Ekle',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTTLockScanSection(context),
            _buildSeamSection(context),
            _buildSection(
              context,
              'Kilitler',
              _buildLockTypes(context),
            ),
            _buildSection(
              context,
              'Ağ geçidi',
              _buildGateways(context),
            ),
            _buildSection(
              context,
              'Kamera',
              _buildCameras(context),
            ),
            _buildSection(
              context,
              'Kapı sensörü',
              _buildDoorSensors(context),
            ),
            _buildSection(
              context,
              'Sayaçlar',
              _buildMeters(context),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSeamSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.api, color: Color(0xFF1E90FF), size: 24),
              SizedBox(width: 12),
              Text(
                'Seam Sandbox Cihazları',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF1E90FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Test',
                  style: TextStyle(
                    color: Color(0xFF1E90FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Seam Connect sandbox ortamındaki test cihazlarını uygulamanıza ekleyin.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoadingSeamDevices ? null : () => _addSeamDevices(context),
                  icon: _isLoadingSeamDevices
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.add_circle_outline),
                  label: Text(_isLoadingSeamDevices ? 'Ekleniyor...' : 'Seam Cihazlarını Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E90FF),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu buton Seam sandbox\'ındaki 3 test kilidini (Lock 0, 1, 2) uygulamanıza ekler.',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTTLockScanSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bluetooth_searching,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'TTLock Kilidi Tara',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Bluetooth ile çevredeki TTLock kilitlerini tara ve uygulamanıza ekleyin.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanPage()),
                ).then((result) {
                  if (result != null && result is Map<String, dynamic>) {
                    // Scan sayfasından geri dönüldü, cihaz eklendi
                    Navigator.of(context).pop(result);
                  }
                });
              },
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'Kilidi Tara',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSeamDevices(BuildContext context) async {
    setState(() {
      _isLoadingSeamDevices = true;
    });

    try {
      final seamDevices = await ApiService.getSandboxDevices();

      // Ana sayfaya Seam cihazlarını eklemek için geri dön
      Navigator.of(context).pop({
        'action': 'add_seam_devices',
        'devices': seamDevices,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${seamDevices.length} Seam cihazı eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seam cihazları eklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSeamDevices = false;
        });
      }
    }
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.5,
            children: items,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLockTypes(BuildContext context) {
    return [
      _buildDeviceButton(context, 'Tüm kilitler', Icons.lock, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Kapı kilidi', Icons.door_front_door, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Asma kilit', Icons.lock_outline, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Güvenli kilit', Icons.security, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Kilit silindiri', Icons.vpn_key, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Park kilidi', Icons.local_parking, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Dolap Kilidi', Icons.inventory_2, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Bisiklet kilidi', Icons.pedal_bike, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
      _buildDeviceButton(context, 'Uzaktan kumanda', Icons.settings_remote, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
      }),
    ];
  }

  List<Widget> _buildGateways(BuildContext context) {
    return [
      _buildDeviceButton(context, 'G1 (Wi-Fi) 2.4G', Icons.router, () {
        _navigateToGatewayScan(context, 'G1');
      }),
      _buildDeviceButton(context, 'G2 (Wi-Fi) 2.4G', Icons.router, () {
        _navigateToGatewayScan(context, 'G2');
      }),
      _buildDeviceButton(context, 'G3 (Kablolu)', Icons.cable, () {
        _navigateToGatewayScan(context, 'G3');
      }),
      _buildDeviceButton(context, 'G4 (4G)', Icons.signal_cellular_4_bar, () {
        _navigateToGatewayScan(context, 'G4');
      }),
      _buildDeviceButton(context, 'G5 (Wi-Fi) 2.4G&5G', Icons.wifi, () {
        _navigateToGatewayScan(context, 'G5');
      }),
      _buildDeviceButton(context, 'G6 (Matter)', Icons.devices, () {
        _navigateToGatewayScan(context, 'G6');
      }),
    ];
  }

  List<Widget> _buildCameras(BuildContext context) {
    return [
      _buildDeviceButton(context, 'TC2', Icons.videocam, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TC2 kamera tarama başlatılıyor...')),
        );
      }),
      _buildDeviceButton(context, 'DB2', Icons.doorbell, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DB2 kapı zili tarama başlatılıyor...')),
        );
      }),
    ];
  }

  List<Widget> _buildDoorSensors(BuildContext context) {
    return [
      _buildDeviceButton(context, 'Kapı sensörü', Icons.sensors, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kapı sensörü tarama başlatılıyor...')),
        );
      }),
    ];
  }

  List<Widget> _buildMeters(BuildContext context) {
    return [
      _buildDeviceButton(context, 'Elektrik', Icons.electrical_services, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Elektrik sayacı tarama başlatılıyor...')),
        );
      }),
      _buildDeviceButton(context, 'Su', Icons.water_drop, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Su sayacı tarama başlatılıyor...')),
        );
      }),
    ];
  }

  Widget _buildDeviceButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(30, 30, 30, 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            Icon(icon, color: Colors.white70, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToGatewayScan(BuildContext context, String gatewayType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanPage(), // TODO: Pass gateway type
      ),
    );
  }
}
