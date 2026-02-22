import 'package:flutter/material.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'config.dart';

class GatewayPage extends StatefulWidget {
  const GatewayPage({super.key, required this.type, this.wifi, required this.mac});
  final String? wifi;
  final TTGatewayType type;
  final String mac;
  @override
  State<GatewayPage> createState() => _GatewayPageState();
}

class _GatewayPageState extends State<GatewayPage> {
  String? _wifiPassword;
  String _gatewayName = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<void> _initGateway_2(String? wifi, String? wifiPassword) async {
    if (widget.wifi == null || wifiPassword == null || wifiPassword.isEmpty) {
      _showSnackBar('Wi-Fi ağı veya şifre boş olamaz', isError: true);
      return;
    }
    if (_gatewayName.isEmpty) {
      _showSnackBar('Lütfen bir ağ geçidi adı girin', isError: true);
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    final uid = await apiService.getUid();
    final pw = await apiService.getMd5Password();

    if (uid == null || pw == null) {
      _showSnackBar('Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.', isError: true);
      return;
    }

    Map paramMap = {};
    paramMap["mac"] = widget.mac;
    paramMap["wifi"] = wifi;
    paramMap["wifiPassword"] = wifiPassword;
    paramMap["type"] = widget.type.index;
    paramMap["gatewayName"] = _gatewayName;
    paramMap["uid"] = uid;
    paramMap["ttlockLoginPassword"] = pw;
    _initGateway(paramMap);
  }

  Future<void> _initGateway_3_4() async {
    if (_gatewayName.isEmpty) {
      _showSnackBar('Lütfen bir ağ geçidi adı girin', isError: true);
      return;
    }

    final apiService = Provider.of<ApiService>(context, listen: false);
    final uid = await apiService.getUid();
    final pw = await apiService.getMd5Password();

    if (uid == null || pw == null) {
      _showSnackBar('Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.', isError: true);
      return;
    }

    Map paramMap = {};
    paramMap["mac"] = widget.mac;
    paramMap["type"] = widget.type.index;
    paramMap["gatewayName"] = _gatewayName;
    paramMap["uid"] = uid;
    paramMap["ttlockLoginPassword"] = pw;
    _initGateway(paramMap);
  }

  void _initGateway(Map paramMap) {
    setState(() => _isLoading = true);
    debugPrint("Gateway INIT START: paramMap=$paramMap");
    
    // Güvenlik amaçlı 60 saniyelik zaman aşımı (Native SDK takılırsa diye)
    bool _isCallbackFired = false;
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && _isLoading && !_isCallbackFired) {
        debugPrint("Gateway INIT TIMEOUT");
        _isCallbackFired = true;
        setState(() => _isLoading = false);
        _showSnackBar('Bağlantı zaman aşımına uğradı. Lütfen ağ geçidini sıfırlayıp ağı kontrol edin.', isError: true);
      }
    });

    TTGateway.init(paramMap, (map) async {
      if (_isCallbackFired) return;
      _isCallbackFired = true;
      debugPrint("Gateway add SDK result: $map");
      
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.initGateway(
          gatewayNetMac: map['mac'] ?? '',
          modelNum: map['modelNum'] ?? '',
          hardwareRevision: map['hardwareRevision'] ?? '',
          firmwareRevision: map['firmwareRevision'] ?? '',
        );

        if (mounted) {
          _showSnackBar('Ağ geçidi başarıyla eklendi ve sunucuya kaydedildi!');
          setState(() => _isLoading = false);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          debugPrint("Gateway Server Upload Error: $e");
          _showSnackBar('Ağ geçidi cihaza eklendi ancak sunucuya kaydedilemedi: $e', isError: true);
          setState(() => _isLoading = false);
        }
      }
    }, (errorCode, errorMsg) {
      if (_isCallbackFired) return;
      _isCallbackFired = true;
      if (mounted) {
        debugPrint("Gateway INIT ERROR: errorCode=$errorCode, msg=$errorMsg");
        setState(() => _isLoading = false);
        _showSnackBar('Hata: $errorCode - $errorMsg', isError: true);
        if (errorCode == TTGatewayError.notConnect ||
            errorCode == TTGatewayError.disconnect) {
          debugPrint("Lütfen ağ geçidini yeniden başlatıp tekrar bağlanın.");
        } else if (errorCode == TTGatewayError.fail) {
           _showSnackBar('Lütfen Wi-Fi ve konum/bluetooth izinlerini kontrol edin.', isError: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Ağ Geçidi Ekle"),
        ),
        body: _isLoading 
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Ağ geçidi başlatılıyor, lütfen bekleyin..."),
                  ],
                ),
              )
            : getChild()
    );
  }

  Widget getChild() {
    TextField nameTextField = TextField(
      textAlign: TextAlign.center,
      controller: TextEditingController(text: _gatewayName),
      decoration: const InputDecoration(hintText: 'Ağ Geçidi Adı (örn: Ev)'),
      onChanged: (String content) {
        _gatewayName = content;
      },
    );

    TextField wifiTextField = TextField(
      textAlign: TextAlign.center,
      controller: TextEditingController(text: widget.wifi),
      enabled: false,
      decoration: const InputDecoration(labelText: 'Seçili Wi-Fi Ağı'),
    );

    TextField wifiPasswordTextField = TextField(
        textAlign: TextAlign.center,
        controller: TextEditingController(text: _wifiPassword),
        decoration: const InputDecoration(hintText: 'Wi-Fi Şifresini Girin'),
        obscureText: false,
        onChanged: (String content) {
          _wifiPassword = content;
        });

    ElevatedButton initGatewayButton = ElevatedButton(
      child: const Text('Bağlan ve Ekle'),
      onPressed: () {
        FocusScope.of(context).requestFocus(FocusNode());
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
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            nameTextField,
            const SizedBox(height: 20),
            wifiTextField,
            const SizedBox(height: 20),
            wifiPasswordTextField,
            const SizedBox(height: 40),
            initGatewayButton
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            nameTextField,
            const SizedBox(height: 40),
            initGatewayButton
          ],
        ),
      );
    }
  }
}

