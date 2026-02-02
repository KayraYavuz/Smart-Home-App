import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:url_launcher/url_launcher.dart'; // Email/SMS launch
import 'package:yavuz_lock/l10n/app_localizations.dart';
import '../../theme.dart';
import '../../../api_service.dart';
import '../../../repositories/auth_repository.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'recurring_period_page.dart';  // Import the new page

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

  List<String> _getTabs(AppLocalizations l10n) => [l10n.tabTimed, l10n.tabOneTime, l10n.tabPermanent, l10n.tabRecurring];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final l10n = AppLocalizations.of(context)!;
    final receiver = _receiverController.text.trim();
    if (receiver.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterReceiver)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthBloc>().state;
      String? token;
      if (authState is Authenticated) {
        token = authState.accessToken;
      }

      if (token == null) throw Exception(l10n.tokenNotFound);

      final apiService = ApiService(AuthRepository());
      
      // Prepare parameters based on tab
      int? finalStart;
      int? finalEnd;
      List<Map<String, dynamic>>? cyclicConfig;

      if (_tabController.index == 0) {
        // Timed
        finalStart = _startDate.millisecondsSinceEpoch;
        finalEnd = _endDate.millisecondsSinceEpoch;
      } else if (_tabController.index == 3) {
        // Recurring
        finalStart = _recStartDate.millisecondsSinceEpoch;
        finalEnd = _recEndDate.millisecondsSinceEpoch;
        
        cyclicConfig = [
          {
            "startTime": _recStartTime.hour * 60 + _recStartTime.minute,
            "endTime": _recEndTime.hour * 60 + _recEndTime.minute,
            "dayData": _recDays,
          }
        ];
      }

      final result = await apiService.sendEKey(
        accessToken: token,
        lockId: widget.lock['lockId'].toString(),
        receiverUsername: receiver,
        keyName: _nameController.text.isEmpty ? receiver : _nameController.text,
        startDate: DateTime.fromMillisecondsSinceEpoch(finalStart ?? 0),
        endDate: DateTime.fromMillisecondsSinceEpoch(finalEnd ?? 0),
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
            print("Link retry ${retryCount + 1} failed: $e");
            retryCount++;
            
            // If it's the last try, log the error but don't stop the flow
            if (retryCount >= maxRetries) {
               if (e.toString().contains('20002') || e.toString().contains('Not lock admin')) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminOnlyLinkWarning), backgroundColor: Colors.orange));
               }
            }
          }
        }
      }
      
      // Always show success dialog if sendEKey worked, even if link failed
      if (mounted) {
        _showSuccessDialog(unlockLink, receiver, l10n);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString())), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String? link, String receiver, AppLocalizations l10n) {
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
            Text(l10n.sentSuccessfully, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.keySentToReceiver, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            if (link != null) ...[
               const SizedBox(height: 20),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.black,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.grey.withOpacity(0.3)),
                 ),
                 child: Column(
                   children: [
                     Text(l10n.shareableLink, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
                      },
                      tooltip: l10n.copy,
                    ),
                    // Email
                    if (receiver.contains('@'))
                      IconButton(
                        icon: const Icon(Icons.email, color: AppColors.primary),
                        onPressed: () => _launchEmail(receiver, link),
                        tooltip: l10n.sendViaEmail,
                      )
                    else 
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.green),
                        onPressed: () => _launchSMS(receiver, link),
                        tooltip: l10n.sendViaSMS,
                      ),
                 ],
               )
            ] else ...[
               const SizedBox(height: 20),
               Text(
                 l10n.sendKeySuccessNoLink,
                 style: const TextStyle(color: Colors.orange, fontSize: 13),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 12),
                if (receiver.contains('@'))
                  TextButton.icon(
                    icon: const Icon(Icons.email, color: AppColors.primary),
                    onPressed: () => _launchEmail(receiver, null),
                    label: Text(l10n.sendAppDownloadLink),
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
                child: Text(l10n.ok, style: const TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email, String? link) async {
    final l10n = AppLocalizations.of(context)!;
    final String body = link != null 
        ? l10n.shareMessageWithLink(link)
        : l10n.shareMessageNoLink;
        
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': l10n.keyAccessSubject,
        'body': body,
      },
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch email';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.emailAppNotFound)));
    }
  }

  Future<void> _launchSMS(String phoneNumber, String? link) async {
    final l10n = AppLocalizations.of(context)!;
    final String body = link != null 
        ? l10n.shareMessageWithLink(link)
        : l10n.shareMessageNoLink;
    
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.smsAppNotFound)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sendKey),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _getTabs(l10n).map((t) => Tab(text: t)).toList(),
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
              label: l10n.receiver, 
              hint: l10n.receiverHint, 
              controller: _receiverController,
              icon: Icons.contacts,
              keyboardType: TextInputType.emailAddress,
            ),
            
             // Name
            _buildInputRow(
              label: l10n.nameLabel, 
              hint: l10n.enterHere, 
              controller: _nameController,
              keyboardType: TextInputType.name,
            ),

            // --- Dynamic Fields ---

            // Timed (0): Start/End Time
            if (_tabController.index == 0) ...[
               _buildTimeRow(l10n.startDate, _startDate, () => _selectDate(true)),
               _buildDivider(),
               _buildTimeRow(l10n.endDate, _endDate, () => _selectDate(false)),
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
                       Text(l10n.validityPeriod, style: const TextStyle(color: Colors.white, fontSize: 16)),
                       Row(
                         children: [
                           Text(
                             _isRecurringConfigured ? l10n.configured : l10n.set, 
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
                title: Text(l10n.allowRemoteUnlock, style: const TextStyle(color: Colors.white, fontSize: 16)),
                value: _allowRemoteUnlock,
                onChanged: (val) => setState(() => _allowRemoteUnlock = val),
             ),
            
            const SizedBox(height: 20),

            // --- Dynamic Footers ---
            if (_tabController.index == 1) 
              _buildNote(l10n.oneTimeKeyNote),
            
            if (_tabController.index == 2)
              _buildNote(l10n.permanentKeyNote),
              
            if (_tabController.index == 0 || _tabController.index == 3)
              _buildNote(l10n.timedKeyNote),

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
                   : Text(l10n.send, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 60), // Extra padding for bottom navigation area

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
