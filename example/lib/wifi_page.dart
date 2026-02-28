import 'package:flutter/material.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'gateway_page.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key, required this.mac});
  final String mac;
  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  List _wifiList = [];
  bool _isScanning = true;
  // BuildContext _context;

  @override
  void initState() {
    super.initState();
    _checkLocationAndScan();
  }

  Future<void> _checkLocationAndScan() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _getNearbyWifi();
    } else {
      debugPrint('Location permission denied, cannot scan wifi.');
      // Wait for build to finish before showing snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.locationPermissionRequiredForWifi ?? 'Wi-Fi taraması için konum izni gereklidir.')),
          );
        }
      });
    }
  }

  void _getNearbyWifi() {
    setState(() => _isScanning = true);
    TTGateway.connect(widget.mac, (status) {
      if (status == TTGatewayConnectStatus.success) {
        TTGateway.getNearbyWifi((finished, wifiList) {
          if (mounted) {
            setState(() {
              _wifiList = wifiList;
              _isScanning = !finished;
            });
          }
        }, (errorCode, errorMsg) {
          if (mounted) {
            setState(() => _isScanning = false);
            debugPrint('Wi-Fi scan failed: $errorMsg');
          }
        });
      } else {
        // Handle connection failure if needed
        debugPrint('Gateway connection failed: $status');
        if (mounted) {
          setState(() => _isScanning = false);
        }
      }
    });
  }

  void _pushGatewayPage(String wifi) {
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return GatewayPage(type: TTGatewayType.g2, wifi: wifi, mac: widget.mac);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.selectWifi ?? 'Select Wifi'),
        ),
        body: Material(child: ProgressHud(
          child: Builder(builder: (context) {
            // _context = context;
            return getList();
          }),
        )));
  }

  Widget getList() {
    if (_isScanning && _wifiList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (!_isScanning && _wifiList.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)?.noWifiNetworksFound ?? 'Bulunan Wi-Fi ağı yok.'));
    }

    return ListView.builder(
        itemCount: _wifiList.length,
        padding: const EdgeInsets.all(5.0),
        itemExtent: 50.0,
        itemBuilder: (context, index) {
          Map wifiMap = _wifiList[index];
          int rssi = wifiMap['rssi'];
          return ListTile(
            title: Text(wifiMap['wifi']),
            subtitle: Text('rssi:$rssi'),
            onTap: () {
              Map wifiMap = _wifiList[index];
              String wifi = wifiMap['wifi'];
              _pushGatewayPage(wifi);
            },
          );
        });
  }
}
