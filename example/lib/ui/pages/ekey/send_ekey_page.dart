import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:url_launcher/url_launcher.dart'; // Email/SMS launch
import '../../theme.dart';
import '../../../api_service.dart';
import '../../../repositories/auth_repository.dart';
import 'recurring_period_page.dart';  // Import the new page
import 'dart:convert'; // For jsonEncode if needed locally, but APIService handles it

class SendEKeyPage extends StatefulWidget {
  final Map<String, dynamic> lock;

  const SendEKeyPage({super.key, required this.lock});

  @override
  State<SendEKeyPage> createState() => _SendEKeyPageState();
}

class _SendEKeyPageState extends State<SendEKeyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  // Timed Defaults
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));

  // Recurring Data
  bool _isRecurringConfigured = false;
  DateTime _recStartDate = DateTime.now();
  DateTime _recEndDate = DateTime.now().add(const Duration(days: 365));
  List<int> _recDays = [1, 2, 3, 4, 5, 6, 7]; // All days default? Or empty.
  TimeOfDay _recStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _recEndTime = const TimeOfDay(hour: 23, minute: 59);

  bool _allowRemoteUnlock = false;
  bool _isLoading = false;
  String _receiverInput = "";

  final List<String> _tabs = ["Zamanlanmış", "Bir kere", "Kalıcı", "Yinelenen"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiverController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
         builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
      );

      if (time != null) {
        setState(() {
          final newDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isStart) {
            _startDate = newDate;
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _endDate = newDate;
          }
        });
      }
    }
  }

  void _openRecurringSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringPeriodPage(
          onSave: (start, end, days, startTime, endTime) {
            setState(() {
              _recStartDate = start;
              _recEndDate = end;
              _recDays = days;
              _recStartTime = startTime;
              _recEndTime = endTime;
              _isRecurringConfigured = true;
            });
          },
        ),
      ),
    );
  }

  Future<void> _sendKey() async {
    String receiver = _receiverController.text.trim();
    if (receiver.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen alıcı giriniz')));
      return;
    }
    
    // Email normalization
    if (receiver.contains('@')) {
      receiver = receiver.toLowerCase();
    }
    _receiverInput = receiver; // Store for sharing

    if (_tabController.index == 3 && !_isRecurringConfigured) {
       // Force configure if recurring tab selected but not configured? 
       // Or use defaults? Let's assume defaults if not set, or prompt.
       // The UI shows "Geçerlilik süresi" row. 
    }

    DateTime finalStart = _startDate;
    DateTime finalEnd = _endDate;
    List<Map<String, dynamic>>? cyclicConfig;

    // 0: Timed -> Use _startDate, _endDate
    if (_tabController.index == 0) {
      finalStart = _startDate;
      finalEnd = _endDate;
    }
    // 1: One-time (Bir kere)
    else if (_tabController.index == 1) {
      finalStart = DateTime.now();
      finalEnd = finalStart.add(const Duration(hours: 1));
    }
    // 2: Permanent (Kalıcı)
    else if (_tabController.index == 2) {
      finalStart = DateTime.now();
      finalEnd = DateTime(2099, 12, 31, 23, 59, 59);
    }
    // 3: Recurring (Yinelenen)
    else if (_tabController.index == 3) {
      finalStart = _recStartDate; // Validity period start
      finalEnd = _recEndDate;     // Validity period end

      // Create cyclic config
      // WeekDay: 1-Sun...
      // startTime/endTime: minutes from midnight
      cyclicConfig = _recDays.map((day) {
        return {
          'weekDay': day,
          'startTime': _recStartTime.hour * 60 + _recStartTime.minute,
          'endTime': _recEndTime.hour * 60 + _recEndTime.minute,
        };
      }).toList();
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();
      final token = apiService.accessToken;

      if (token == null) throw Exception('Token bulunamadı');

      final result = await apiService.sendEKey(
        accessToken: token,
        lockId: widget.lock['lockId'].toString(),
        receiverUsername: receiver,
        keyName: _nameController.text.isEmpty ? receiver : _nameController.text,
        startDate: finalStart,
        endDate: finalEnd,
        remoteEnable: _allowRemoteUnlock ? 1 : 2,
        cyclicConfig: cyclicConfig,
        createUser: 1, // Auto-create user if not exists
      );

      // Fetch unlock link with retry mechanism
      String? unlockLink;
      if (result.containsKey('keyId')) {
        int retryCount = 0;
        const int maxRetries = 3;
        
        while (retryCount < maxRetries) {
          try {
             if (retryCount > 0) {
               await Future.delayed(const Duration(milliseconds: 1500)); // Wait before retry
             }
             
             final linkResult = await apiService.getUnlockLink(
               accessToken: token,
               keyId: result['keyId'].toString()
             );
             
             if (linkResult['link'] != null) {
               unlockLink = linkResult['link'];
               break; // Success, exit loop
             }
          } catch (e) {
            print("Link alma denemesi ${retryCount + 1} başarısız: $e");
            retryCount++;
            
            // If it's the last try, log the error but don't stop the flow
            if (retryCount >= maxRetries) {
               if (e.toString().contains('20002') || e.toString().contains('Not lock admin')) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not: Link oluşturma yetkisi sadece Kilit Sahibindedir.'), backgroundColor: Colors.orange));
               }
            }
          }
        }
      }
      
      // Always show success dialog if sendEKey worked, even if link failed
      if (mounted) {
        _showSuccessDialog(unlockLink);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String? link) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text('Başarıyla Gönderildi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Elektronik anahtar alıcıya iletildi.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            if (link != null) ...[
               const SizedBox(height: 20),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.black,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                 ),
                 child: Column(
                   children: [
                     const Text('Paylaşılabilir Link:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     const SizedBox(height: 4),
                     SelectableText(
                       link,
                       style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                       textAlign: TextAlign.center,
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 12),
               
               // Share Buttons
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                    // Copy
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link kopyalandı')));
                      },
                      tooltip: 'Kopyala',
                    ),
                    // Email
                    if (_receiverInput.contains('@'))
                      IconButton(
                        icon: const Icon(Icons.email, color: AppColors.primary),
                        onPressed: () => _launchEmail(_receiverInput, link),
                        tooltip: 'E-posta ile gönder',
                      )
                    else 
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.green),
                        onPressed: () => _launchSMS(_receiverInput, link),
                        tooltip: 'SMS ile gönder',
                      ),
                 ],
               )
            ] else ...[
               const SizedBox(height: 20),
               const Text(
                 'Anahtar başarıyla gönderildi, ancak yetki kısıtlaması nedeniyle web linki oluşturulamadı.\nAlıcı uygulamayı indirerek anahtarı kullanabilir.',
                 style: TextStyle(color: Colors.orange, fontSize: 13),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 12),
                if (_receiverInput.contains('@'))
                  TextButton.icon(
                    icon: const Icon(Icons.email, color: AppColors.primary),
                    onPressed: () => _launchEmail(_receiverInput, null),
                    label: const Text('Uygulama İndirme Linki Gönder'),
                  ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Tamam', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email, String? link) async {
    final String body = link != null 
        ? 'Merhaba, size bir akıllı kilit erişim anahtarı gönderdim. Erişmek için aşağıdaki linke tıklayabilirsiniz:\n\n$link'
        : 'Merhaba, size bir akıllı kilit erişim anahtarı gönderdim. Kullanmak için lütfen Yavuz Lock uygulamasını indirin ve giriş yapın.';
        
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Kilit Erişim Anahtarı&body=$body',
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch email';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta uygulaması bulunamadı')));
    }
  }

  Future<void> _launchSMS(String phoneNumber, String? link) async {
    final String body = link != null 
        ? 'Merhaba, size bir akıllı kilit erişim anahtarı gönderdim. Erişmek için aşağıdaki linke tıklayabilirsiniz:\n\n$link'
        : 'Merhaba, size bir akıllı kilit erişim anahtarı gönderdim. Kullanmak için lütfen Yavuz Lock uygulamasını indirin ve giriş yapın.';
    
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': body,
      },
    );
    try {
      if (!await launchUrl(smsLaunchUri)) {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS uygulaması bulunamadı')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Elektronik anahtar gönder', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Common Fields ---
            
            // Receiver
            _buildInputRow(
              label: 'Alıcı', 
              hint: 'Telefon numarası / E-posta', 
              controller: _receiverController,
              icon: Icons.contacts,
              keyboardType: TextInputType.emailAddress,
            ),
            
             // Name
            _buildInputRow(
              label: 'İsim', 
              hint: 'Lütfen buraya giriniz', 
              controller: _nameController,
              keyboardType: TextInputType.name,
            ),

            // --- Dynamic Fields ---

            // Timed (0): Start/End Time
            if (_tabController.index == 0) ...[
               _buildTimeRow('Başlangıç saati', _startDate, () => _selectDate(true)),
               _buildDivider(),
               _buildTimeRow('Bitiş zamanı', _endDate, () => _selectDate(false)),
            ],

            // Recurring (3): Validity Period Link
            if (_tabController.index == 3) ...[
               InkWell(
                 onTap: _openRecurringSettings,
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Geçerlilik süresi', style: TextStyle(color: Colors.white, fontSize: 16)),
                       Row(
                         children: [
                           Text(
                             _isRecurringConfigured ? 'Ayarlı' : 'Ayarla', 
                             style: TextStyle(color: _isRecurringConfigured ? AppColors.primary : Colors.grey, fontSize: 16)
                           ),
                           const SizedBox(width: 8),
                           const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                         ],
                       )
                     ],
                   ),
                 ),
               ),
            ],

            // --- Common Toggle ---
            const SizedBox(height: 10),
            SwitchListTile(
               contentPadding: EdgeInsets.zero,
               activeColor: AppColors.primary,
               title: const Text('Uzaktan kilit açmaya izin ver', style: TextStyle(color: Colors.white, fontSize: 16)),
               value: _allowRemoteUnlock,
               onChanged: (val) => setState(() => _allowRemoteUnlock = val),
            ),
            
            const SizedBox(height: 20),

            // --- Dynamic Footers ---
            if (_tabController.index == 1) 
              _buildNote('Tek seferlik elektronik anahtar, bir saat için geçerlidir.'),
            
            if (_tabController.index == 2)
              _buildNote('Alıcılar bu uygulama ile kilidi süresiz olarak açabilir.'),
              
            if (_tabController.index == 0 || _tabController.index == 3)
              _buildNote('Davet edilenler, geçerlilik süresi içinde Bluetooth üzerinden veya uzaktan (Gateway varsa) kilidi açabilirler.'),

            const SizedBox(height: 40),

            // Main Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('Gönder', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {},
               child: const Text('Birden fazla elektronik anahtar gönder', style: TextStyle(color: AppColors.primary)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow({
    required String label, 
    required String hint, 
    required TextEditingController controller, 
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF2C2C2C))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4), // Reduced vertical padding as TextField will have its own
        child: Row(
          children: [
             Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
             const SizedBox(width: 16),
             Expanded(
               child: TextField(
                 controller: controller,
                 style: const TextStyle(color: Colors.white),
                 textAlign: TextAlign.right,
                 keyboardType: keyboardType,
                 textInputAction: TextInputAction.next,
                 decoration: InputDecoration(
                   hintText: hint,
                   hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                   border: InputBorder.none,
                   contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Larger hit area
                   isDense: false, // Allow normal height
                 ),
               ),
             ),
             if (icon != null) ...[
               const SizedBox(width: 12),
               Icon(icon, color: AppColors.primary, size: 24),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime date, VoidCallback onTap) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}";
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
             Row(
               children: [
                 Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                 const SizedBox(width: 8),
                 const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
               ],
             )
           ],
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return const Divider(color: Color(0xFF2C2C2C), height: 1);
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}
