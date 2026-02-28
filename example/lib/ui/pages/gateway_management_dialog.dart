import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class GatewayManagementDialog extends StatefulWidget {
  const GatewayManagementDialog({super.key});

  @override
  State<GatewayManagementDialog> createState() => _GatewayManagementDialogState();
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

      final apiService = context.read<ApiService>();
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      final gateways = await apiService.getGatewayList();

      if (!mounted) return;
      setState(() {
        _gateways = gateways;
        _isLoading = false;
      });

      debugPrint('📡 ${gateways.length} gateway bulundu');

    } catch (e) {
      debugPrint('❌ Gateway listesi yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _connectGateway(String gatewayId) async {
    try {
      final apiService = context.read<ApiService>();
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

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gatewayConnectedSuccess),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gatewayConnectError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectGateway(String gatewayId) async {
    try {
      final apiService = context.read<ApiService>();
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

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gatewayDisconnectedSuccess),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gatewayDisconnectError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showGatewayDetail(String gatewayId) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      final detail = await apiService.getGatewayDetail(
        gatewayId: gatewayId,
      );

      final locks = await apiService.getGatewayLocks(
        gatewayId: gatewayId,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(l10n.gatewayDetails, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gateway ID: $gatewayId', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('${l10n.nameLabel}: ${detail['gatewayName'] ?? l10n.unknown}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('MAC: ${detail['gatewayMac'] ?? l10n.unknown}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('${l10n.networkLabel}: ${detail['networkName'] ?? l10n.unknown}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('${l10n.statusLabel}: ${detail['isOnline'] == true ? l10n.online : l10n.offline}',
                      style: TextStyle(
                        color: detail['isOnline'] == true ? Colors.green : Colors.red,
                      )),
                  const SizedBox(height: 16),
                  Text('${l10n.connectedLocks} (${locks.length}):', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...locks.map((lock) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${lock['lockAlias'] ?? lock['lockName'] ?? l10n.unnamedLock}',
                        style: const TextStyle(color: Colors.grey)),
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.closeButton, style: const TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gatewayDetailError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                const Icon(Icons.router, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.gatewayManagement,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadGateways,
                  tooltip: l10n.refresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gatewayManagementDesc,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                '${l10n.errorLabel}: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadGateways,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        )
                      : _gateways.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noConnectedGatewaysDesc,
                                style: const TextStyle(color: Colors.grey),
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
                                                    gateway['gatewayName'] ?? l10n.unnamedGateway,
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
                                                isOnline ? l10n.online : l10n.offline,
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
                                          'MAC: ${gateway['gatewayMac'] ?? l10n.unknown}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showGatewayDetail(gateway['gatewayId'].toString()),
                                                icon: const Icon(Icons.info_outline, size: 16),
                                                label: Text(l10n.detailsButton),
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
                                                label: Text(isOnline ? l10n.disconnect : l10n.connectButton),
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
                    child: Text(
                      l10n.closeButton,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
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
