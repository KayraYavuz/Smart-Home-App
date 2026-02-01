import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/ui/pages/feature_pages.dart';
import 'package:yavuz_lock/ui/pages/passage_mode/passage_mode_page.dart';


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

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(AuthRepository());
    _lockName = widget.lock['name'] ?? '';
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final lockId = widget.lock['lockId'].toString();
      
      // Fetch Passage Mode
      final passageConfig = await _apiService.getPassageModeConfiguration(lockId: lockId);
      
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
        // _autoLockSeconds = autoLockConfig['autoLockTime'] ?? 0; // Removing non-existent method call
        _groupName = (currentGroup.isNotEmpty) ? currentGroup['name'] : null;
      });
    } catch (e) {
      print('Error fetching settings: $e');
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
                icon: Icons.folder,
                title: l10n.groupSetting,
                subtitle: _groupName ?? l10n.manageGroup,
                onTap: _showGroupSelection,
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
              _buildSettingTile(
                icon: Icons.work_history,
                title: l10n.workingHours,
                subtitle: l10n.configureWorkingFreezingModes,
                onTap: _showWorkingModeSettings,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameLock),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.newName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              final newName = controller.text;
              if (newName.isNotEmpty) {
                try {
                  await _apiService.renameLock(lockId: widget.lock['lockId'].toString(), newName: newName);
                  if (!context.mounted) return;
                  setState(() => _lockName = newName);
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
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

  void _showGroupSelection() async {
    final groups = await _apiService.getGroupList();
    
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
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
                        Navigator.pop(context);
                        try {
                          await _apiService.setLockGroup(
                            lockId: widget.lock['lockId'].toString(),
                            groupId: group['groupId'].toString(),
                          );
                          if (!context.mounted) return;
                          setState(() {
                            _groupName = group['name'];
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.lockAssignedToGroup(group['name']))),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
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
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          if (_groupName != null)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // 0 sets to no group
                try {
                  await _apiService.setLockGroup(
                    lockId: widget.lock['lockId'].toString(),
                    groupId: "0",
                  );
                  if (!context.mounted) return;
                  setState(() {
                    _groupName = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.groupAssignmentRemoved)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
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
    try {
      // Simulation: assuming we read battery via SDK first
      await _apiService.updateElectricQuantity(
        lockId: widget.lock['lockId'].toString(),
        electricQuantity: widget.lock['battery'] ?? 100,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.batterySynced)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAutoLockDialog() {
    final controller = TextEditingController(text: _autoLockSeconds.toString());
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              final seconds = int.tryParse(controller.text) ?? 0;
              try {
                await _apiService.setAutoLockTime(
                  lockId: widget.lock['lockId'].toString(),
                  seconds: seconds,
                  type: 2, // Gateway/WiFi simulation
                );
                if (!context.mounted) return;
                setState(() {
                  _autoLockSeconds = seconds;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.timeSet)));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.errorWithMsg(e.toString()))),
                );
              }
            },
            child: Text(l10n.set),
          ),
        ],
      ),
    );
  }

  void _openPassageModePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassageModePage(lock: widget.lock),
      ),
    );
    // Refresh settings after returning
    _fetchSettings();
  }

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
    try {
      await _apiService.configWorkingMode(
        lockId: widget.lock['lockId'].toString(),
        workingMode: mode,
        type: 2,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.modeUpdated)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  void _changeAdminPasscode() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _apiService.changeAdminKeyboardPwd(
                    lockId: widget.lock['lockId'].toString(),
                    password: controller.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.operationSuccessful)));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transferLockToUser),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.receiverUsernameTitle),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _apiService.transferLock(
                    lockIdList: [int.parse(widget.lock['lockId'].toString())],
                    receiverUsername: controller.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Navigator.pop(context); // Close settings page
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.transferInitiated)));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLockConfirmationTitle),
        content: Text(l10n.deleteLockConfirmationMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteLock(lockId: widget.lock['lockId'].toString());
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pop(context, 'deleted'); // Go back to list
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
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
}
