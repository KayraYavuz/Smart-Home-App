import 'package:flutter/material.dart';
import 'package:ttlock_flutter/ttelectricMeter.dart';
import 'package:ttlock_flutter/ttwaterMeter.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/config.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';

String _t(BuildContext context, {required String tr, required String en}) {
  return Localizations.localeOf(context).languageCode == 'tr' ? tr : en;
}

class UtilityMeterPage extends StatefulWidget {
  const UtilityMeterPage({super.key});

  @override
  State<UtilityMeterPage> createState() => _UtilityMeterPageState();
}

class _UtilityMeterPageState extends State<UtilityMeterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ApiService _api;

  // Electric meters discovered via BLE scan
  final List<TTElectricMeterScanModel> _electricMeters = [];
  // Water meters discovered via BLE scan
  final List<TTWaterMeterScanModel> _waterMeters = [];

  bool _isScanningElectric = false;
  bool _isScanningWater = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _api = ApiService(AuthRepository());
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isScanningElectric) TTElectricMeter.stopScan();
    if (_isScanningWater) TTWaterMeter.stopScan();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _startElectricScan() async {
    setState(() {
      _isScanningElectric = true;
      _electricMeters.clear();
    });

    try {
      await _api.getAccessToken();
      final token = _api.accessToken ?? '';

      final params = ElectricMeterServerParamMode();
      params.url = ApiConfig.baseUrl;
      params.clientId = ApiConfig.clientId;
      params.accessToken = token;
      TTElectricMeter.configServer(params);

      TTElectricMeter.startScan((model) {
        if (!mounted) return;
        setState(() {
          final idx = _electricMeters.indexWhere((m) => m.mac == model.mac);
          if (idx >= 0) {
            _electricMeters[idx] = model;
          } else {
            _electricMeters.add(model);
          }
        });
      });

      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isScanningElectric) _stopElectricScan();
      });
    } catch (e) {
      _snack(_t(context, tr: 'Tarama başlatılamadı: $e', en: 'Scan failed: $e'),
          error: true);
      setState(() => _isScanningElectric = false);
    }
  }

  void _stopElectricScan() {
    TTElectricMeter.stopScan();
    if (mounted) setState(() => _isScanningElectric = false);
  }

  Future<void> _startWaterScan() async {
    setState(() {
      _isScanningWater = true;
      _waterMeters.clear();
    });

    try {
      await _api.getAccessToken();
      final token = _api.accessToken ?? '';

      final params = WaterMeterServerParamMode();
      params.url = ApiConfig.baseUrl;
      params.clientId = ApiConfig.clientId;
      params.accessToken = token;
      TTWaterMeter.configServer(params);

      TTWaterMeter.startScan((model) {
        if (!mounted) return;
        setState(() {
          final idx = _waterMeters.indexWhere((m) => m.mac == model.mac);
          if (idx >= 0) {
            _waterMeters[idx] = model;
          } else {
            _waterMeters.add(model);
          }
        });
      });

      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isScanningWater) _stopWaterScan();
      });
    } catch (e) {
      _snack(_t(context, tr: 'Tarama başlatılamadı: $e', en: 'Scan failed: $e'),
          error: true);
      setState(() => _isScanningWater = false);
    }
  }

  void _stopWaterScan() {
    TTWaterMeter.stopScan();
    if (mounted) setState(() => _isScanningWater = false);
  }

  Future<void> _initElectricMeter(TTElectricMeterScanModel model) async {
    final priceCtrl = TextEditingController(text: '1.0');
    TTMeterPayMode payMode = TTMeterPayMode.postpaid;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(_t(ctx, tr: 'Sayacı Başlat', en: 'Initialize Meter'),
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _t(ctx, tr: 'Birim Fiyat (kWh)', en: 'Unit Price (kWh)'),
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(_t(ctx, tr: 'Ödeme Modu:', en: 'Pay Mode:'),
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  DropdownButton<TTMeterPayMode>(
                    value: payMode,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(
                        value: TTMeterPayMode.postpaid,
                        child: Text(_t(ctx, tr: 'Sonra Öde', en: 'Postpaid')),
                      ),
                      DropdownMenuItem(
                        value: TTMeterPayMode.prepaid,
                        child: Text(_t(ctx, tr: 'Ön Ödemeli', en: 'Prepaid')),
                      ),
                    ],
                    onChanged: (v) => setSt(() => payMode = v ?? TTMeterPayMode.postpaid),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                    style: const TextStyle(color: Colors.grey))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_t(ctx, tr: 'Başlat', en: 'Initialize'),
                    style: const TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    final paramMap = {
      'mac': model.mac,
      'price': priceCtrl.text.trim(),
      'payMode': payMode.index,
      'number': model.name.isEmpty ? model.mac : model.name,
    };

    TTElectricMeter.init(
      paramMap,
      () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack(_t(context, tr: 'Sayaç başlatıldı', en: 'Meter initialized'));
      },
      (code, msg) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack(_t(context, tr: 'Başlatma hatası: $msg', en: 'Init failed: $msg'),
            error: true);
      },
    );
  }

  Future<void> _initWaterMeter(TTWaterMeterScanModel model) async {
    final priceCtrl = TextEditingController(text: '1.0');
    TTMeterPayMode payMode = TTMeterPayMode.postpaid;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(_t(ctx, tr: 'Sayacı Başlat', en: 'Initialize Meter'),
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      _t(ctx, tr: 'Birim Fiyat (m³)', en: 'Unit Price (m³)'),
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(_t(ctx, tr: 'Ödeme Modu:', en: 'Pay Mode:'),
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  DropdownButton<TTMeterPayMode>(
                    value: payMode,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(
                        value: TTMeterPayMode.postpaid,
                        child: Text(_t(ctx, tr: 'Sonra Öde', en: 'Postpaid')),
                      ),
                      DropdownMenuItem(
                        value: TTMeterPayMode.prepaid,
                        child: Text(_t(ctx, tr: 'Ön Ödemeli', en: 'Prepaid')),
                      ),
                    ],
                    onChanged: (v) => setSt(() => payMode = v ?? TTMeterPayMode.postpaid),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                    style: const TextStyle(color: Colors.grey))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_t(ctx, tr: 'Başlat', en: 'Initialize'),
                    style: const TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    final paramMap = {
      'mac': model.mac,
      'price': priceCtrl.text.trim(),
      'payMode': payMode.index,
      'number': model.name.isEmpty ? model.mac : model.name,
    };

    TTWaterMeter.init(
      paramMap,
      () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack(_t(context, tr: 'Sayaç başlatıldı', en: 'Meter initialized'));
      },
      (code, msg) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack(_t(context, tr: 'Başlatma hatası: $msg', en: 'Init failed: $msg'),
            error: true);
      },
    );
  }

  void _showElectricDetail(TTElectricMeterScanModel model) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ElectricMeterDetailSheet(
        model: model,
        onPowerToggle: (isOn) {
          setState(() => _isLoading = true);
          TTElectricMeter.setPowerOnOff(
            model.mac,
            isOn,
            () {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx,
                  tr: isOn ? 'Güç açıldı' : 'Güç kapatıldı',
                  en: isOn ? 'Power on' : 'Power off'));
            },
            (code, msg) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx, tr: 'Güç değiştirilemedi: $msg', en: 'Power toggle failed: $msg'),
                  error: true);
            },
          );
        },
        onRecharge: (amount, kwh) {
          setState(() => _isLoading = true);
          TTElectricMeter.recharge(
            model.mac,
            amount,
            kwh,
            () {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx, tr: 'Yükleme başarılı', en: 'Recharge successful'));
            },
            (code, msg) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx, tr: 'Yükleme hatası: $msg', en: 'Recharge failed: $msg'),
                  error: true);
            },
          );
        },
        onDisconnect: () {
          TTElectricMeter.disconnect(model.mac);
          Navigator.pop(ctx);
          _snack(_t(context, tr: 'Bağlantı kesildi', en: 'Disconnected'));
        },
      ),
    );
  }

  void _showWaterDetail(TTWaterMeterScanModel model) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _WaterMeterDetailSheet(
        model: model,
        onPowerToggle: (isOn) {
          setState(() => _isLoading = true);
          TTWaterMeter.setPowerOnOff(
            model.mac,
            isOn,
            () {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx,
                  tr: isOn ? 'Vana açıldı' : 'Vana kapatıldı',
                  en: isOn ? 'Valve opened' : 'Valve closed'));
            },
            (code, msg) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx, tr: 'Vana değiştirilemedi: $msg', en: 'Valve toggle failed: $msg'),
                  error: true);
            },
          );
        },
        onRecharge: (amount, m3) {
          setState(() => _isLoading = true);
          TTWaterMeter.recharge(
            model.mac,
            amount,
            m3,
            () {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx, tr: 'Yükleme başarılı', en: 'Recharge successful'));
            },
            (code, msg) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _snack(_t(ctx, tr: 'Yükleme hatası: $msg', en: 'Recharge failed: $msg'),
                  error: true);
            },
          );
        },
        onDisconnect: () {
          TTWaterMeter.disconnect(model.mac);
          Navigator.pop(ctx);
          _snack(_t(context, tr: 'Bağlantı kesildi', en: 'Disconnected'));
        },
      ),
    );
  }

  Widget _buildElectricTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isScanningElectric
                      ? _t(context, tr: 'Elektrik sayaçları aranıyor...', en: 'Scanning for electric meters...')
                      : _t(context,
                          tr: '${_electricMeters.length} sayaç bulundu',
                          en: '${_electricMeters.length} meter(s) found'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isScanningElectric ? _stopElectricScan : _startElectricScan,
                icon: Icon(_isScanningElectric ? Icons.stop : Icons.search, size: 18),
                label: Text(_isScanningElectric
                    ? _t(context, tr: 'Durdur', en: 'Stop')
                    : _t(context, tr: 'Tara', en: 'Scan')),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isScanningElectric ? Colors.red : AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (_isScanningElectric && _electricMeters.isEmpty)
          const Expanded(
              child: Center(child: CircularProgressIndicator())),
        if (!_isScanningElectric && _electricMeters.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _t(context,
                    tr: 'Bluetooth elektrik sayacı bulunamadı.\nTaramayı başlatın.',
                    en: 'No electric meters found.\nStart a scan to discover nearby devices.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _electricMeters.length,
            itemBuilder: (ctx, i) {
              final m = _electricMeters[i];
              return _ElectricMeterCard(
                model: m,
                onTap: m.isInited ? () => _showElectricDetail(m) : null,
                onInit: m.isInited ? null : () => _initElectricMeter(m),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isScanningWater
                      ? _t(context, tr: 'Su sayaçları aranıyor...', en: 'Scanning for water meters...')
                      : _t(context,
                          tr: '${_waterMeters.length} sayaç bulundu',
                          en: '${_waterMeters.length} meter(s) found'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isScanningWater ? _stopWaterScan : _startWaterScan,
                icon: Icon(_isScanningWater ? Icons.stop : Icons.search, size: 18),
                label: Text(_isScanningWater
                    ? _t(context, tr: 'Durdur', en: 'Stop')
                    : _t(context, tr: 'Tara', en: 'Scan')),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isScanningWater ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_isScanningWater && _waterMeters.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator())),
        if (!_isScanningWater && _waterMeters.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _t(context,
                    tr: 'Bluetooth su sayacı bulunamadı.\nTaramayı başlatın.',
                    en: 'No water meters found.\nStart a scan to discover nearby devices.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _waterMeters.length,
            itemBuilder: (ctx, i) {
              final m = _waterMeters[i];
              return _WaterMeterCard(
                model: m,
                onTap: m.isInited ? () => _showWaterDetail(m) : null,
                onInit: m.isInited ? null : () => _initWaterMeter(m),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          _t(context, tr: 'Utility Sayacı', en: 'Utility Meter'),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: const Icon(Icons.electrical_services),
              text: _t(context, tr: 'Elektrik', en: 'Electric'),
            ),
            Tab(
              icon: const Icon(Icons.water_drop),
              text: _t(context, tr: 'Su', en: 'Water'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildElectricTab(),
              _buildWaterTab(),
            ],
          ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// --- Electric Meter Card ---
class _ElectricMeterCard extends StatelessWidget {
  final TTElectricMeterScanModel model;
  final VoidCallback? onTap;
  final VoidCallback? onInit;

  const _ElectricMeterCard({required this.model, this.onTap, this.onInit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  model.onOff ? Icons.electrical_services : Icons.power_off,
                  color: model.onOff ? Colors.orange : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name.isEmpty ? model.mac : model.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (model.isInited) ...[
                      Text(
                        _t(context,
                            tr: 'Toplam: ${model.totalKwh} kWh  |  Kalan: ${model.remainderKwh} kWh',
                            en: 'Total: ${model.totalKwh} kWh  |  Remaining: ${model.remainderKwh} kWh'),
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      Text(
                        _t(context,
                            tr: '${model.voltage}V  ${model.electricCurrent}A',
                            en: '${model.voltage}V  ${model.electricCurrent}A'),
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ] else
                      Text(
                        _t(context,
                            tr: 'Başlatılmamış', en: 'Not initialized'),
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (!model.isInited && onInit != null)
                TextButton(
                  onPressed: onInit,
                  child: Text(
                    _t(context, tr: 'Başlat', en: 'Init'),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Water Meter Card ---
class _WaterMeterCard extends StatelessWidget {
  final TTWaterMeterScanModel model;
  final VoidCallback? onTap;
  final VoidCallback? onInit;

  const _WaterMeterCard({required this.model, this.onTap, this.onInit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  model.onOff ? Icons.water_drop : Icons.water_drop_outlined,
                  color: model.onOff ? Colors.blue : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name.isEmpty ? model.mac : model.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (model.isInited) ...[
                      Text(
                        _t(context,
                            tr: 'Toplam: ${model.totalM3} m³  |  Kalan: ${model.remainderM3} m³',
                            en: 'Total: ${model.totalM3} m³  |  Remaining: ${model.remainderM3} m³'),
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      if (model.electricQuantity >= 0)
                        Text(
                          _t(context,
                              tr: 'Pil: ${model.electricQuantity}%',
                              en: 'Battery: ${model.electricQuantity}%'),
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11),
                        ),
                    ] else
                      Text(
                        _t(context,
                            tr: 'Başlatılmamış', en: 'Not initialized'),
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (!model.isInited && onInit != null)
                TextButton(
                  onPressed: onInit,
                  child: Text(
                    _t(context, tr: 'Başlat', en: 'Init'),
                    style: const TextStyle(color: Colors.blue),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Electric Meter Detail Bottom Sheet ---
class _ElectricMeterDetailSheet extends StatelessWidget {
  final TTElectricMeterScanModel model;
  final void Function(bool isOn) onPowerToggle;
  final void Function(String amount, String kwh) onRecharge;
  final VoidCallback onDisconnect;

  const _ElectricMeterDetailSheet({
    required this.model,
    required this.onPowerToggle,
    required this.onRecharge,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(model.name.isEmpty ? model.mac : model.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(model.mac,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(color: Colors.white12, height: 24),
          _row(Icons.bolt, _t(context, tr: 'Toplam Tüketim', en: 'Total Usage'),
              '${model.totalKwh} kWh'),
          const SizedBox(height: 8),
          _row(Icons.battery_charging_full,
              _t(context, tr: 'Kalan Kredi', en: 'Remaining Credit'),
              '${model.remainderKwh} kWh'),
          const SizedBox(height: 8),
          _row(Icons.electrical_services,
              _t(context, tr: 'Voltaj / Akım', en: 'Voltage / Current'),
              '${model.voltage}V / ${model.electricCurrent}A'),
          const SizedBox(height: 8),
          _row(Icons.payment,
              _t(context, tr: 'Ödeme Modu', en: 'Pay Mode'),
              model.payMode == TTMeterPayMode.prepaid
                  ? _t(context, tr: 'Ön Ödemeli', en: 'Prepaid')
                  : _t(context, tr: 'Sonra Öde', en: 'Postpaid')),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onPowerToggle(!model.onOff),
                  icon: Icon(model.onOff ? Icons.power_off : Icons.power,
                      size: 18),
                  label: Text(model.onOff
                      ? _t(context, tr: 'Gücü Kes', en: 'Power Off')
                      : _t(context, tr: 'Gücü Aç', en: 'Power On')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: model.onOff ? Colors.red : Colors.green,
                    side: BorderSide(
                        color: model.onOff ? Colors.red : Colors.green),
                  ),
                ),
              ),
              if (model.payMode == TTMeterPayMode.prepaid) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRechargeDialog(context),
                    icon: const Icon(Icons.add_card, size: 18),
                    label: Text(_t(context, tr: 'Yükle', en: 'Recharge')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onDisconnect,
            icon: const Icon(Icons.bluetooth_disabled,
                color: Colors.grey, size: 18),
            label: Text(_t(context, tr: 'Bağlantıyı Kes', en: 'Disconnect'),
                style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final kwhCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_t(ctx, tr: 'Elektrik Yükle', en: 'Recharge Electric'),
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _t(ctx, tr: 'Tutar (₺)', en: 'Amount'),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: kwhCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _t(ctx, tr: 'kWh Miktarı', en: 'kWh Amount'),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // close bottom sheet
                onRecharge(amountCtrl.text.trim(), kwhCtrl.text.trim());
              },
              child: Text(_t(ctx, tr: 'Yükle', en: 'Recharge'),
                  style: const TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// --- Water Meter Detail Bottom Sheet ---
class _WaterMeterDetailSheet extends StatelessWidget {
  final TTWaterMeterScanModel model;
  final void Function(bool isOn) onPowerToggle;
  final void Function(String amount, String m3) onRecharge;
  final VoidCallback onDisconnect;

  const _WaterMeterDetailSheet({
    required this.model,
    required this.onPowerToggle,
    required this.onRecharge,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(model.name.isEmpty ? model.mac : model.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(model.mac,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(color: Colors.white12, height: 24),
          _row(Icons.water,
              _t(context, tr: 'Toplam Kullanım', en: 'Total Usage'),
              '${model.totalM3} m³'),
          const SizedBox(height: 8),
          _row(Icons.water_drop,
              _t(context, tr: 'Kalan Kredi', en: 'Remaining Credit'),
              '${model.remainderM3} m³'),
          if (model.electricQuantity >= 0) ...[
            const SizedBox(height: 8),
            _row(Icons.battery_std,
                _t(context, tr: 'Pil', en: 'Battery'),
                '${model.electricQuantity}%'),
          ],
          const SizedBox(height: 8),
          _row(Icons.payment,
              _t(context, tr: 'Ödeme Modu', en: 'Pay Mode'),
              model.payMode == TTMeterPayMode.prepaid
                  ? _t(context, tr: 'Ön Ödemeli', en: 'Prepaid')
                  : _t(context, tr: 'Sonra Öde', en: 'Postpaid')),
          if (model.waterValveFailure != 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text(
                  _t(context, tr: 'Vana arızası algılandı', en: 'Valve failure detected'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onPowerToggle(!model.onOff),
                  icon: Icon(
                      model.onOff ? Icons.water_drop : Icons.water_drop_outlined,
                      size: 18),
                  label: Text(model.onOff
                      ? _t(context, tr: 'Vanayı Kapat', en: 'Close Valve')
                      : _t(context, tr: 'Vanayı Aç', en: 'Open Valve')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: model.onOff ? Colors.red : Colors.blue,
                    side: BorderSide(
                        color: model.onOff ? Colors.red : Colors.blue),
                  ),
                ),
              ),
              if (model.payMode == TTMeterPayMode.prepaid) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRechargeDialog(context),
                    icon: const Icon(Icons.add_card, size: 18),
                    label: Text(_t(context, tr: 'Yükle', en: 'Recharge')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onDisconnect,
            icon: const Icon(Icons.bluetooth_disabled,
                color: Colors.grey, size: 18),
            label: Text(_t(context, tr: 'Bağlantıyı Kes', en: 'Disconnect'),
                style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final m3Ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_t(ctx, tr: 'Su Yükle', en: 'Recharge Water'),
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _t(ctx, tr: 'Tutar (₺)', en: 'Amount'),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: m3Ctrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _t(ctx, tr: 'm³ Miktarı', en: 'm³ Amount'),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                onRecharge(amountCtrl.text.trim(), m3Ctrl.text.trim());
              },
              child: Text(_t(ctx, tr: 'Yükle', en: 'Recharge'),
                  style: const TextStyle(color: Colors.blue))),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
