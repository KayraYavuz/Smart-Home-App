import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../api_service.dart';
import '../../repositories/auth_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class ShareLockDialog extends StatefulWidget {
  final Map<String, dynamic> lock;

  const ShareLockDialog({
    super.key,
    required this.lock,
  });

  @override
  State<ShareLockDialog> createState() => _ShareLockDialogState();
}

class _ShareLockDialogState extends State<ShareLockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _remarksController = TextEditingController();

  int _selectedPermission = 2; // Default: Normal user
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;

  Map<int, String> _getPermissionOptions(AppLocalizations l10n) => {
    1: l10n.adminPermission,
    2: l10n.normalUserPermission,
    3: l10n.limitedUserPermission,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissionOptions = _getPermissionOptions(l10n);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.share, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.shareLockTitle(widget.lock['name']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Email/Phone Input
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailOrPhone,
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: l10n.emailOrPhoneHint,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_add, color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailOrPhoneRequired;
                    }
                    // Basic email validation
                    if (!value.contains('@') && !value.startsWith('+')) {
                      return l10n.validEmailOrPhoneRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Permission Selection
                Text(
                  l10n.permissionLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                Column(
                  children: [
                    // ignore: deprecated_member_use
                    RadioListTile<int>(
                      title: Text(
                        permissionOptions[1]!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: 1,
                      groupValue: _selectedPermission,
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPermission = value);
                      },
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    // ignore: deprecated_member_use
                    RadioListTile<int>(
                      title: Text(
                        permissionOptions[2]!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: 2,
                      groupValue: _selectedPermission,
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPermission = value);
                      },
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    // ignore: deprecated_member_use
                    RadioListTile<int>(
                      title: Text(
                        permissionOptions[3]!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: 3,
                      groupValue: _selectedPermission,
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPermission = value);
                      },
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: l10n.startDate,
                        selectedDate: _startDate,
                        onDateSelected: (date) {
                          setState(() {
                            _startDate = date;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: l10n.endDate,
                        selectedDate: _endDate,
                        onDateSelected: (date) {
                          setState(() {
                            _endDate = date;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: InputDecoration(
                    labelText: l10n.remarksLabel,
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: l10n.remarksHint,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _shareLock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                l10n.share,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blue,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );

        if (!mounted) return;

        if (pickedDate != null) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.blue,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedTime != null) {
            final combinedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            onDateSelected(combinedDateTime);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}'
                        : AppLocalizations.of(context)!.notSelected,
                    style: TextStyle(
                      color: selectedDate != null ? Colors.white : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.access_time,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectStartEndDate),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token alınamadı');
      }

      final originalReceiver = _emailController.text.trim();
      final String emailSmall = originalReceiver.toLowerCase();
      final String sanitized = emailSmall.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final String beforeAt = emailSmall.contains('@') ? emailSmall.split('@')[0] : emailSmall;

      final List<String> receiversToTry = [
        'fihbg_$sanitized', 
        'fihbg_$beforeAt',
        originalReceiver,
      ];

      bool shareSuccess = false;
      String? lastError;

      for (String receiver in receiversToTry) {
        if (receiver.isEmpty) continue;
        try {
          await apiService.sendEKey(
            accessToken: accessToken,
            lockId: widget.lock['lockId'].toString(),
            receiverUsername: receiver,
            keyName: 'Key for $originalReceiver',
            startDate: _startDate!,
            endDate: _endDate!,
            remoteEnable: _selectedPermission == 1 ? 1 : 2, // Map permission logic as needed
            createUser: 2, 
          );
          shareSuccess = true;
          break; 
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (!shareSuccess) {
        try {
          await apiService.sendEKey(
            accessToken: accessToken,
            lockId: widget.lock['lockId'].toString(),
            receiverUsername: originalReceiver,
            keyName: 'Key for $originalReceiver',
            startDate: _startDate!,
            endDate: _endDate!,
            remoteEnable: _selectedPermission == 1 ? 1 : 2,
            createUser: 1, 
          );
          shareSuccess = true;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (!shareSuccess) {
        throw Exception(lastError ?? 'Paylaşım başarısız');
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lockSharedSuccess(widget.lock['name'])),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.sharingError}: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}