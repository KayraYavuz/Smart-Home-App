import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'ui/pages/lock_detail_page.dart';
import 'ui/pages/add_device_page.dart';
import 'profile_page.dart';
import 'api_service.dart';
import 'blocs/webhook/webhook_bloc.dart';
import 'blocs/webhook/webhook_state.dart';
import 'blocs/ttlock_webhook/ttlock_webhook_bloc.dart';
import 'blocs/ttlock_webhook/ttlock_webhook_state.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _bottomNavIndex = 0;
  bool _isLoading = false;

  // Start with empty list, will be populated by API data
  List<Map<String, dynamic>> _locks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Seam cihazlarını otomatik olarak yükle
    _fetchAndSetLocks();

    // Webhook bağlantısını başlat (test için simüle edilmiş URL)
    _initializeWebhookConnection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama yeniden açıldığında cihazları yenile
      _fetchAndSetLocks();
    }
  }

          void _initializeWebhookConnection() {
    // Test için simüle edilmiş WebSocket URL (gerçek ortamda backend URL'i kullanılmalı)
    // Not: Gerçek WebSocket bağlantısı için backend servisi gerekli
    // Şimdilik sadece webhook olaylarını simüle edeceğiz

    // Seam webhook olaylarını dinle
    context.read<WebhookBloc>().stream.listen((state) {
      if (state is WebhookConnected && state.latestEvent != null) {
        _handleWebhookEvent(state.latestEvent!);
      }
    });

    // TTLock webhook olaylarını dinle
    context.read<TTLockWebhookBloc>().stream.listen((state) {
      if (state is TTLockWebhookEventReceivedState) {
        _handleTTLockWebhookEvent(state.ttlockEvent);
      }
    });
  }

  void _handleWebhookEvent(SeamWebhookEvent event) {
    // Webhook event'ini işle ve UI'ı güncelle
    final deviceIndex = _locks.indexWhere((lock) => lock['seamDeviceId'] == event.deviceId);

    if (deviceIndex != -1) {
      setState(() {
        switch (event.eventType) {
          case SeamWebhookEventType.lockUnlocked:
            _locks[deviceIndex]['isLocked'] = false;
            _locks[deviceIndex]['status'] = 'Açık';
            break;
          case SeamWebhookEventType.lockLocked:
            _locks[deviceIndex]['isLocked'] = true;
            _locks[deviceIndex]['status'] = 'Kilitli';
            break;
          case SeamWebhookEventType.accessCodeCreated:
            // Erişim kodu oluşturuldu - bildirim göster
            break;
          default:
            break;
        }
      });

      // Kullanıcıya bildirim göster
      _showWebhookNotification(event);
    }
  }

  void _handleTTLockWebhookEvent(TTLockWebhookEvent event) {
    // TTLock webhook event'ini işle ve UI'ı güncelle
    final deviceIndex = _locks.indexWhere((lock) => lock['lockId'] == event.lockId);

    if (deviceIndex != -1) {
      setState(() {
        switch (event.eventType) {
          case TTLockWebhookEventType.lockOpened:
          case TTLockWebhookEventType.lockOpenedFromApp:
          case TTLockWebhookEventType.lockOpenedFromKeypad:
          case TTLockWebhookEventType.lockOpenedFromFingerprint:
          case TTLockWebhookEventType.lockOpenedFromCard:
            _locks[deviceIndex]['isLocked'] = false;
            _locks[deviceIndex]['status'] = 'Açık';
            break;
          case TTLockWebhookEventType.lockClosed:
            _locks[deviceIndex]['isLocked'] = true;
            _locks[deviceIndex]['status'] = 'Kilitli';
            break;
          case TTLockWebhookEventType.lowBattery:
            // Düşük pil uyarısı - pil seviyesini güncelle
            if (event.batteryLevel != null) {
              _locks[deviceIndex]['battery'] = event.batteryLevel!;
            }
            break;
          case TTLockWebhookEventType.lockTampered:
            // Kilit manipülasyon uyarısı
            _locks[deviceIndex]['status'] = 'Güvenlik Uyarısı';
            break;
          default:
            break;
        }
      });

      // Kullanıcıya bildirim göster
      _showTTLockWebhookNotification(event);
    }
  }

  void _showWebhookNotification(SeamWebhookEvent event) {
    String message = '';
    Color backgroundColor = Colors.blue;

    switch (event.eventType) {
      case SeamWebhookEventType.lockUnlocked:
        message = '${_locks.firstWhere((lock) => lock['seamDeviceId'] == event.deviceId)['name']} açıldı';
        backgroundColor = Colors.green;
        break;
      case SeamWebhookEventType.lockLocked:
        message = '${_locks.firstWhere((lock) => lock['seamDeviceId'] == event.deviceId)['name']} kilitlendi';
        backgroundColor = Colors.red;
        break;
      case SeamWebhookEventType.accessCodeCreated:
        message = 'Yeni erişim kodu oluşturuldu';
        backgroundColor = Colors.blue;
        break;
      default:
        message = 'Kilit durumu güncellendi';
        backgroundColor = Colors.grey;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showTTLockWebhookNotification(TTLockWebhookEvent event) {
    String message = '';
    Color backgroundColor = Colors.blue;
    IconData iconData = Icons.lock;

    final lockName = _locks.firstWhere(
      (lock) => lock['lockId'] == event.lockId,
      orElse: () => {'name': 'Bilinmeyen Kilit'}
    )['name'];

    switch (event.eventType) {
      case TTLockWebhookEventType.lockOpened:
        message = '$lockName açıldı';
        backgroundColor = Colors.green;
        iconData = Icons.lock_open;
        break;
      case TTLockWebhookEventType.lockClosed:
        message = '$lockName kilitlendi';
        backgroundColor = Colors.red;
        iconData = Icons.lock;
        break;
      case TTLockWebhookEventType.lockOpenedFromApp:
        message = '$lockName uygulamadan açıldı';
        backgroundColor = Colors.blue;
        iconData = Icons.phone_android;
        break;
      case TTLockWebhookEventType.lockOpenedFromKeypad:
        message = '$lockName tuş takımıyla açıldı';
        backgroundColor = Colors.orange;
        iconData = Icons.dialpad;
        break;
      case TTLockWebhookEventType.lockOpenedFromFingerprint:
        message = '$lockName parmak iziyle açıldı';
        backgroundColor = Colors.purple;
        iconData = Icons.fingerprint;
        break;
      case TTLockWebhookEventType.lockOpenedFromCard:
        message = '$lockName kart ile açıldı';
        backgroundColor = Colors.teal;
        iconData = Icons.credit_card;
        break;
      case TTLockWebhookEventType.lowBattery:
        message = '$lockName düşük pil seviyesi: ${event.batteryLevel ?? 'Bilinmiyor'}%';
        backgroundColor = Colors.amber;
        iconData = Icons.battery_alert;
        break;
      case TTLockWebhookEventType.lockTampered:
        message = '$lockName güvenlik uyarısı!';
        backgroundColor = Colors.red;
        iconData = Icons.warning;
        break;
      default:
        message = '$lockName durumu güncellendi';
        backgroundColor = Colors.grey;
        iconData = Icons.info;
    }

    // Erişim yöntemini de ekle
    if (event.accessMethod != null && event.accessMethod!.isNotEmpty) {
      message += ' (${event.accessMethod})';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(iconData, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _fetchAndSetLocks() async {
            setState(() {
              _isLoading = true;
            });

            try {
              final seamDevices = await ApiService.getSandboxDevices();

              // Seam cihazlarını uygulamamızın formatına dönüştür
              final newLocks = seamDevices.map((device) {
                // Seam API'sinden gelen device verilerini parse et
                final properties = device['properties'] ?? {};

                // Locked durumunu boolean'a çevir (Seam API farklı format gönderebilir)
                final lockedRaw = properties['locked'];
                final isLocked = lockedRaw is bool ? lockedRaw : false;

                // Battery seviyesini int'e çevir (Seam API double gönderebilir)
                final batteryLevelRaw = properties['battery_level'];
                final batteryLevel = batteryLevelRaw is num ? batteryLevelRaw.toInt() : 0;

                return {
                  'name': device['display_name'] ?? 'İsimsiz Kilit',
                  'status': isLocked ? 'Kilitli' : 'Açık',
                  'isLocked': isLocked,
                  'battery': batteryLevel,
                  'lockData': device['device_id'] ?? '',
                  'lockMac': device['device_id'] ?? '',
                  'deviceType': device['device_type'] ?? 'unknown',
                  'seamDeviceId': device['device_id'] ?? '',
                };
              }).toList();

              setState(() {
                _locks = newLocks;
                _isLoading = false;
              });

              print('Seam\'den ${newLocks.length} cihaz yüklendi');
            } catch (e) {
              print('Seam API hatası: $e');
              setState(() {
                _isLoading = false;
              });

              String errorMessage = 'Cihazlar yüklenirken bir hata oluştu';
              if (e.toString().contains('network') || e.toString().contains('connection')) {
                errorMessage = 'İnternet bağlantınızı kontrol edin';
              } else if (e.toString().contains('timeout')) {
                errorMessage = 'Sunucu yanıt vermedi, tekrar deneyin';
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Tekrar Dene',
                      textColor: Colors.white,
                      onPressed: _fetchAndSetLocks,
                    ),
                  ),
                );
              }
            }
          }

  Future<void> _addNewDevice(BuildContext context) async {
    // Navigates to the new AddDevicePage and waits for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDevicePage()),
    );

    // Handle different device addition types
    if (result != null && result is Map<String, dynamic>) {
      // Handle Seam device addition
      if (result['action'] == 'add_seam_devices' && result['devices'] != null) {
        final seamDevices = result['devices'] as List<dynamic>;

        setState(() {
          for (final device in seamDevices) {
            // Check if device already exists
            final existingIndex = _locks.indexWhere(
              (lock) => lock['seamDeviceId'] == device['device_id']
            );

            if (existingIndex == -1) {
              // Add new Seam device
              final properties = device['properties'] ?? {};
              _locks.add({
                'name': device['display_name'] ?? 'Seam Kilit',
                'status': properties['locked'] == true ? 'Kilitli' : 'Açık',
                'isLocked': properties['locked'] ?? false,
                'battery': (properties['battery_level'] as num?)?.toInt() ?? 0,
                'lockData': device['device_id'] ?? '',
                'lockMac': device['device_id'] ?? '',
                'deviceType': device['device_type'] ?? 'unknown',
                'seamDeviceId': device['device_id'] ?? '',
              });
            }
          }
          // Sort devices by name
          _locks.sort((a, b) => a['name'].compareTo(b['name']));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${seamDevices.length} Seam cihazı eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Handle TTLock device addition
      else if (result['action'] == 'ttlock_added' && result['lock'] != null) {
        final ttlockDevice = result['lock'] as Map<String, dynamic>;

        setState(() {
          // Check if device already exists (by lockId or lockData)
          final existingIndex = _locks.indexWhere(
            (lock) => lock['lockId'] == ttlockDevice['lockId'] ||
                     lock['lockData'] == ttlockDevice['lockData']
          );

          if (existingIndex == -1) {
            _locks.add(ttlockDevice);
            // Sort devices by name
            _locks.sort((a, b) => a['name'].compareTo(b['name']));
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TTLock kilidi başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // The body of the Scaffold will now be determined by the selected page
    final List<Widget> _pages = [
      _buildMainContent(context), // Ana sayfa - Cihaz listesi
      ProfilePage(), // Profil sayfası - Ben
    ];

    return ProgressHud(
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            // The body is now one of the pages from the list
            body: SafeArea(
              child: _pages[_bottomNavIndex],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    // This is the content for the first tab (index 0)
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : _locks.isEmpty
                  ? Center(
                      child: Text(
                        'API\'den kilit bulunamadı.',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _locks.length,
                      itemBuilder: (context, index) {
                        return _buildLockListItem(_locks[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tüm Kilitler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row( // Use a Row to hold multiple icons
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.cloud_sync, color: Colors.white),
                  onPressed: _fetchAndSetLocks,
                  tooltip: 'Kilitleri Yenile',
                ),
              ),
              SizedBox(width: 8), // Spacing between icons
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () => _addNewDevice(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockListItem(Map<String, dynamic> lock) {
    final isSeamDevice = lock.containsKey('seamDeviceId');

    return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        color: Color.fromRGBO(30, 30, 30, 0.85), // Dark semi-transparent background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LockDetailPage(
                  lock: lock,
                  seamDeviceId: lock['seamDeviceId'],
                  isSeamDevice: isSeamDevice,
                ),
              ),
            );
          },
          onLongPress: () async {
            final shouldDelete = await _showDeleteConfirmationDialog(lock);
            if (shouldDelete) {
              _removeDevice(lock);
            }
          },
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        lock['isLocked'] ? Icons.lock : Icons.lock_open,
                        color: lock['isLocked'] ? Color(0xFF1E90FF) : Colors.amber,
                        size: 40,
                      ),
                      if (isSeamDevice)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF1E90FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Seam',
                            style: TextStyle(
                              color: Color(0xFF1E90FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lock['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4),
                        Text(
                          lock['status'],
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        if (isSeamDevice && lock['deviceType'] != null)
                          Text(
                            'Tip: ${lock['deviceType']}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Battery and Wi-Fi icons at top right
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Battery icon
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getBatteryIcon(lock['battery'] ?? 0),
                          color: _getBatteryColor(lock['battery'] ?? 0),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${lock['battery'] ?? 0}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Wi-Fi icon
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.wifi,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(Map<String, dynamic> lock) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.redAccent),
              SizedBox(width: 12),
              Text(
                'Cihazı Sil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${lock['name']} cihazını uygulamadan kaldırmak istediğinizden emin misiniz?\n\nBu işlem sadece bu uygulamadan kaldırır, cihaz fiziksel olarak etkilenmez.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Sil',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _removeDevice(Map<String, dynamic> lock) {
    setState(() {
      _locks.removeWhere((device) =>
        device['name'] == lock['name'] &&
        (device['seamDeviceId'] == lock['seamDeviceId'] || device['lockId'] == lock['lockId'])
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${lock['name']} cihazı kaldırıldı'),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: 'Geri Al',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _locks.add(lock);
              // Listeyi yeniden sırala
              _locks.sort((a, b) => a['name'].compareTo(b['name']));
            });
          },
        ),
      ),
    );
  }

  IconData _getBatteryIcon(int battery) {
    if (battery >= 80) return Icons.battery_full;
    if (battery >= 50) return Icons.battery_5_bar;
    if (battery >= 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(int battery) {
    if (battery >= 50) return Colors.green;
    if (battery >= 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() => _bottomNavIndex = index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFF1E90FF),
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(_bottomNavIndex == 0 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _bottomNavIndex == 0
                      ? Color(0xFF1E90FF).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_filled,
                  size: _bottomNavIndex == 0 ? 26 : 22,
                ),
              ),
              label: 'Cihaz',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(_bottomNavIndex == 1 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _bottomNavIndex == 1
                      ? Color(0xFF1E90FF).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _bottomNavIndex == 1 ? Icons.person : Icons.person_outline,
                  size: _bottomNavIndex == 1 ? 26 : 22,
                ),
              ),
              label: 'Ben',
            ),
          ],
        ),
      ),
    );
  }

}