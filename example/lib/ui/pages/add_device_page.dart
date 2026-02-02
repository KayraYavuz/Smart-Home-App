import 'package:flutter/material.dart';
import 'package:yavuz_lock/ui/pages/scan_page.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}


class _AddDevicePageState extends State<AddDevicePage> {


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          l10n.addDeviceTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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

            _buildSection(
              context,
              l10n.categoryLocks,
              _buildLockTypes(context),
            ),
            _buildSection(
              context,
              l10n.categoryGateways,
              _buildGateways(context),
            ),
            _buildSection(
              context,
              l10n.categoryCameras,
              _buildCameras(context),
            ),
            _buildSection(
              context,
              l10n.doorSensorMenu.replaceAll('\n', ' '), // Reuse existing if suitable
              _buildDoorSensors(context),
            ),
            _buildSection(
              context,
              l10n.utilityMeter, // Use existing
              _buildMeters(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTTLockScanSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bluetooth_searching,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.scanLockTitle, // 'Yavuz Lock Kilidi Tara' or similar
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bluetooth ile çevredeki Yavuz Lock kilitlerini tara ve uygulamanıza ekleyin.', // TODO: Add to l10n
            style: const TextStyle(
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
                  MaterialPageRoute(builder: (context) => const ScanPage()),
                ).then((result) {
                  if (result != null && result is Map<String, dynamic>) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop(result);
                  }
                });
              },
              icon: const Icon(Icons.search, color: Colors.white),
              label: Text(
                l10n.scanLockTitle,
                style: const TextStyle(color: Colors.white, fontSize: 16),
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



  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
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
            physics: const NeverScrollableScrollPhysics(),
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
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildDeviceButton(context, l10n.deviceAllLocks, Icons.lock, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, l10n.deviceDoorLock, Icons.door_front_door, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, l10n.devicePadlock, Icons.lock_outline, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, l10n.deviceSafe, Icons.security, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, 'Kilit silindiri', Icons.vpn_key, () { // TODO: Add l10n
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, 'Park kilidi', Icons.local_parking, () { // TODO: Add l10n
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, 'Dolap Kilidi', Icons.inventory_2, () { // TODO: Add l10n
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, 'Bisiklet kilidi', Icons.pedal_bike, () { // TODO: Add l10n
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
      _buildDeviceButton(context, 'Uzaktan kumanda', Icons.settings_remote, () { // TODO: Add l10n
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
      }),
    ];
  }

  List<Widget> _buildGateways(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildDeviceButton(context, l10n.deviceGatewayWifi, Icons.router, () {
        _navigateToGatewayScan(context, 'G1');
      }),
      _buildDeviceButton(context, 'G2 (Wi-Fi) 2.4G', Icons.router, () { // Use l10n if added
        _navigateToGatewayScan(context, 'G2');
      }),
      _buildDeviceButton(context, l10n.deviceGatewayG3, Icons.cable, () {
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
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildDeviceButton(context, l10n.deviceCameraSurveillance, Icons.videocam, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TC2 scanning...')),
        );
      }),
      _buildDeviceButton(context, 'DB2', Icons.doorbell, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DB2 scanning...')),
        );
      }),
    ];
  }

  List<Widget> _buildDoorSensors(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildDeviceButton(context, l10n.doorSensor, Icons.sensors, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensor scanning...')),
        );
      }),
    ];
  }

  List<Widget> _buildMeters(BuildContext context) {
    return [
      _buildDeviceButton(context, 'Electric', Icons.electrical_services, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Electric meter scanning...')),
        );
      }),
      _buildDeviceButton(context, 'Water', Icons.water_drop, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water meter scanning...')),
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
          color: const Color.fromRGBO(30, 30, 30, 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToGatewayScan(BuildContext context, String gatewayType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanPage(isGateway: true), 
      ),
    );
  }
}
