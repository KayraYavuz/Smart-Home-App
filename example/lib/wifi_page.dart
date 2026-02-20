import 'package:flutter/material.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'gateway_page.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key, required this.mac});
  final String mac;
  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  List _wifiList = [];
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
            const SnackBar(content: Text('Wi-Fi taraması için konum izni gereklidir.')),
          );
        }
      });
    }
  }

  void _getNearbyWifi() {
    TTGateway.connect(widget.mac, (status) {
      if (status == TTGatewayConnectStatus.success) {
        TTGateway.getNearbyWifi((finished, wifiList) {
          setState(() {
            _wifiList = wifiList;
          });
        }, (errorCode, errorMsg) {});
      } else {
        // Handle connection failure if needed
        debugPrint('Gateway connection failed: $status');
      }
    });
  }

  void _pushGatewayPage(String wifi) {
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return GatewayPage(type: TTGatewayType.g2, wifi: wifi);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Select Wifi'),
        ),
        body: Material(child: ProgressHud(
          child: Builder(builder: (context) {
            // _context = context;
            return getList();
          }),
        )));
  }

  Widget getList() {
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
