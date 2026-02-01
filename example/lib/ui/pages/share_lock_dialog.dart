import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

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

  final Map<int, String> _permissionOptions = {
    1: 'Admin - Tam erişim (açma, kapama, ayarlar)',
    2: 'Normal Kullanıcı - Açma ve kapama',
    3: 'Sınırlı Kullanıcı - Sadece görüntüleme',
  };

  @override
  Widget build(BuildContext context) {
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
                        '${widget.lock['name']} Kilidini Paylaş',
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
                    labelText: 'E-posta veya Telefon Numarası',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: 'ornek@email.com veya +905551234567',
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
                      return 'E-posta veya telefon numarası gerekli';
                    }
                    // Basic email validation
                    if (!value.contains('@') && !value.startsWith('+')) {
                      return 'Geçerli bir e-posta veya telefon numarası girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Permission Selection
                const Text(
                  'Yetki Seviyesi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                RadioGroup<int>(
                  groupValue: _selectedPermission,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPermission = value;
                      });
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        title: Text(
                          _permissionOptions[1]!,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: 1,
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      RadioListTile<int>(
                        title: Text(
                          _permissionOptions[2]!,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: 2,
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      RadioListTile<int>(
                        title: Text(
                          _permissionOptions[3]!,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: 3,
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Date Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: 'Başlangıç Tarihi',
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
                        label: 'Bitiş Tarihi',
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
                    labelText: 'Not (İsteğe bağlı)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: 'Paylaşım hakkında not...',
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
                        child: const Text(
                          'İptal',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
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
                            : const Text(
                                'Paylaş',
                                style: TextStyle(
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
                dialogTheme: const DialogThemeData(
                  backgroundColor: Color(0xFF2A2A2A),
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
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: const Color(0xFF2A2A2A),
                    hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? Colors.blue
                            : Colors.grey[800]!),
                    hourMinuteTextColor: WidgetStateColor.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? Colors.white
                            : Colors.grey),
                    dialHandColor: Colors.blue,
                    dialBackgroundColor: Colors.grey[800],
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
                        : 'Seçilmemiş',
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
    print('🔄 Paylaşım butonuna tıklandı');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validasyonu başarısız');
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen başlangıç ve bitiş tarihlerini seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Form validasyonu başarılı');
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔑 API servisi başlatılıyor...');
      final apiService = ApiService(AuthRepository());
      print('🔑 Access token alınıyor...');
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        print('❌ Access token alınamadı');
        throw Exception('Access token alınamadı');
      }
      print('✅ Access token alındı');

      final originalReceiver = _emailController.text.trim();
      final String emailSmall = originalReceiver.toLowerCase();
      final String sanitized = emailSmall.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final String beforeAt = emailSmall.contains('@') ? emailSmall.split('@')[0] : emailSmall;

      // Denenecek alıcı isimleri listesi
      final List<String> receiversToTry = [
        'fihbg_$sanitized', // 1. Tercih: App Prefix + Temizlenmiş Email
        'fihbg_$beforeAt',  // 2. Tercih: App Prefix + Email başı
        originalReceiver,   // 3. Tercih: Orijinal Email
      ];

      bool shareSuccess = false;
      String? lastError;

      for (String receiver in receiversToTry) {
        if (receiver.isEmpty) continue;
        try {
          print('🚀 Paylaşım deneniyor (Alıcı: $receiver)...');
          await apiService.sendEKey(
            accessToken: accessToken,
            lockId: widget.lock['lockId'].toString(),
            receiverUsername: receiver,
            keyName: 'Key for $originalReceiver',
            startDate: _startDate!,
            endDate: _endDate!,
            keyRight: _selectedPermission,
            remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
            createUser: 2, // Önce var olanı dene, otomatik oluşturma
          );
          shareSuccess = true;
          print('✅ Paylaşım başarılı (Alıcı: $receiver)');
          break; // Başarılıysa döngüden çık
        } catch (e) {
          print('⚠️ $receiver ile paylaşım başarısız: $e');
          lastError = e.toString();
        }
      }

      // Eğer hiçbir varyasyon çalışmadıysa, son bir kez orijinal email ile kullanıcı oluşturarak dene
      if (!shareSuccess) {
        try {
          print('🚀 Son deneme: Orijinal email ile kullanıcı oluşturarak paylaşım...');
          await apiService.sendEKey(
            accessToken: accessToken,
            lockId: widget.lock['lockId'].toString(),
            receiverUsername: originalReceiver,
            keyName: 'Key for $originalReceiver',
            startDate: _startDate!,
            endDate: _endDate!,
            keyRight: _selectedPermission,
            remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
            createUser: 1, // Kullanıcı yoksa oluştur
          );
          shareSuccess = true;
          print('✅ Paylaşım başarılı (Yeni kullanıcı oluşturuldu)');
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (!shareSuccess) {
        throw Exception(lastError ?? 'Paylaşım başarısız');
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.lock['name']} kilidi başarıyla paylaşıldı'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print('❌ Paylaşım hatası: $e');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paylaşım hatası: ${e.toString().replaceAll('Exception: ', '')}'),
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