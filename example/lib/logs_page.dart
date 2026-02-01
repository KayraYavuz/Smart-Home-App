import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class LogsPage extends StatefulWidget {
  final String? lockId;
  final String? lockName;
  final String? lockData; // JSON string for TTLock init

  const LogsPage({super.key, this.lockId, this.lockName, this.lockData});

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
      await _apiService.getAccessToken();
      final accessToken = _apiService.accessToken;
      
      if (accessToken == null) throw Exception('No access token');

      if (widget.lockId != null) {
        final data = await _apiService.getLockRecords(
          accessToken: accessToken,
          lockId: widget.lockId!,
          pageSize: 100,
        );
        setState(() {
          _records = data;
          _isLoading = false;
        });
      } else {
        final allKeys = await _apiService.getKeyList();
        List<Map<String, dynamic>> allRecords = [];
        
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
        
        allRecords.sort((a, b) => (b['lockDate'] ?? 0).compareTo(a['lockDate'] ?? 0));
        
        if (!mounted) return;
        setState(() {
          _records = allRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showClearConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.clearAllRecords, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${l10n.clearAllRecords}?\n\n(This action cannot be undone/Geri alınamaz)', // Fallback mixed or reuse
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)), // reusing delete or clear
          ),
        ],
      ),
    );

    if (confirm == true) {
      _clearRecords();
    }
  }

  Future<void> _clearRecords() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await _apiService.getAccessToken();
      final accessToken = _apiService.accessToken;
      if (accessToken == null) throw Exception('No access token');

      await _apiService.clearLockRecords(
        accessToken: accessToken,
        lockId: widget.lockId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveSuccess), backgroundColor: Colors.green), // reusing success
      );
      
      _fetchRecords();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMsg(e.toString())), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getRecordInfo(Map<String, dynamic> record) {
    // Localization for record types would require more keys.
    // Keeping existing Turkish labels for now or could switch to simple icons only if requested.
    // User requested Multi-language support. Ideally these should be localized.
    // Ill use hardcoded Turkish as fallback/current state since keys weren't prepared for all methods.
    
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
        if (recordType == 11) return {'label': 'Kilitlendi', 'icon': Icons.lock, 'color': Colors.redAccent};
        if (recordType == 12) return {'label': 'Açıldı', 'icon': Icons.lock_open, 'color': Colors.greenAccent};
        return {'label': 'Diğer İşlem ($typeFromLock)', 'icon': Icons.history, 'color': Colors.white54};
    }
  }

  Future<void> _readLogsFromLock() async {
    // Deprecated or alternative method stub
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Helper for title
    String title = l10n.lockRecords;
    if (widget.lockName != null) {
      title = l10n.lockRecordsWithName(widget.lockName!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(Icons.bluetooth_searching, color: Colors.blue),
             onPressed: _syncLogsWithBluetooth,
             tooltip: l10n.readFromLock,
          ),
          if (widget.lockId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: _showClearConfirmation,
              tooltip: l10n.clearAllRecords,
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
        child: _buildContent(l10n),
      ),
    );
  }

  Future<void> _syncLogsWithBluetooth() async {
     final l10n = AppLocalizations.of(context)!;
     if (widget.lockData == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.missingLockData)));
       return;
     }

     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) {
         return AlertDialog(
           backgroundColor: const Color(0xFF1E1E1E),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const CircularProgressIndicator(color: Colors.blue),
               const SizedBox(height: 16),
               Text(l10n.connectingReadingLogs, style: const TextStyle(color: Colors.white)),
             ],
           ),
         );
       }
     );

     try {
       print('🔵 Bluetooth logs reading...');
       
       TTLock.getLog(widget.lockData!, (String log) async {
         try {
           await _apiService.uploadOperationLog(
             lockId: widget.lockId!, 
             records: log
           );
           
           if (!mounted) return;
           Navigator.pop(context); // Dialog close
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.recordsSynced), backgroundColor: Colors.green));
           
           _fetchRecords();
           
         } catch (e) {
           print('❌ Upload hatası: $e');
           if (!mounted) return;
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.uploadError(e.toString())), backgroundColor: Colors.orange));
         }
       }, (errorCode, errorMsg) {
         print('❌ Bluetooth error: $errorCode - $errorMsg');
         if (!mounted) return;
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.readError(errorMsg)), backgroundColor: Colors.red));
       });
       
     } catch (e) {
       if (!mounted) return;
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unexpectedError(e.toString()))));
     }
  }

  Widget _buildContent(AppLocalizations l10n) {
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
            Text('${l10n.errorLabel}: $_error', style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: _fetchRecords, child: Text(l10n.refresh)),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Text(l10n.noData, style: const TextStyle(color: Colors.grey)),
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
