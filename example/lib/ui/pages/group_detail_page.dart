import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class GroupDetailPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final Function() onGroupUpdated;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.onGroupUpdated,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _groupLocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthRepository>());
    _fetchGroupLocks();
  }

  Future<void> _fetchGroupLocks() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final locks = await _apiService.getGroupLockList(widget.group['groupId'].toString());
      if (!mounted) return;
      setState(() {
        _groupLocks = locks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.groupLocksLoadError(e.toString()))),
      );
    }
  }

  Future<void> _manageGroupLocks() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      // 1. Get ALL locks
      final allLocks = await _apiService.getKeyList();
      
      // 2. Get locks ALREADY in this group
      final currentGroupLocks = await _apiService.getGroupLockList(widget.group['groupId'].toString());
      final Set<String> groupLockIds = currentGroupLocks.map((l) => l['lockId'].toString()).toSet();

      if (!mounted) return;
      navigator.pop(); // Close loading

      // Selected locks state
      final Set<String> selectedLockIds = Set.from(groupLockIds);

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: Text(l10n.groupLocksTitle(widget.group['name'] ?? ''), style: const TextStyle(color: Colors.white)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: allLocks.isEmpty 
                    ? Center(child: Text(l10n.noLocksFound, style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: allLocks.length,
                        itemBuilder: (context, index) {
                          final lock = allLocks[index];
                          final lockId = lock['lockId'].toString();
                          final isSelected = selectedLockIds.contains(lockId);
                          
                          return CheckboxListTile(
                            title: Text(lock['name'] ?? l10n.lock, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(lockId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            value: isSelected,
                            activeColor: AppColors.primary,
                            checkColor: Colors.black,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedLockIds.add(lockId);
                                } else {
                                  selectedLockIds.remove(lockId);
                                }
                              });
                            },
                          );
                        },
                      ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => navigator.pop(),
                    child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      navigator.pop();
                      await _saveGroupLocks(widget.group['groupId'].toString(), groupLockIds, selectedLockIds);
                      _fetchGroupLocks(); // Refresh list
                    },
                    child: Text(l10n.save, style: const TextStyle(color: AppColors.primary)),
                  ),
                ],
              );
            }
          );
        },
      );

    } catch (e) {
      navigator.pop(); // Close loading
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.lockListRetrievalError(e.toString())), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveGroupLocks(String groupId, Set<String> oldLockIds, Set<String> newLockIds) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    int successCount = 0;
    int failCount = 0;

    // 1. Add new locks (in new but not in old)
    final toAdd = newLockIds.difference(oldLockIds);
    for (var lockId in toAdd) {
      try {
        await _apiService.setLockGroup(lockId: lockId, groupId: groupId);
        successCount++;
      } catch (e) {
        debugPrint("Add lock $lockId failed: $e");
        failCount++;
      }
    }

    // 2. Remove locks (in old but not in new)
    final toRemove = oldLockIds.difference(newLockIds);
    for (var lockId in toRemove) {
      try {
        await _apiService.setLockGroup(lockId: lockId, groupId: "0"); // 0 to ungroup
        successCount++;
      } catch (e) {
        debugPrint("Remove lock $lockId failed: $e");
        failCount++;
      }
    }

    if (!mounted) return;
    navigator.pop(); // Close loading

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(l10n.operationCompletedWithCounts(successCount.toString(), failCount.toString())),
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
      ),
    );
  }

  Future<void> _shareGroup() async {
    final TextEditingController usernameController = TextEditingController();
    // Default start now, end 1 year later
    int startDate = DateTime.now().millisecondsSinceEpoch;
    int endDate = DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch;
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.shareGroupTitle(widget.group['name'] ?? ''), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.receiverHintUserEmail,
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                prefixIcon: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.groupShareNote,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty) {
                navigator.pop();
                await _processGroupShare(
                  widget.group['groupId'].toString(),
                  usernameController.text,
                  startDate,
                  endDate,
                );
              }
            },
            child: Text(l10n.send, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _processGroupShare(String groupId, String receiverUsername, int startDateMs, int endDateMs) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      await _apiService.getAccessToken();
      final token = _apiService.accessToken;
      if (token == null) throw Exception(l10n.tokenNotFound);

      final locks = await _apiService.getGroupLockList(groupId);
      
      if (locks.isEmpty) {
        if (mounted) navigator.pop();
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.noLocksInGroup)));
        }
        return;
      }

      int successCount = 0;
      int failCount = 0;

      for (var lock in locks) {
        try {
          await _apiService.sendEKey(
            accessToken: token,
            lockId: lock['lockId'].toString(),
            receiverUsername: receiverUsername,
            keyName: "${lock['lockAlias'] ?? 'Lock'} (Group)",
            startDate: DateTime.fromMillisecondsSinceEpoch(startDateMs),
            endDate: DateTime.fromMillisecondsSinceEpoch(endDateMs),
            remoteEnable: 2,
          );
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) navigator.pop();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.locksSharedCounts(successCount.toString(), failCount.toString())),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) navigator.pop();
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.group['name'] ?? AppLocalizations.of(context)!.groupDetail),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.green),
            onPressed: _shareGroup,
            tooltip: AppLocalizations.of(context)!.shareGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header / Stats
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.folder_open, size: 32, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group['name'] ?? AppLocalizations.of(context)!.unnamed,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AppLocalizations.of(context)!.totalLocksCount(_groupLocks.length.toString()),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _manageGroupLocks,
                icon: const Icon(Icons.edit_note, color: Colors.black),
                label: Text(AppLocalizations.of(context)!.editGroupLocks, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          
          // Lock List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _groupLocks.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.noLocksInGroup, style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groupLocks.length,
                        itemBuilder: (context, index) {
                          final lock = _groupLocks[index];
                          return Card(
                            color: const Color(0xFF2C2C2C),
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: const Icon(Icons.lock, color: Colors.white70),
                              title: Text(
                                lock['lockAlias'] ?? lock['lockName'] ?? AppLocalizations.of(context)!.lock,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'ID: ${lock['lockId']}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
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
