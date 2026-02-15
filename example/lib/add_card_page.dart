import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:intl/intl.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:nfc_manager/nfc_manager.dart';

class AddCardPage extends StatefulWidget {
  final String lockId;
  final String lockData;
  const AddCardPage({super.key, required this.lockId, required this.lockData});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cardNameController = TextEditingController();

  // Timed fields
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  // Recurring fields
  List<int> _selectedDays = [];
  TimeOfDay _recurringStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _recurringEndTime = const TimeOfDay(hour: 23, minute: 59);
  DateTime _recurringStartDate = DateTime.now();
  DateTime _recurringEndDate = DateTime.now().add(const Duration(days: 365));
  bool _recurringConfigured = false;

  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  int get _currentTabIndex => _tabController.index;

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4A90FF),
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4A90FF),
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return;

    final combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    setState(() {
      if (isStart) {
        _startDate = combined;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      } else {
        _endDate = combined;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(hours: 1));
        }
      }
    });
  }



  /// Next button: Start phone NFC scan → read card number → register via Gateway
  Future<void> _onNext() async {
    final cardName = _cardNameController.text.trim();
    if (cardName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.cardNameRequired ?? 'Card name is required')),
      );
      return;
    }

    if (_currentTabIndex == 2 && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.selectDays ?? 'Please configure the validity period')),
      );
      return;
    }

    // Check NFC availability
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = AppLocalizations.of(context)?.scanCardWithPhone ?? 'Hold the card to your phone...';
    });

    try {
      final completer = Completer<String>();

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Read card UID from NFC tag
            List<int>? identifier;

            final nfcA = tag.data['nfca'];
            final nfcB = tag.data['nfcb'];
            final isoDep = tag.data['isodep'];
            final mifareClassic = tag.data['mifareclassic'];
            final mifareUltralight = tag.data['mifareultralight'];

            if (nfcA != null && nfcA['identifier'] != null) {
              identifier = List<int>.from(nfcA['identifier']);
            } else if (nfcB != null && nfcB['identifier'] != null) {
              identifier = List<int>.from(nfcB['identifier']);
            } else if (isoDep != null && isoDep['identifier'] != null) {
              identifier = List<int>.from(isoDep['identifier']);
            } else if (mifareClassic != null && mifareClassic['identifier'] != null) {
              identifier = List<int>.from(mifareClassic['identifier']);
            } else if (mifareUltralight != null && mifareUltralight['identifier'] != null) {
              identifier = List<int>.from(mifareUltralight['identifier']);
            }

            await NfcManager.instance.stopSession();

            if (identifier != null && identifier.isNotEmpty) {
              final cardNumber = identifier
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
              if (!completer.isCompleted) completer.complete(cardNumber);
            } else {
              if (!completer.isCompleted) {
                completer.completeError(Exception('Could not read card number'));
              }
            }
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            if (!completer.isCompleted) completer.completeError(e);
          }
        },
        onError: (error) async {
          if (!completer.isCompleted) completer.completeError(error);
        },
      );

      final cardNumber = await completer.future;
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Card: $cardNumber\nSaving...';
      });

      // Get date params
      int startDateMs;
      int endDateMs;
      List<Map<String, dynamic>>? cyclicConfig;

      if (_currentTabIndex == 1) {
        // Permanent
        startDateMs = 0;
        endDateMs = 0;
      } else if (_currentTabIndex == 0) {
        // Timed
        startDateMs = _startDate.millisecondsSinceEpoch;
        endDateMs = _endDate.millisecondsSinceEpoch;
      } else {
        // Recurring
        startDateMs = _recurringStartDate.millisecondsSinceEpoch;
        endDateMs = _recurringEndDate.millisecondsSinceEpoch;
        final startMinutes = _recurringStartTime.hour * 60 + _recurringStartTime.minute;
        final endMinutes = _recurringEndTime.hour * 60 + _recurringEndTime.minute;
        cyclicConfig = _selectedDays.map((day) => {
          "weekDay": day,
          "startTime": startMinutes,
          "endTime": endMinutes,
        }).toList();
      }

      // Register card on server via Gateway (remote)
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.addIdentityCard(
        lockId: widget.lockId,
        cardNumber: cardNumber,
        startDate: startDateMs,
        endDate: endDateMs,
        cardName: cardName,
        addType: 2, // Gateway — remote
        cyclicConfig: cyclicConfig,
        cardType: _currentTabIndex == 2 ? 4 : 1,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Card added successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      try { await NfcManager.instance.stopSession(); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  void _openValidityPeriodPage() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => _ValidityPeriodPage(
          selectedDays: _selectedDays,
          startDate: _recurringStartDate,
          endDate: _recurringEndDate,
          startTime: _recurringStartTime,
          endTime: _recurringEndTime,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDays = List<int>.from(result['selectedDays']);
        _recurringStartDate = result['startDate'];
        _recurringEndDate = result['endDate'];
        _recurringStartTime = result['startTime'];
        _recurringEndTime = result['endTime'];
        _recurringConfigured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(l10n.addCard, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: const Color(0xFF4A90FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4A90FF),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l10n.tabTimed),
            Tab(text: l10n.tabPermanent),
            Tab(text: l10n.tabRecurring),
          ],
        ),
      ),
      body: _isLoading
          ? _buildScanningState(l10n)
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTimedTab(l10n),
                      _buildPermanentTab(l10n),
                      _buildRecurringTab(l10n),
                    ],
                  ),
                ),
                _buildNextButton(l10n),
              ],
            ),
    );
  }

  // ==================== SCANNING STATE ====================

  Widget _buildScanningState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.nfc, color: Color(0xFF4A90FF), size: 56),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF4A90FF)),
            const SizedBox(height: 20),
            Text(
              _statusMessage ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                try { await NfcManager.instance.stopSession(); } catch (_) {}
                setState(() {
                  _isLoading = false;
                  _statusMessage = null;
                });
              },
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB CONTENT ====================

  Widget _buildPermanentTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(children: [_buildNameField(l10n)]),
    );
  }

  Widget _buildTimedTab(AppLocalizations l10n) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(l10n),
          _buildSettingsRow(l10n.startDate, dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildSettingsRow(l10n.endDate, dateFormat.format(_endDate),
              onTap: () => _selectDateTime(context, false)),
        ],
      ),
    );
  }

  Widget _buildRecurringTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(l10n),
          _buildSettingsRow(
            l10n.validityPeriod,
            _recurringConfigured ? l10n.configured : '',
            onTap: _openValidityPeriodPage,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildNameField(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(l10n.nameLabel, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _cardNameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: l10n.enterHere,
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String label, String value, {VoidCallback? onTap, bool showArrow = false}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty)
              Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            if (showArrow)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNextButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            elevation: 0,
          ),
          child: Text(
            l10n.next,
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ==================== VALIDITY PERIOD PAGE ====================

class _ValidityPeriodPage extends StatefulWidget {
  final List<int> selectedDays;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const _ValidityPeriodPage({
    required this.selectedDays,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<_ValidityPeriodPage> createState() => _ValidityPeriodPageState();
}

class _ValidityPeriodPageState extends State<_ValidityPeriodPage> {
  late List<int> _selectedDays;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  final List<String> _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<int> _dayValues = [7, 1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _selectedDays = List<int>.from(widget.selectedDays);
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF4A90FF), surface: Color(0xFF1E1E1E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF4A90FF), surface: Color(0xFF1E1E1E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(l10n?.validityPeriod ?? 'Validity Period',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(l10n?.startDate ?? 'Start Date', DateFormat('yyyy-MM-dd').format(_startDate),
              onTap: () => _pickDate(true)),
          _buildDivider(),
          _buildRow(l10n?.endDate ?? 'End Date', DateFormat('yyyy-MM-dd').format(_endDate),
              onTap: () => _pickDate(false)),
          _buildDivider(),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: const Text('Cycle on', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final dayValue = _dayValues[index];
                final isSelected = _selectedDays.contains(dayValue);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(dayValue);
                      } else {
                        _selectedDays.add(dayValue);
                      }
                    });
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF4A90FF) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4A90FF) : Colors.grey[600]!,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayLabels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
          _buildDivider(),
          _buildRow(l10n?.startTime ?? 'Start Time', _startTime.format(context),
              onTap: () => _pickTime(true)),
          _buildDivider(),
          _buildRow(l10n?.endTime ?? 'End Time', _endTime.format(context),
              onTap: () => _pickTime(false)),
          _buildDivider(),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'selectedDays': _selectedDays,
                    'startDate': _startDate,
                    'endDate': _endDate,
                    'startTime': _startTime,
                    'endTime': _endTime,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                child: Text(
                  l10n?.ok ?? 'OK',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFF2A2A2A), indent: 16, endIndent: 16);
  }
}
