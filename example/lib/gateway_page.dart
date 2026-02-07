import 'package:flutter/material.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';

import 'config.dart';

class GatewayPage extends StatefulWidget {
  const GatewayPage({super.key, required this.type, this.wifi});
  final String? wifi;
  final TTGatewayType type;
  @override
  State<GatewayPage> createState() => _GatewayPageState();
}

class _GatewayPageState extends State<GatewayPage> {
  BuildContext? _context;
  String? _wifiPassword;

  @override
  void initState() {
    super.initState();
  }

  void _showLoading() {
    ProgressHud.of(_context!)!.showLoading();
  }

  void _showAndDismiss(ProgressHudType type, String text) {
    ProgressHud.of(_context!)!.showAndDismiss(type, text);
  }

  void _initGateway_2(String? wifi, String? wifiPassword) {
    if (widget.wifi == null || wifiPassword == null || wifiPassword.isEmpty) {
      _showAndDismiss(ProgressHudType.error, 'wifi or password cant be empty');
      return;
    }

    Map paramMap = {};
    paramMap["wifi"] = wifi;
    paramMap["wifiPassword"] = wifiPassword;
    paramMap["type"] = widget.type.index;
    paramMap["gatewayName"] = GatewayConfig.gatewayName;
    paramMap["uid"] = GatewayConfig.uid;
    paramMap["ttlockLoginPassword"] = GatewayConfig.ttlockLoginPassword;
    _initGateway(paramMap);
  }

  void _initGateway_3_4() {
    Map paramMap = {};
    paramMap["type"] = widget.type.index;
    paramMap["gatewayName"] = GatewayConfig.gatewayName;
    paramMap["uid"] = GatewayConfig.uid;
    paramMap["ttlockLoginPassword"] = GatewayConfig.ttlockLoginPassword;
    _initGateway(paramMap);
  }

  void _initGateway(Map paramMap) {
    // test account.  ttlockUid = 17498, ttlockLoginPassword = "1111111"
    // if (Config.ttlockUid == 17498) {
    //   String errorDesc =
    //       "Please config ttlockUid and ttlockLoginPassword. Reference documentation ‘https://open.sciener.com/doc/api/v3/user/getUid’";
    //   _showAndDismiss(ProgressHudType.error, errorDesc);
    //   debugPrint(errorDesc);
    //   return;
    // }

    _showLoading();
    TTGateway.init(paramMap, (map) {
      debugPrint("网关添加结果");
      debugPrint(map.toString());
      _showAndDismiss(ProgressHudType.success, 'Init Gateway Success');
    }, (errorCode, errorMsg) {
      _showAndDismiss(
          ProgressHudType.error, 'errorCode:$errorCode msg:$errorMsg');
      if (errorCode == TTGatewayError.notConnect ||
          errorCode == TTGatewayError.disconnect) {
        debugPrint("Please repower  and connect the gateway again");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Gateway"),
        ),
        body: Material(child: ProgressHud(
          child: Builder(builder: (context) {
            _context = context;
            return getChild();
          }),
        )));
  }

  Widget getChild() {
    TextField wifiTextField = TextField(
      textAlign: TextAlign.center,
      controller: TextEditingController(text: widget.wifi),
      enabled: false,
    );

    TextField wifiPasswordTextField = TextField(
        textAlign: TextAlign.center,
        controller: TextEditingController(text: _wifiPassword),
        decoration: const InputDecoration(hintText: 'Input wifi password'),
        onChanged: (String content) {
          _wifiPassword = content;
        });

    ElevatedButton initGatewayButton = ElevatedButton(
      child: const Text('Init Gateway'),
      onPressed: () {
        FocusScope.of(_context!).requestFocus(FocusNode());
        //g2
        if (widget.type == TTGatewayType.g2) {
          _initGateway_2(widget.wifi, _wifiPassword);
        } else {
          //g3 g4
          _initGateway_3_4();
        }
      },
    );

    if (widget.type == TTGatewayType.g2) {
      return Column(
        children: <Widget>[
          wifiTextField,
          wifiPasswordTextField,
          initGatewayButton
        ],
      );
    } else {
      return Center(child: initGatewayButton);
    }
  }
}
