import 'package:flutter/material.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';

class GatewayManagementDialog extends StatefulWidget {
  const GatewayManagementDialog({Key? key}) : super(key: key);

  @override
  _GatewayManagementDialogState createState() => _GatewayManagementDialogState();
}

class _GatewayManagementDialogState extends State<GatewayManagementDialog> {
  List<Map<String, dynamic>> _gateways = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  Future<void> _loadGateways() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiService = ApiService(AuthRepository());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      final gateways = await apiService.getGatewayList(accessToken: accessToken);

      setState(() {
        _gateways = gateways;
        _isLoading = false;
      });

      print('📡 ${gateways.length} gateway bulundu');

    } catch (e) {
      print('❌ Gateway listesi yükleme hatası: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _connectGateway(String gatewayId) async {
    try {
      final apiService = ApiService(AuthRepository());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      await apiService.connectGateway(
        accessToken: accessToken,
        gatewayId: gatewayId,
      );

      // Listeyi yenile
      await _loadGateways();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gateway\'e başarıyla bağlanıldı'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gateway bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectGateway(String gatewayId) async {
    try {
      final apiService = ApiService(AuthRepository());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      await apiService.disconnectGateway(
        accessToken: accessToken,
        gatewayId: gatewayId,
      );

      // Listeyi yenile
      await _loadGateways();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gateway bağlantısı kesildi'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gateway bağlantı kesme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showGatewayDetail(String gatewayId) async {
    try {
      final apiService = ApiService(AuthRepository());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      final detail = await apiService.getGatewayDetail(
        accessToken: accessToken,
        gatewayId: gatewayId,
      );

      final locks = await apiService.getGatewayLocks(
        accessToken: accessToken,
        gatewayId: gatewayId,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Gateway Detayları', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gateway ID: $gatewayId', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('İsim: ${detail['gatewayName'] ?? 'Bilinmiyor'}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('MAC: ${detail['gatewayMac'] ?? 'Bilinmiyor'}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Ağ: ${detail['networkName'] ?? 'Bilinmiyor'}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Durum: ${detail['isOnline'] == true ? 'Çevrimiçi' : 'Çevrimdışı'}',
                      style: TextStyle(
                        color: detail['isOnline'] == true ? Colors.green : Colors.red,
                      )),
                  const SizedBox(height: 16),
                  Text('Bağlı Kilitler (${locks.length}):', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...locks.map((lock) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${lock['lockAlias'] ?? lock['lockName'] ?? 'İsimsiz Kilit'}',
                        style: const TextStyle(color: Colors.grey)),
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gateway detay hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.router, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gateway Yönetimi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadGateways,
                  tooltip: 'Yenile',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'TTLock Gateway\'lerinizi yönetin ve uzaktan kontrol için bağlanın.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Hata: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadGateways,
                                child: const Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        )
                      : _gateways.isEmpty
                          ? const Center(
                              child: Text(
                                'Hiç Gateway bulunamadı.\nTTLock uygulamanızdan Gateway ekleyin.',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _gateways.length,
                              itemBuilder: (context, index) {
                                final gateway = _gateways[index];
                                final isOnline = gateway['isOnline'] == true;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: const Color(0xFF2A2A2A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isOnline ? Icons.wifi : Icons.wifi_off,
                                              color: isOnline ? Colors.green : Colors.red,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    gateway['gatewayName'] ?? 'İsimsiz Gateway',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'ID: ${gateway['gatewayId']}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                                                style: TextStyle(
                                                  color: isOnline ? Colors.green : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'MAC: ${gateway['gatewayMac'] ?? 'Bilinmiyor'}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showGatewayDetail(gateway['gatewayId'].toString()),
                                                icon: const Icon(Icons.info_outline, size: 16),
                                                label: const Text('Detaylar'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                                  foregroundColor: Colors.blue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: isOnline
                                                    ? () => _disconnectGateway(gateway['gatewayId'].toString())
                                                    : () => _connectGateway(gateway['gatewayId'].toString()),
                                                icon: Icon(isOnline ? Icons.link_off : Icons.link, size: 16),
                                                label: Text(isOnline ? 'Bağlantıyı Kes' : 'Bağlan'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isOnline ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                                                  foregroundColor: isOnline ? Colors.red : Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),

            const SizedBox(height: 24),

            // Footer
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
