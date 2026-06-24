import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class ImportFromLockPage extends StatefulWidget {
  final String targetLockData;
  final String targetLockId;

  const ImportFromLockPage({
    super.key,
    required this.targetLockData,
    required this.targetLockId,
  });

  @override
  State<ImportFromLockPage> createState() => _ImportFromLockPageState();
}

class _ImportFromLockPageState extends State<ImportFromLockPage> {
  List<Map<String, dynamic>> _otherLocks = [];
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadOtherLocks();
  }

  Future<void> _loadOtherLocks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_locks');
      if (cached != null) {
        final List<dynamic> all = json.decode(cached);
        final others = all
            .cast<Map<String, dynamic>>()
            .where((l) => l['lockId']?.toString() != widget.targetLockId)
            .toList();
        if (!mounted) return;
        setState(() {
          _otherLocks = others;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startImport(Map<String, dynamic> sourceLock) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.importFromLock, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${sourceLock['name'] ?? l10n.selectSourceLock} → ${l10n.importFromLockSubtitle}',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.proceed, style: const TextStyle(color: Color(0xFF1E90FF))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);

    try {
      final api = ApiService(context.read<AuthRepository>());
      await api.getAccessToken();
      final token = api.accessToken;
      if (token == null) throw Exception('No access token');

      final sourceLockId = sourceLock['lockId']?.toString() ?? '';

      // Get passcodes from source lock
      final passcodes = await api.getPasscodeList(lockId: sourceLockId);

      // Get cards from source lock
      final cards = await api.getLockCards(accessToken: token, lockId: sourceLockId);

      if (!mounted) return;
      setState(() => _isImporting = false);

      messenger.showSnackBar(SnackBar(
        content: Text('${l10n.importStarted} (${passcodes.length} passcodes, ${cards.length} cards)'),
        backgroundColor: Colors.green,
      ));
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
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
          l10n.selectSourceLock,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isImporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1E90FF)),
                  const SizedBox(height: 16),
                  Text(l10n.importStarted, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E90FF)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.importFromLockDesc,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: _otherLocks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noOtherLocks,
                                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _otherLocks.length,
                              itemBuilder: (context, index) {
                                final lock = _otherLocks[index];
                                return Card(
                                  color: const Color(0xFF1E1E1E),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFF1E90FF),
                                      child: Icon(Icons.lock, color: Colors.white, size: 20),
                                    ),
                                    title: Text(
                                      lock['name'] ?? 'Lock ${lock['lockId']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      'ID: ${lock['lockId']}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                    onTap: () => _startImport(lock),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
