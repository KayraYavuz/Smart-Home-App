import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class AuthorizedAdminPage extends StatefulWidget {
  final String lockId;
  final String lockName;

  const AuthorizedAdminPage({
    super.key,
    required this.lockId,
    required this.lockName,
  });

  @override
  State<AuthorizedAdminPage> createState() => _AuthorizedAdminPageState();
}

class _AuthorizedAdminPageState extends State<AuthorizedAdminPage> {
  late ApiService _apiService;
  String? _accessToken;
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthRepository>());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _apiService.getAccessToken();
      if (mounted) {
        setState(() => _accessToken = _apiService.accessToken);
        _loadAdmins();
      }
    });
  }

  Future<void> _loadAdmins() async {
    if (_accessToken == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await _apiService.getLockEKeys(
        accessToken: _accessToken!,
        lockId: widget.lockId,
        keyRight: 1,
      );
      if (!mounted) return;
      setState(() {
        _admins = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _addAdmin() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final username = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.grantAdminAccess, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.enterUsername,
            labelStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => navigator.pop(controller.text.trim()),
            child: Text(l10n.save, style: const TextStyle(color: Color(0xFF1E90FF))),
          ),
        ],
      ),
    );
    controller.dispose();

    if (username == null || username.isEmpty || !mounted) return;

    try {
      await _apiService.grantAdmin(lockId: widget.lockId, receiverUsername: username);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminGranted)));
      _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _revokeAdmin(Map<String, dynamic> admin) async {
    if (_accessToken == null) return;
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${admin['username'] ?? admin['keyName'] ?? ''}',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => navigator.pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.deleteEKey(
        accessToken: _accessToken!,
        keyId: admin['keyId'].toString(),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminRevoked)));
      _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  String _formatDate(dynamic ms) {
    if (ms == null) return '—';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ms.toString()));
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.authorizedAdminMenu,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF1E90FF)),
            tooltip: l10n.grantAdminAccess,
            onPressed: _addAdmin,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E90FF)))
          : _admins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noAdminsYet,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addAdmin,
                        icon: const Icon(Icons.person_add),
                        label: Text(l10n.grantAdminAccess),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E90FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAdmins,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _admins.length,
                    itemBuilder: (context, index) {
                      final admin = _admins[index];
                      final name = admin['keyName'] ?? admin['username'] ?? l10n.authorizedAdminMenu;
                      final username = admin['username'] ?? '';
                      final start = _formatDate(admin['startDate']);
                      final end = _formatDate(admin['endDate']);
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1E90FF),
                            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            username.isNotEmpty ? '$username\n$start → $end' : '$start → $end',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          isThreeLine: username.isNotEmpty,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _revokeAdmin(admin),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
