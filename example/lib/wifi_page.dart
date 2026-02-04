import 'package:flutter/material.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'gateway_page.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:bmprogresshud/progresshud.dart';

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
    _getNearbyWifi();
  }

  void _getNearbyWifi() {
    // ProgressHud.of(_context).showLoading();
    TTGateway.getNearbyWifi((finished, wifiList) {
      // ProgressHud.of(_context).dismiss();
      setState(() {
        _wifiList = wifiList;
      });
    }, (errorCode, errorMsg) {});
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
