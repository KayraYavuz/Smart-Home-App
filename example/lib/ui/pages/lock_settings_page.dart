import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/ui/pages/feature_pages.dart';
import 'package:yavuz_lock/ui/pages/passage_mode/passage_mode_page.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';


class LockSettingsPage extends StatefulWidget {
  final Map<String, dynamic> lock;

  const LockSettingsPage({super.key, required this.lock});

  @override
  State<LockSettingsPage> createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  late ApiService _apiService;
  bool _isLoading = false;
  
  // Settings values
  bool _passageModeEnabled = false;
  String _lockName = '';
  String? _groupName;
  int _autoLockSeconds = 0;
  String _lockData = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(AuthRepository());
    _lockName = widget.lock['name'] ?? '';
    _lockData = widget.lock['lockData'] ?? '';
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final lockId = widget.lock['lockId'].toString();
      
      // Fetch Passage Mode
      final passageConfig = await _apiService.getPassageModeConfiguration(lockId: lockId);
      
      // Fetch Lock Detail for Auto Lock Time and fresh LockData
      final lockDetail = await _apiService.getLockDetail(lockId: lockId);
      final autoLockTime = lockDetail['autoLockTime'] ?? 0;
      final freshLockData = lockDetail['lockData'];

      // Fetch Group Info
      final groupList = await _apiService.getGroupList();
      final currentGroupId = widget.lock['groupId']?.toString();
      final currentGroup = groupList.firstWhere(
        (group) => group['groupId'].toString() == currentGroupId,
        orElse: () => <String, dynamic>{},
      );


