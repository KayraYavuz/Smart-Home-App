import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class GatewayManagementPage extends StatefulWidget {
  const GatewayManagementPage({super.key});

  @override
  State<GatewayManagementPage> createState() => _GatewayManagementPageState();
}

class _GatewayManagementPageState extends State<GatewayManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _gateways = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGateways() async {
    setState(() {
      _isLoading = true;
    });

    // Mock API çağrısı - gerçek uygulamada API'den gelecek
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _gateways = []; // Veri yok durumu için boş liste
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.transferGateway,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.searchGateway,
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  // Arama filtresi uygulanabilir
                  setState(() {});
                },
              ),
            ),

            // Ana İçerik
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : _gateways.isEmpty
                      ? _buildEmptyState(l10n)
                      : _buildGatewayList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.router,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noData,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noGatewayFound,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayList(AppLocalizations l10n) {
    final filteredGateways = _gateways.where((gateway) {
      final searchTerm = _searchController.text.toLowerCase();
      final name = gateway['name'].toString().toLowerCase();
      final mac = gateway['mac'].toString().toLowerCase();
      return name.contains(searchTerm) || mac.contains(searchTerm);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredGateways.length,
      itemBuilder: (context, index) {
        final gateway = filteredGateways[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.router,
                color: Colors.green,
                size: 24,
              ),
            ),
            title: Text(
              gateway['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAC: ${gateway['mac']}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                Text(
                  gateway['status'] == 'online' ? l10n.online : l10n.offline,
                  style: TextStyle(
                    color: gateway['status'] == 'online' ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () {
                // Ağ geçidi menüsü
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.actionsFor(gateway['name']))),
                );
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }
}
