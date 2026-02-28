import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'dart:async';

class CreatePasscodePage extends StatefulWidget {
  final Map<String, dynamic> lock;
  const CreatePasscodePage({super.key, required this.lock});

  @override
  State<CreatePasscodePage> createState() => _CreatePasscodePageState();
}

class _CreatePasscodePageState extends State<CreatePasscodePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  // Timed fields (Zamanlı)
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // One-time field (Bir kerelik) - Uses _startDate as the start time (valid for 6 hours)

  // Recurring fields (Yinelenen)
  PasscodeType _selectedCyclicType = PasscodeType.dailyCyclic;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 0: Kalıcı, 1: Zamanlı, 2: Tek Seferlik, 3: Yinelenen
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _passcodeController.dispose();
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
    if (pickedDate == null) return;
    if (!context.mounted) return;

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
        // End date cannot be before start date for timed passcodes
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _createCustomPasscodeNative(String passcode, int startDateMs, int endDateMs, String lockId, String name, ApiService apiService) async {
    final completer = Completer<void>();
    
    // Natively set it to the lock via Bluetooth
    TTLock.createCustomPasscode(
      passcode, 
      startDateMs, 
      endDateMs, 
      widget.lock['lockData'], 
      () {
        completer.complete();
      }, 
      (errorCode, errorMsg) {
        final l10n = AppLocalizations.of(context);
        completer.completeError(l10n?.cannotReachLockBluetooth(errorMsg) ?? 'Kilide ulaşılamadı. Bluetooth açık ve yakında olduğunuzdan emin olun. Hata: $errorMsg');
      }
    );
    
    await completer.future;
    
    // Now upload to Cloud
    await apiService.addPasscode(
      lockId: lockId,
      passcodeName: name,
      passcode: passcode,
      startDate: startDateMs,
      endDate: endDateMs,
    );
  }

  Future<void> _onNext() async {
    final name = _nameController.text.trim();
    final customPasscode = _passcodeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.nameRequired ?? 'Lütfen bir isim giriniz.')),
      );
      return;
    }

    // Validation for Custom passcodes (Kalıcı ve Zamanlı)
    if (_currentTabIndex <= 1) {
      if (customPasscode.isEmpty || customPasscode.length < 4 || customPasscode.length > 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.invalidPasscodeLengthAlt ?? 'Geçerli bir şifre giriniz (4-9 haneli). Veya boş bırakıp sistemi rasgele ürettirin.')),
        );
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final lockId = widget.lock['lockId'].toString();

      Map<String, dynamic> result;

      if (_currentTabIndex == 0) {
        // Kalıcı (Permanent)
        if (customPasscode.isNotEmpty) {
           final now = DateTime.now();
           final tenYearsLater = now.add(const Duration(days: 3650));
           await _createCustomPasscodeNative(
             customPasscode, 
             now.millisecondsSinceEpoch, 
             tenYearsLater.millisecondsSinceEpoch, 
             lockId, 
             name, 
             apiService
           );
           result = {'keyboardPwd': customPasscode};
        } else {
           result = await apiService.getRandomPasscode(
             lockId: lockId,
             passcodeType: PasscodeType.permanent,
             passcodeName: name,
             startDate: DateTime.now().millisecondsSinceEpoch,
           );
        }
      } else if (_currentTabIndex == 1) {
        // Zamanlı (Timed)
        if (customPasscode.isNotEmpty) {
           await _createCustomPasscodeNative(
             customPasscode, 
             _startDate.millisecondsSinceEpoch, 
             _endDate.millisecondsSinceEpoch, 
             lockId, 
             name, 
             apiService
           );
           result = {'keyboardPwd': customPasscode};
        } else {
           result = await apiService.getRandomPasscode(
             lockId: lockId,
             passcodeType: PasscodeType.timed,
             passcodeName: name,
             startDate: _startDate.millisecondsSinceEpoch,
             endDate: _endDate.millisecondsSinceEpoch,
           );
        }
      } else if (_currentTabIndex == 2) {
        // Tek Seferlik (One-Time)
        result = await apiService.getRandomPasscode(
             lockId: lockId,
             passcodeType: PasscodeType.oneTime,
             passcodeName: name,
             startDate: _startDate.millisecondsSinceEpoch,
           );
      } else {
        // Yinelenen (Recurring)
        result = await apiService.getRandomPasscode(
             lockId: lockId,
             passcodeType: _selectedCyclicType,
             passcodeName: name,
             startDate: _startDate.millisecondsSinceEpoch,
             endDate: _endDate.millisecondsSinceEpoch,
           );
      }

      if (!mounted) return;
      
      final generatedPasscode = result['keyboardPwd'] ?? customPasscode;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(l10n?.passcodeCreatedTitleAlt ?? 'Şifre Oluşturuldu!', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n?.yourLockPasscode ?? 'Kilit şifreniz:', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Text(
                  generatedPasscode,
                  style: const TextStyle(
                    color: Color(0xFF4A90FF),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.passcodeReadyToUse ?? 'Bu şifre kullanıma hazırdır. Kapıyı açmak için şifreyi tuşlayıp sonuna # (veya kilit simgesi) eklemeniz yeterlidir.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Close screen and return true
                },
                child: Text(l10n?.ok ?? 'Tamam', style: const TextStyle(color: Color(0xFF4A90FF))),
              ),
            ],
          );
        }
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.errorGeneric(e.toString()) ?? 'Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: Text(l10n?.createPasscodeTitle ?? 'Parola Oluştur', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          isScrollable: true,
          labelColor: const Color(0xFF4A90FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4A90FF),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l10n?.tabPermanent ?? 'Kalıcı'),
            Tab(text: l10n?.tabTimed ?? 'Zamanlı'),
            Tab(text: l10n?.tabOneTime ?? 'Tek Seferlik'),
            Tab(text: l10n?.tabRecurring ?? 'Yinelenen'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90FF)))
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPermanentTab(),
                      _buildTimedTab(),
                      _buildOneTimeTab(),
                      _buildRecurringTab(),
                    ],
                  ),
                ),
                _buildNextButton(l10n),
              ],
            ),
    );
  }

  // ==================== TAB CONTENT ====================

  Widget _buildPermanentTab() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(l10n),
          _buildCustomPasscodeField(l10n),
          _buildInfoMessage(l10n?.infoPermanent ?? 'Kalıcı şifreler süresiz geçerlidir. Kilit üzerinden silinene kadar çalışır. Şifreyi boş bırakırsanız sistem otomatik üretir.'),
        ],
      ),
    );
  }

  Widget _buildTimedTab() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(l10n),
          _buildCustomPasscodeField(l10n),
          _buildSettingsRow(l10n?.startDate ?? 'Başlangıç', dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildSettingsRow(l10n?.endDate ?? 'Bitiş', dateFormat.format(_endDate),
              onTap: () => _selectDateTime(context, false)),
          _buildInfoMessage(l10n?.infoTimed ?? 'Zamanlı şifreler belirtilen tarih aralığında geçerlidir. Şifreyi boş bırakırsanız sistem otomatik üretir.'),
        ],
      ),
    );
  }

  Widget _buildOneTimeTab() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(l10n),
          _buildSettingsRow(l10n?.startDate ?? 'Başlangıç', dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildInfoMessage(l10n?.infoOneTime ?? 'Tek seferlik şifreler, başlangıç saatinden itibaren 6 saat boyunca kullanılabilir ve kullanıldıktan sonra silinir. Sistem tarafından otomatik olarak üretilir.'),
        ],
      ),
    );
  }

  Widget _buildRecurringTab() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(l10n),
          _buildSettingsRow(l10n?.startDate ?? 'Başlangıç', dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildSettingsRow(l10n?.endDate ?? 'Bitiş', dateFormat.format(_endDate),
              onTap: () => _selectDateTime(context, false)),
          ListTile(
            title: Text(l10n?.recurringMode ?? 'Tekrar Modu', style: const TextStyle(color: Colors.white, fontSize: 16)),
            trailing: DropdownButton<PasscodeType>(
              value: _selectedCyclicType,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: PasscodeType.dailyCyclic, child: Text(l10n?.everyDay ?? 'Her Gün')),
                DropdownMenuItem(value: PasscodeType.workdayCyclic, child: Text(l10n?.workdays ?? 'Hafta İçi (Pzt-Cum)')),
                DropdownMenuItem(value: PasscodeType.weekendCyclic, child: Text(l10n?.weekend ?? 'Hafta Sonu')),
                DropdownMenuItem(value: PasscodeType.mondayCyclic, child: Text(l10n?.onlyMonday ?? 'Sadece Pazartesi')),
                DropdownMenuItem(value: PasscodeType.tuesdayCyclic, child: Text(l10n?.onlyTuesday ?? 'Sadece Salı')),
                DropdownMenuItem(value: PasscodeType.wednesdayCyclic, child: Text(l10n?.onlyWednesday ?? 'Sadece Çarşamba')),
                DropdownMenuItem(value: PasscodeType.thursdayCyclic, child: Text(l10n?.onlyThursday ?? 'Sadece Perşembe')),
                DropdownMenuItem(value: PasscodeType.fridayCyclic, child: Text(l10n?.onlyFriday ?? 'Sadece Cuma')),
                DropdownMenuItem(value: PasscodeType.saturdayCyclic, child: Text(l10n?.onlySaturday ?? 'Sadece Cumartesi')),
                DropdownMenuItem(value: PasscodeType.sundayCyclic, child: Text(l10n?.onlySunday ?? 'Sadece Pazar')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCyclicType = val);
                }
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A), indent: 16, endIndent: 16),
          _buildInfoMessage(l10n?.infoRecurring ?? 'Yinelenen şifreler yalnızca belirtilen günlerde aktiftir. Sistem tarafından otomatik olarak üretilir.'),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildNameField(AppLocalizations? l10n) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(l10n?.nameLabel ?? 'İsim', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: l10n?.passcodeNameHint ?? 'Şifre adı girin...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPasscodeField(AppLocalizations? l10n) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(l10n?.passcodeOptional ?? 'Şifre (Opsiyonel)', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: l10n?.passcodeLengthHint ?? '4-9 hane veya boş',
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

  Widget _buildInfoMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(AppLocalizations? l10n) {
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
            l10n?.createButtonAlt ?? 'Oluştur',
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
