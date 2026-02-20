import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:intl/intl.dart';

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
    if (!mounted) return;

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

  Future<void> _onNext() async {
    final name = _nameController.text.trim();
    final customPasscode = _passcodeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir isim giriniz.')),
      );
      return;
    }

    // Validation for Custom passcodes (Kalıcı ve Zamanlı)
    if (_currentTabIndex <= 1) {
      if (customPasscode.isEmpty || customPasscode.length < 4 || customPasscode.length > 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir şifre giriniz (4-9 haneli). Veya boş bırakıp sistemi rasgele ürettirin.')),
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
           result = await apiService.addPasscode(
             lockId: lockId,
             passcodeName: name,
             passcode: customPasscode,
             startDate: 0,
             endDate: 0,
           );
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
           result = await apiService.addPasscode(
             lockId: lockId,
             passcodeName: name,
             passcode: customPasscode,
             startDate: _startDate.millisecondsSinceEpoch,
             endDate: _endDate.millisecondsSinceEpoch,
           );
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
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Şifre Oluşturuldu!', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kilit şifreniz:', style: TextStyle(color: Colors.grey)),
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
              const Text(
                'Lütfen bu şifreyi kilidin tuş takımına girerek etkinleştirin. (# veya kilit tuşuna basarak onaylayın)',
                style: TextStyle(color: Colors.grey, fontSize: 13),
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
              child: const Text('Tamam', style: TextStyle(color: Color(0xFF4A90FF))),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Parola Oluştur', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
          tabs: const [
            Tab(text: 'Kalıcı'),
            Tab(text: 'Zamanlı'),
            Tab(text: 'Tek Seferlik'),
            Tab(text: 'Yinelenen'),
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
                _buildNextButton(),
              ],
            ),
    );
  }

  // ==================== TAB CONTENT ====================

  Widget _buildPermanentTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(),
          _buildCustomPasscodeField(),
          _buildInfoMessage('Kalıcı şifreler süresiz geçerlidir. Kilit üzerinden silinene kadar çalışır. Şifreyi boş bırakırsanız sistem otomatik üretir.'),
        ],
      ),
    );
  }

  Widget _buildTimedTab() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(),
          _buildCustomPasscodeField(),
          _buildSettingsRow('Başlangıç', dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildSettingsRow('Bitiş', dateFormat.format(_endDate),
              onTap: () => _selectDateTime(context, false)),
          _buildInfoMessage('Zamanlı şifreler belirtilen tarih aralığında geçerlidir. Şifreyi boş bırakırsanız sistem otomatik üretir.'),
        ],
      ),
    );
  }

  Widget _buildOneTimeTab() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(),
          _buildSettingsRow('Başlangıç', dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildInfoMessage('Tek seferlik şifreler, başlangıç saatinden itibaren 6 saat boyunca kullanılabilir ve kullanıldıktan sonra silinir. Sistem tarafından otomatik olarak üretilir.'),
        ],
      ),
    );
  }

  Widget _buildRecurringTab() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNameField(),
          _buildSettingsRow('Başlangıç', dateFormat.format(_startDate),
              onTap: () => _selectDateTime(context, true)),
          _buildSettingsRow('Bitiş', dateFormat.format(_endDate),
              onTap: () => _selectDateTime(context, false)),
          ListTile(
            title: const Text('Tekrar Modu', style: TextStyle(color: Colors.white, fontSize: 16)),
            trailing: DropdownButton<PasscodeType>(
              value: _selectedCyclicType,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: PasscodeType.dailyCyclic, child: Text('Her Gün')),
                DropdownMenuItem(value: PasscodeType.workdayCyclic, child: Text('Hafta İçi (Pzt-Cum)')),
                DropdownMenuItem(value: PasscodeType.weekendCyclic, child: Text('Hafta Sonu')),
                DropdownMenuItem(value: PasscodeType.mondayCyclic, child: Text('Sadece Pazartesi')),
                DropdownMenuItem(value: PasscodeType.tuesdayCyclic, child: Text('Sadece Salı')),
                DropdownMenuItem(value: PasscodeType.wednesdayCyclic, child: Text('Sadece Çarşamba')),
                DropdownMenuItem(value: PasscodeType.thursdayCyclic, child: Text('Sadece Perşembe')),
                DropdownMenuItem(value: PasscodeType.fridayCyclic, child: Text('Sadece Cuma')),
                DropdownMenuItem(value: PasscodeType.saturdayCyclic, child: Text('Sadece Cumartesi')),
                DropdownMenuItem(value: PasscodeType.sundayCyclic, child: Text('Sadece Pazar')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCyclicType = val);
                }
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A), indent: 16, endIndent: 16),
          _buildInfoMessage('Yinelenen şifreler yalnızca belirtilen günlerde aktiftir. Sistem tarafından otomatik olarak üretilir.'),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildNameField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('İsim', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: 'Şifre adı girin...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPasscodeField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('Şifre (Opsiyonel)', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: '4-9 hane veya boş',
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

  Widget _buildNextButton() {
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
          child: const Text(
            'Oluştur',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