      if (!mounted) return;
      setState(() {
        _passageModeEnabled = passageConfig['passageMode'] == 1;
        _autoLockSeconds = autoLockTime;
        _groupName = (currentGroup.isNotEmpty) ? currentGroup['name'] : null;
        if (freshLockData != null && freshLockData.isNotEmpty) {
          _lockData = freshLockData;
        }
      });
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lockSettings),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(l10n.general),
              _buildSettingTile(
                icon: Icons.edit,
                title: l10n.lockNameTitle,
                subtitle: _lockName,
                onTap: _renameLock,
              ),
              _buildSettingTile(
                icon: Icons.battery_charging_full,
                title: l10n.updateBatteryStatus,
                subtitle: l10n.syncWithServer,
                onTap: _updateBattery,
              ),
              _buildSettingTile(
                icon: Icons.wifi,
                title: l10n.wifiSettingsTitle,
                subtitle: l10n.manageWifiConnection,
                onTap: _showWifiSettings,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(l10n.lockingSettings),
              _buildSettingTile(
                icon: Icons.timer,
                title: l10n.autoLockTitle,
                subtitle: _autoLockSeconds > 0 ? '$_autoLockSeconds ${l10n.secondsShortcut}' : l10n.off,
                onTap: _showAutoLockDialog,
              ),
              _buildSettingTile(
                icon: Icons.door_front_door,
                title: l10n.passageModeTitle,
                subtitle: _passageModeEnabled ? l10n.activeLabel : l10n.passiveLabel,
                onTap: _openPassageModePage,
              ),
              // Working Hours removed as per request (not supported/redundant)

              const SizedBox(height: 24),
              _buildSectionHeader(l10n.dataManagement),
              _buildSettingTile(
                icon: Icons.file_download_outlined,
                title: l10n.exportData,
                subtitle: l10n.exportDataSubtitle,
                onTap: _exportLockRecords,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(l10n.security),
              _buildSettingTile(
                icon: Icons.password,
                title: l10n.changeAdminPasscodeTitle,
                subtitle: l10n.updateSuperPasscode,
                onTap: _changeAdminPasscode,
              ),
              _buildSettingTile(
                icon: Icons.swap_horiz,
                title: l10n.transferLockToUser,
                subtitle: l10n.transferLockSubtitle,
                onTap: _transferLock,
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: _deleteLock,
                child: Text(l10n.deleteLockAction),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }



  // Action Methods
  void _renameLock() {
    final controller = TextEditingController(text: _lockName);
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameLock),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.newName),
        ),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              final newName = controller.text;
              if (newName.isNotEmpty) {
                try {
                  await _apiService.renameLock(lockId: widget.lock['lockId'].toString(), newName: newName);
                  if (!mounted) return;
                  setState(() => _lockName = newName);
                  navigator.pop();
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element - Reserved for future use (group assignment feature)
  void _showGroupSelection() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final groups = await _apiService.getGroupList();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectGroup),
        content: SizedBox(
          width: double.maxFinite,
          child: groups.isEmpty
              ? Text(l10n.noGroupsFoundCreateOne)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      title: Text(group['name']),
                      onTap: () async {
                        navigator.pop();
                        try {
                          await _apiService.setLockGroup(
                            lockId: widget.lock['lockId'].toString(),
                            groupId: group['groupId'].toString(),
                          );
                          if (!mounted) return;
                          setState(() {
                            _groupName = group['name'];
                          });
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(l10n.lockAssignedToGroup(group['name']))),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text(l10n.cancel),
          ),
          if (_groupName != null)
            TextButton(
              onPressed: () async {
                navigator.pop();
                // 0 sets to no group
                try {
                  await _apiService.setLockGroup(
                    lockId: widget.lock['lockId'].toString(),
                    groupId: "0",
                  );
                  if (!mounted) return;
                  setState(() {
                    _groupName = null;
                  });
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.groupAssignmentRemoved)),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                  );
                }
              },
              child: Text(l10n.removeGroupAssignment, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  void _updateBattery() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Simulation: assuming we read battery via SDK first
      await _apiService.updateElectricQuantity(
        lockId: widget.lock['lockId'].toString(),
        electricQuantity: widget.lock['battery'] ?? 100,
      );
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.batterySynced)));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAutoLockDialog() {
    final controller = TextEditingController(text: _autoLockSeconds.toString());
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.autoLockTime),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterTimeInSeconds),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(suffixText: l10n.secondsShortcut),
            ),
            const SizedBox(height: 12),
            const Text(
              "Note: Only the Lock Admin can change this setting.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Properly dispose controller when cancelling
              // (Ideally should be done in a StatefulWidget dialog, but this is okay for now if we don't leak)
              navigator.pop();
            },
            child: Text(l10n.cancel)
          ),
          TextButton(
            onPressed: () async {
              // Check if user is Admin
              // userType 110301 is Admin usually.
              // We check if it is available in lock map.
              // If we are not sure, we proceed but warn on failure.
              
              final seconds = int.tryParse(controller.text) ?? 0;
              final lockData = _lockData;
              final lockId = widget.lock['lockId'].toString();
              
              bool hasGateway = false;
              if (widget.lock['hasGateway'] is int) {
                hasGateway = widget.lock['hasGateway'] == 1;
              } else if (widget.lock['hasGateway'] is bool) {
                hasGateway = widget.lock['hasGateway'];
              }
              
              if (lockData.isEmpty) {
                 scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Lock data not found")));
                 return;
              }

              // 1. Close Input Dialog
              navigator.pop(); 
              
              // 2. Small delay to ensure dialog closed
              await Future.delayed(const Duration(milliseconds: 200));

              // 3. Show Loading Dialog
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
              );

              bool bluetoothSuccess = false;
              String bluetoothError = "";

              final completer = Completer<void>();
              debugPrint("Attempting Bluetooth set Auto Lock: $seconds");

              TTLock.setLockAutomaticLockingPeriodicTime(seconds, lockData, () {
                  if (!completer.isCompleted) completer.complete();
              }, (errorCode, errorMsg) {
                  if (!completer.isCompleted) completer.completeError('$errorMsg (Code: $errorCode)');
              });

              try {
                await completer.future.timeout(const Duration(seconds: 3));
                bluetoothSuccess = true;
                debugPrint("Bluetooth set success.");
              } catch (e) {
                bluetoothSuccess = false;
                bluetoothError = e.toString();
                debugPrint("Bluetooth set failed: $bluetoothError");
              }

              // 4. Close Loading Dialog ALWAYS
              if (mounted) {
                navigator.pop(); 
              }

              // 5. Handle Result
              if (bluetoothSuccess) {
                 try {
                    await _apiService.setAutoLockTime(
                      lockId: lockId,
                      seconds: seconds,
                      type: 1, 
                    );
                  } catch (e) {
                    debugPrint("Cloud sync (Type 1) failed: $e");
                  }
                  
                  if (mounted) {
                    setState(() => _autoLockSeconds = seconds);
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.timeSet)));
                  }

              } else {
                if (hasGateway) {
                   debugPrint("Bluetooth failed, trying Gateway (Type 2)...");
                   // Show Gateway Loading
                   if (!mounted) return;
                   showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.green)),
                   );

                   try {
                      await _apiService.setAutoLockTime(
                        lockId: lockId,
                        seconds: seconds,
                        type: 2, 
                      );
                      
                      if (mounted) {
                        navigator.pop(); // Close gateway loading
                        setState(() => _autoLockSeconds = seconds);
                        scaffoldMessenger.showSnackBar(SnackBar(content: Text("${l10n.timeSet} (via Gateway)")));
                      }

                   } catch (e) {
                      debugPrint("Gateway set failed: $e");
                      if (mounted) {
                        navigator.pop(); // Close gateway loading
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Error"),
                            content: Text("Failed via Bluetooth: $bluetoothError\n\nFailed via Gateway: $e"),
                            actions: [TextButton(onPressed: () => navigator.pop(), child: const Text("OK"))],
                          ),
                        );
                      }
                   }
                } else {
                   if (mounted) {
                     String errorMsg = l10n.errorLabel;
                     if (bluetoothError.contains("Timeout")) {
                       errorMsg = "Bluetooth operation timed out.";
                     } else {
                       errorMsg = bluetoothError;
                     }

                     showDialog(
                       context: context,
                       builder: (dialogCtx) => AlertDialog(
                         title: const Text("Error"),
                         content: Text(errorMsg),
                         actions: [
                           TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text("OK")),
                           TextButton(
                             onPressed: () async {
                               Navigator.of(dialogCtx).pop(); // Close error dialog
                               
                               // Use the Page's context (this.context), not the dialog's context
                               if (!mounted) return;
                               
                               showDialog(
                                  context: context, 
                                  barrierDismissible: false,
                                  builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.green)),
                               );

                               try {
                                  await _apiService.setAutoLockTime(
                                    lockId: lockId,
                                    seconds: seconds,
                                    type: 2, 
                                  );
                                  
                                  if (mounted) {
                                    Navigator.of(context).pop(); // Close gateway loading
                                    setState(() => _autoLockSeconds = seconds);
                                    scaffoldMessenger.showSnackBar(SnackBar(content: Text("${l10n.timeSet} (via Gateway)")));
                                  }
                               } catch (e) {
                                  debugPrint("Gateway retry failed: $e");
                                  if (mounted) {
                                    Navigator.of(context).pop(); // Close gateway loading
                                    scaffoldMessenger.showSnackBar(SnackBar(content: Text("Gateway failed: $e")));
                                  }
                               }
                             },
                             child: const Text("Try Gateway"),
                           )
                         ],
                       ),
                     );
                   }
                }
              }
            },
            child: Text(l10n.set),
          ),
        ],
      ),
    );
  }

  void _openPassageModePage() async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => PassageModePage(lock: widget.lock),
      ),
    );
    // Refresh settings after returning
    _fetchSettings();
  }

  // ignore: unused_element - Reserved for future use (working mode feature)
  void _showWorkingModeSettings() {
    // This could be a complex dialog or a separate page. For simplicity, let's show a basic choice.
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.workingMode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.continuouslyWorking),
              onTap: () => _setWorkingMode(1),
            ),
            ListTile(
              title: Text(l10n.freezingMode),
              onTap: () => _setWorkingMode(2),
            ),
            ListTile(
              title: Text(l10n.customHours),
              onTap: () {
                Navigator.pop(context);
                // Implementation for custom hours...
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setWorkingMode(int mode) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.configWorkingMode(
        lockId: widget.lock['lockId'].toString(),
        workingMode: mode,
        type: 2,
      );
      if (!mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.modeUpdated)));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  void _changeAdminPasscode() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeAdminPasscodeTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.newPasscodeTitle),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _apiService.changeAdminKeyboardPwd(
                    lockId: widget.lock['lockId'].toString(),
                    password: controller.text,
                  );
                  if (!mounted) return;
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.operationSuccessful)));
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }

  void _transferLock() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transferLockToUser),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.receiverUsernameTitle),
        ),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _apiService.transferLock(
                    lockIdList: [int.parse(widget.lock['lockId'].toString())],
                    receiverUsername: controller.text,
                  );
                  if (!mounted) return;
                  navigator.pop();
                  navigator.pop(); // Close settings page
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.transferInitiated)));
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.transferAction),
          ),
        ],
      ),
    );
  }

  void _deleteLock() {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLockConfirmationTitle),
        content: Text(l10n.deleteLockConfirmationMessage),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteLock(lockId: widget.lock['lockId'].toString());
                if (!mounted) return;
                navigator.pop();
                navigator.pop('deleted'); // Go back to list
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                );
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showWifiSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WifiLockPage(lockId: int.parse(widget.lock['lockId'].toString())),
      ),
    );
  }

  Future<void> _exportLockRecords() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final picked = await showDateRangePicker(
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
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(l10n.preparingRecords)),
    );

    try {
      final lockId = widget.lock['lockId'].toString();
      final lockName = widget.lock['lockAlias'] ?? widget.lock['lockName'] ?? _lockName ?? 'Lock';
      
      final records = await _apiService.getLockRecords(
        accessToken: _apiService.accessToken!,
        lockId: lockId,
        startDate: picked.start.millisecondsSinceEpoch,
        endDate: picked.end.millisecondsSinceEpoch,
        pageSize: 100,
      );
      
      // Add lock name to each record
      for (var r in records) {
        r['lockName'] = lockName;
      }

      if (records.isEmpty) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.noData)),
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final sanitizedLockName = lockName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final file = File('${directory.path}/${sanitizedLockName}_records.json');
      await file.writeAsString(jsonEncode(records));

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: '$lockName - Records Export'));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.exportError(e.toString())), backgroundColor: Colors.red),
      );
    }
  }
}
