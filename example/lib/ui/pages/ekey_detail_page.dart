
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class EKeyDetailPage extends StatefulWidget {
  final Map<String, dynamic> eKey;
  final String lockId;
  final String lockName;
  final bool isOwner; // Current user is the owner of the lock (admin)

  const EKeyDetailPage({
    super.key,
    required this.eKey,
    required this.lockId,
    required this.lockName,
    required this.isOwner,
  });

  @override
  State<EKeyDetailPage> createState() => _EKeyDetailPageState();
}

class _EKeyDetailPageState extends State<EKeyDetailPage> {
  late Map<String, dynamic> _eKey;
  bool _isLoading = false;
  late ApiService _apiService;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _eKey = Map.from(widget.eKey);
    // Initialize access token after build to access context, or use Future.microtask
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService = ApiService(context.read<AuthRepository>());
      _initAccessToken();
    });
  }

  Future<void> _initAccessToken() async {
    await _apiService.getAccessToken();
    if (mounted) {
      setState(() {
        _accessToken = _apiService.accessToken;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check key status
    // 110401: Normal, 110405: Frozen, 110402: Pending, 110408: Deleting, 110410: Resetting
    final keyStatus = _eKey['keyStatus'];
    bool isFrozen = keyStatus == '110405';
    // keyRight: 0-No, 1-Yes (Authorized admin)
    bool isAuthorized = _eKey['keyRight'] == 1;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lockName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: isAuthorized ? Colors.blue : Colors.orange,
                    child: Icon(
                      isAuthorized ? Icons.admin_panel_settings : Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _eKey['keyName'] ?? l10n.key,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eKey['username'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFrozen ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFrozen ? Colors.red : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isFrozen ? l10n.frozen : l10n.active,
                      style: TextStyle(
                        color: isFrozen ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Info Cards
            _buildInfoCard(
              l10n.validityPeriod,
              '${_formatDate(_eKey['startDate'])} - ${_formatDate(_eKey['endDate'])}',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              l10n.authorizationStatus,
              isAuthorized ? l10n.authorizedAdmin : l10n.normalUser,
              Icons.security,
            ),
            const SizedBox(height: 12),
             _buildInfoCard(
              l10n.remoteUnlock,
              _eKey['remoteEnable'] == 1 ? l10n.active : l10n.passive,
              Icons.wifi_tethering,
            ),

            const SizedBox(height: 32),

            // Actions (Only for admin/owner)
            if (widget.isOwner) ...[
              Text(
                l10n.actions,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Freeze / Unfreeze
                  _buildActionButton(
                    label: isFrozen ? l10n.unfreeze : l10n.freeze,
                    icon: isFrozen ? Icons.ac_unit : Icons.ac_unit_outlined,
                    color: isFrozen ? Colors.green : Colors.orange,
                    onTap: () => _toggleFreezeStatus(isFrozen),
                  ),

                  // Authorize / Unauthorize
                  _buildActionButton(
                    label: isAuthorized ? l10n.revokeAuthority : l10n.authorize,
                    icon: isAuthorized ? Icons.remove_moderator : Icons.add_moderator,
                    color: isAuthorized ? Colors.redAccent : Colors.blue,
                    onTap: () => _toggleAuthorization(isAuthorized),
                  ),

                  // Change Period
                  _buildActionButton(
                    label: l10n.changePeriod,
                    icon: Icons.edit_calendar,
                    color: Colors.purple,
                    onTap: _showChangePeriodDialog,
                  ),

                   // Rename / Update Remote
                  _buildActionButton(
                    label: l10n.edit,
                    icon: Icons.edit,
                    color: Colors.blueGrey,
                    onTap: _showUpdateDialog,
                  ),

                  // Get Unlock Link
                  _buildActionButton(
                    label: l10n.unlockLink,
                    icon: Icons.link,
                    color: Colors.teal,
                    onTap: _getUnlockLink,
                  ),

                  // Delete
                  _buildActionButton(
                    label: l10n.delete,
                    icon: Icons.delete,
                    color: Colors.red,
                    onTap: _confirmDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF2C2C2C),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width / 3 - 24, // Dynamic width for 3 cols roughly
          constraints: const BoxConstraints(minHeight: 100), // Reduced from 110
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), // Reduced vertical from 16
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced from 10
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22), // Reduced from 24
              ),
              const SizedBox(height: 6), // Reduced from 8
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10, // Reduced from 11
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    // Timestamp is in milliseconds
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleFreezeStatus(bool isCurrentlyFrozen) async {
    if (_accessToken == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      if (isCurrentlyFrozen) {
        await _apiService.unfreezeEKey(
          accessToken: _accessToken!,
          keyId: _eKey['keyId'].toString(),
        );
        _eKey['keyStatus'] = '110401'; // Normal
      } else {
        await _apiService.freezeEKey(
          accessToken: _accessToken!,
          keyId: _eKey['keyId'].toString(),
        );
        _eKey['keyStatus'] = '110405'; // Frozen
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isCurrentlyFrozen ? l10n.unfreezeSuccess : l10n.freezeSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAuthorization(bool isCurrentlyAuthorized) async {
    if (_accessToken == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      if (isCurrentlyAuthorized) {
        await _apiService.unauthorizeEKey(
          accessToken: _accessToken!,
          lockId: widget.lockId,
          keyId: _eKey['keyId'].toString(),
        );
        _eKey['keyRight'] = 0;
      } else {
        await _apiService.authorizeEKey(
          accessToken: _accessToken!,
          lockId: widget.lockId,
          keyId: _eKey['keyId'].toString(),
        );
        _eKey['keyRight'] = 1;
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isCurrentlyAuthorized ? l10n.revokeSuccess : l10n.authorizeSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

   Future<void> _getUnlockLink() async {
    if (_accessToken == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getUnlockLink(
        accessToken: _accessToken!,
        keyId: _eKey['keyId'].toString(),
      );
      
      final link = result['link'];
      if (link != null) {
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(l10n.unlockLink, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.unlockLinkDescription,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  link,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                   Clipboard.setData(ClipboardData(text: link));
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(l10n.linkCopied)),
                   );
                   Navigator.pop(context);
                },
                 child: Text(l10n.copy),
               ),
               TextButton(
                 onPressed: () => Navigator.pop(context),
                 child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
               ),
            ],
          ),
        );
      }
    } catch (e) {
      String msg = l10n.linkRetrievalError(e.toString());
      if (e.toString().contains('20002') || e.toString().contains('Not lock admin')) {
        msg = l10n.authorityError;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showChangePeriodDialog() {
    // Current dates
    DateTime currentStart = DateTime.fromMillisecondsSinceEpoch(_eKey['startDate']);
    DateTime currentEnd = DateTime.fromMillisecondsSinceEpoch(_eKey['endDate']);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => _ChangePeriodDialog(
        initialStartDate: currentStart, 
        initialEndDate: currentEnd,
        onSave: (start, end) async {
           if (_accessToken == null) return;
           try {
             await _apiService.changeEKeyPeriod(
               accessToken: _accessToken!,
               keyId: _eKey['keyId'].toString(),
               startDate: start,
               endDate: end,
             );
             
             if (!mounted) return;
             setState(() {
               _eKey['startDate'] = start.millisecondsSinceEpoch;
               _eKey['endDate'] = end.millisecondsSinceEpoch;
             });
             
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(l10n.updateSuccess)),
             );
           } catch(e) {
             if (!mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
             );
           }
        },
      ),
    );
  }

   void _showUpdateDialog() {
    final nameController = TextEditingController(text: _eKey['keyName']);
    // remoteEnable: 1-yes, 2-no
    bool remoteInfo = _eKey['remoteEnable'] == 1;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        bool remoteEnabled = remoteInfo;
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(l10n.edit, style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.nameLabel,
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 16),
                   SwitchListTile(
                    title: Text(l10n.allowRemoteUnlock, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(l10n.gatewayRequired, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    value: remoteEnabled,
                    onChanged: (val) {
                      setStateSB(() => remoteEnabled = val);
                    },
                    activeTrackColor: Colors.blue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (_accessToken == null) return;
                    
                    try {
                       await _apiService.updateEKey(
                         accessToken: _accessToken!, 
                         keyId: _eKey['keyId'].toString(),
                         keyName: nameController.text,
                         remoteEnable: remoteEnabled ? 1 : 2,
                       );

                       if (!mounted) return;
                       setState(() {
                         _eKey['keyName'] = nameController.text;
                         _eKey['remoteEnable'] = remoteEnabled ? 1 : 2;
                       });
                       
                       ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.updateSuccess)),
                       );
                    } catch(e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text(l10n.save, style: const TextStyle(color: Colors.blue)),
                ),
              ],
            );
          }
        );
      },
    );
  }


  void _confirmDelete() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteKeyConfirmation,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
               Navigator.pop(context);
               if (_accessToken == null) return;

               try {
                 await _apiService.deleteEKey(
                   accessToken: _accessToken!,
                   keyId: _eKey['keyId'].toString(),
                 );
                 
                 if (!mounted) return;
                 Navigator.pop(context, 'deleted'); // Return to list with deleted signal
               } catch(e) {
                 if (!mounted) return;
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                 );
               }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ChangePeriodDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onSave;

  const _ChangePeriodDialog({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onSave,
  });

  @override
  State<_ChangePeriodDialog> createState() => __ChangePeriodDialogState();
}

