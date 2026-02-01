import 'package:yavuz_lock/ui/pages/user_management_page.dart';
import 'package:yavuz_lock/ui/pages/gateway_management_page.dart';
import 'package:yavuz_lock/ui/pages/group_management_page.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class SystemManagementPage extends StatefulWidget {
  const SystemManagementPage({super.key});

  @override
  _SystemManagementPageState createState() => _SystemManagementPageState();
}

class _SystemManagementPageState extends State<SystemManagementPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthRepository>());
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getGroupList();
      if (!mounted) return;
      
      setState(() {
        _groups = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Group load error: $e');
    }
  }

  // --- Export Logic ---
  Future<void> _exportRecords() async {
    final l10n = AppLocalizations.of(context)!;
    // 1. Pick Date Range
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
      saveText: l10n.save,
      cancelText: l10n.cancel,
    );

    if (picked == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.preparingRecords)),
    );

    try {
      // 2. Fetch All Locks
      final locks = await _apiService.getKeyList();
      List<Map<String, dynamic>> allRecords = [];

      // 3. Fetch Records for each lock
      await Future.wait(locks.map((lock) async {
        try {
          final records = await _apiService.getLockRecords(
            accessToken: _apiService.accessToken!,
            lockId: lock['lockId'].toString(),
            startDate: picked.start.millisecondsSinceEpoch,
            endDate: picked.end.millisecondsSinceEpoch,
            pageSize: 100,
          );
          
          for (var r in records) {
             r['lockName'] = lock['lockAlias'] ?? lock['lockName'] ?? 'Unknown';
          }
          allRecords.addAll(records);
        } catch (e) {
          print('Error fetching records for ${lock['lockId']}: $e');
        }
      }));

      // 4. Generate CSV
      final buffer = StringBuffer();
      // Headers (Keep EN/TR neutral or specific? Using TR as current default)
      buffer.writeln('Kilit,Kullanici,Islem,Tarih,Basari');

      for (var r in allRecords) {
        final lockName = r['lockName'] ?? '-';
        final user = r['username'] ?? r['sender'] ?? '-';
        final type = r['recordType'] ?? '-'; 
        final dateMs = r['lockDate'] ?? 0;
        final dateStr = DateTime.fromMillisecondsSinceEpoch(dateMs).toString();
        final success = r['success'] == 1 ? 'Evet' : 'Hayir';

        buffer.writeln('$lockName,$user,$type,$dateStr,$success');
      }

      final csvData = buffer.toString();

      // 5. Save & Share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kilit_kayitlari_${DateTime.now().millisecond}.csv');
      await file.writeAsString(csvData);

      final dateRangeStr = l10n.lockRecordsTitle(
          picked.start.toString().split(" ")[0], 
          picked.end.toString().split(" ")[0]
      );
      
      await Share.shareXFiles([XFile(file.path)], text: dateRangeStr);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportError(e.toString())), backgroundColor: Colors.red),
      );
    }
  }

  // --- Admin Creation Logic ---
  Future<void> _showCreateAdminDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final locks = await _apiService.getKeyList();
    
    if (!mounted) return;
    
    final usernameController = TextEditingController();
    Map<String, dynamic>? selectedLock = locks.isNotEmpty ? locks.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(l10n.createAdmin, style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.grantAdminDesc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  // Lock Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedLock,
                        dropdownColor: const Color(0xFF2C2C2C),
                        isExpanded: true,
                        hint: Text(l10n.selectLock, style: const TextStyle(color: Colors.grey)),
                        items: locks.map((l) {
                          return DropdownMenuItem(
                            value: l,
                            child: Text(l['lockAlias'] ?? l['lockName'] ?? l10n.unknownLock, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedLock = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username Input
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.userEmailOrPhone,
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () async {
                    if (selectedLock != null && usernameController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _processGrantAdmin(selectedLock!['lockId'].toString(), usernameController.text);
                    }
                  },
                  child: Text(l10n.grantAccess, style: const TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _processGrantAdmin(String lockId, String username) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.processing)));
    try {
      await _apiService.grantAdmin(lockId: lockId, receiverUsername: username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminGranted), backgroundColor: Colors.green));
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString())), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.systemManagement,
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Grup Yönetimi Bölümü
            _buildSectionHeader(l10n.groupManagement),
            if (_isLoading) 
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
            if (!_isLoading && _groups.isEmpty)
              Padding(padding: const EdgeInsets.all(8.0), child: Text(l10n.noData, style: const TextStyle(color: Colors.grey))),
            ..._groups.map((group) => _buildGroupTile(group, l10n)),

            // Yetkili Yönetici Bölümü
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.adminManagement),
            _buildAdminManagementSection(l10n),

            // Diğer Sistem Yönetimi Öğeleri
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.userManagement),
            _buildManagementTile(
              icon: Icons.lock_person,
              title: l10n.lockUsers,
              subtitle: l10n.lockUsersSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserManagementPage()),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(l10n.gatewayManagement),
            _buildManagementTile(
              icon: Icons.swap_horiz,
              title: l10n.transferLock,
              subtitle: l10n.transferLockSubtitle,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.transferLockComingSoon)),
                );
              },
            ),
            _buildManagementTile(
              icon: Icons.wifi_tethering,
              title: l10n.transferGateway,
              subtitle: l10n.transferGatewaySubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GatewayManagementPage()),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(l10n.dataManagement),
            _buildManagementTile(
              icon: Icons.file_download,
              title: l10n.exportData,
              subtitle: l10n.exportDataSubtitle,
              onTap: _exportRecords,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const GroupManagementPage()),
           ).then((_) => _loadGroups());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group, AppLocalizations l10n) {
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.group,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          group['name'] ?? l10n.unnamedGroup,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.lockCount(group['lockCount'] ?? 0),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        ),
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupManagementPage()),
          ).then((_) => _loadGroups());
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAdminManagementSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.admin_panel_settings,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.adminRights,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _showCreateAdminDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.createAdmin,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
