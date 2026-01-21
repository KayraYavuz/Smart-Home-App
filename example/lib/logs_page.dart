import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';

class LogsPage extends StatefulWidget {
  final String? lockId;
  final String? lockName;

  const LogsPage({super.key, this.lockId, this.lockName});

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(AuthRepository());
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 LogsPage: Fetching records for lockId=${widget.lockId}');
      await _apiService.getAccessToken();
      final accessToken = _apiService.accessToken;
      print('🔍 LogsPage: AccessToken is ${accessToken != null ? 'Present' : 'NULL'}');
      
      if (accessToken == null) throw Exception('Erişim anahtarı alınamadı');

      if (widget.lockId != null) {
        print('📋 LogsPage: Calling getLockRecords for ${widget.lockId}');
        final data = await _apiService.getLockRecords(
          accessToken: accessToken,
          lockId: widget.lockId!,
          pageSize: 100, // Increased page size
        );
        print('✅ LogsPage: Received ${data.length} records');
        setState(() {
          _records = data;
          _isLoading = false;
        });
      } else {
        print('📋 LogsPage: No lockId, fetching all keys first...');
        final allKeys = await _apiService.getKeyList();
        print('🔍 LogsPage: Found ${allKeys.length} locks');
        List<Map<String, dynamic>> allRecords = [];
        
        // Paralel olarak ilk 5 kilidin kayıtlarını çekelim (performans için sınırlı)
        final limitedKeys = allKeys.take(5).toList();
        for (var key in limitedKeys) {
          try {
            final recs = await _apiService.getLockRecords(
              accessToken: accessToken,
              lockId: key['lockId'].toString(),
              pageSize: 20,
            );
            allRecords.addAll(recs);
          } catch (e) {
            print('Error fetching records for ${key['lockId']}: $e');
          }
        }
        
        // Tarihe göre sırala
        allRecords.sort((a, b) => (b['lockDate'] ?? 0).compareTo(a['lockDate'] ?? 0));
        
        setState(() {
          _records = allRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showClearConfirmation() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Kayıtları Temizle', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm kilit kayıtlarını bulut sunucusundan silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Temizle', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _clearRecords();
    }
  }

  Future<void> _clearRecords() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.getAccessToken();
      final accessToken = _apiService.accessToken;
      if (accessToken == null) throw Exception('Erişim anahtarı alınamadı');

      await _apiService.clearLockRecords(
        accessToken: accessToken,
        lockId: widget.lockId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm kayıtlar başarıyla temizlendi'), backgroundColor: Colors.green),
      );
      
      _fetchRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Temizleme hatası: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getRecordInfo(Map<String, dynamic> record) {
    final int typeFromLock = record['recordTypeFromLock'] ?? 0;
    final int recordType = record['recordType'] ?? 0;
    
    switch (typeFromLock) {
      case 1:
        return {'label': 'Şifre', 'icon': Icons.keyboard, 'color': AppColors.primary};
      case 2:
        return {'label': 'Kart', 'icon': Icons.credit_card, 'color': Colors.green};
      case 3:
        return {'label': 'Parmak İzi', 'icon': Icons.fingerprint, 'color': Colors.purple};
      case 4:
        return {'label': 'Uygulama (BT)', 'icon': Icons.phone_android, 'color': Colors.orange};
      case 5:
        return {'label': 'Uzaktan Açma', 'icon': Icons.wifi, 'color': Colors.teal};
      case 6:
        return {'label': 'Kilitlendi', 'icon': Icons.lock, 'color': AppColors.error};
      case 7:
        return {'label': 'Mekanik Anahtar', 'icon': Icons.vpn_key, 'color': Colors.grey};
      case 8:
        return {'label': 'Bileklik', 'icon': Icons.watch, 'color': Colors.indigo};
      case 10:
        return {'label': 'Uzaktan Kumanda', 'icon': Icons.settings_remote, 'color': Colors.blueGrey};
      case 11:
      case 28:
        return {'label': 'Uygulama (Uzaktan)', 'icon': Icons.cloud_done, 'color': Colors.blue};
      case 12:
        return {'label': 'Gateway ile açıldı', 'icon': Icons.router, 'color': Colors.cyan};
      case 17:
      case 26:
        return {'label': 'Otomatik Kilitleme', 'icon': Icons.lock_clock, 'color': Colors.redAccent};
      default:
        // recordType'a göre fallback
        if (recordType == 11) return {'label': 'Kilitlendi', 'icon': Icons.lock, 'color': Colors.redAccent};
        if (recordType == 12) return {'label': 'Açıldı', 'icon': Icons.lock_open, 'color': Colors.greenAccent};
        return {'label': 'Diğer İşlem ($typeFromLock)', 'icon': Icons.history, 'color': Colors.white54};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.lockName != null ? '${widget.lockName} Kayıtları' : 'Kilit Kayıtları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.lockId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: _showClearConfirmation,
              tooltip: 'Tüm Kayıtları Temizle',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecords,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecords,
        color: AppColors.primary,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Hata: $_error', style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: _fetchRecords, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return const Center(
        child: Text('Henüz kayıt bulunamadı', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
      itemBuilder: (context, index) {
        final record = _records[index];
        final typeInfo = _getRecordInfo(record);
        
        final timestamp = record['lockDate'] ?? DateTime.now().millisecondsSinceEpoch;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final formattedDate = '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        final userName = record['keyName'] ?? record['username'] ?? '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (typeInfo['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeInfo['icon'] as IconData, color: typeInfo['color'] as Color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  typeInfo['label'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (userName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    userName,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            formattedDate,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: record['success'] == 0 
            ? const Icon(Icons.error, color: AppColors.error, size: 16)
            : const Icon(Icons.check_circle, color: Colors.green, size: 16),
        );
      },
    );
  }
}