class __ChangePeriodDialogState extends State<_ChangePeriodDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark(),
            child: child!,
          );
        },
      );

      if (time != null) {
         setState(() {
           final newDate = DateTime(
             picked.year, 
             picked.month, 
             picked.day, 
             time.hour, 
             time.minute
           );
           
           if (isStart) {
             _startDate = newDate;
           } else {
             _endDate = newDate;
           }
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(l10n.changePeriod, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.start, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            subtitle: Text(
              '${_startDate.day}.${_startDate.month}.${_startDate.year} ${_startDate.hour}:${_startDate.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.calendar_today, color: Colors.blue),
            onTap: () => _selectDate(true),
          ),
          ListTile(
             title: Text(l10n.end, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            subtitle: Text(
              '${_endDate.day}.${_endDate.month}.${_endDate.year} ${_endDate.hour}:${_endDate.minute.toString().padLeft(2, '0')}',
               style: const TextStyle(color: Colors.white),
            ),
             trailing: const Icon(Icons.event_busy, color: Colors.blue),
            onTap: () => _selectDate(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            if (_endDate.isBefore(_startDate)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.dateError)),
              );
              return;
            }
            Navigator.pop(context);
            widget.onSave(_startDate, _endDate);
          },
          child: Text(l10n.save, style: const TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
