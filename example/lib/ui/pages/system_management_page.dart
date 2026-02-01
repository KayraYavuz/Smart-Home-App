import 'package:flutter/material.dart';
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
  State<SystemManagementPage> createState() => _SystemManagementPageState();
}

class _SystemManagementPageState extends State<SystemManagementPage> {
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthRepository>());
  }

  Future<void> _exportRecords() async {
    final l10n = AppLocalizations.of(context)!;
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
      final locks = await _apiService.getKeyList();
      List<Map<String, dynamic>> allRecords = [];

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
          print('Export error for lock ${lock['lockId']}: $e');
        }
      }));

      if (allRecords.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noData)),
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/yavuz_lock_records.json');
      await file.writeAsString(jsonEncode(allRecords));

      await Share.shareXFiles([XFile(file.path)], text: 'Yavuz Lock Records Export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportError(e.toString())), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.adminManagement),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildAdminMenuSection(l10n),
            const SizedBox(height: 24),
            _buildDataMenuSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            l10n.adminRights.toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        _buildMenuItem(
          icon: Icons.people_outline,
          title: l10n.userManagement,
          subtitle: l10n.lockUsersSubtitle,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementPage())),
        ),
        _buildMenuItem(
          icon: Icons.router_outlined,
          title: l10n.gatewayManagement,
          subtitle: l10n.transferGatewaySubtitle,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GatewayManagementPage())),
        ),
        _buildMenuItem(
          icon: Icons.folder_open_outlined,
          title: l10n.groupManagement,
          subtitle: l10n.newGroupComingSoon,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupManagementPage())),
        ),
      ],
    );
  }

  Widget _buildDataMenuSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            l10n.dataManagement.toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        _buildMenuItem(
          icon: Icons.file_download_outlined,
          title: l10n.exportData,
          subtitle: l10n.exportDataSubtitle,
          onTap: _exportRecords,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}