 import 'dart:ui';
 import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmprogresshud/progresshud.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'ui/pages/lock_detail_page.dart';
import 'ui/pages/add_device_page.dart';
import 'ui/pages/gateways_page.dart';
import 'profile_page.dart';
import 'api_service.dart';
import 'blocs/ttlock_webhook/ttlock_webhook_bloc.dart';
import 'blocs/ttlock_webhook/ttlock_webhook_event.dart';
import 'blocs/ttlock_webhook/ttlock_webhook_state.dart';
import 'repositories/auth_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _bottomNavIndex = 0;
  bool _isLoading = false;

  // Start with empty list, will be populated by API data
  List<Map<String, dynamic>> _locks = [];
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Önce önbelleği yükle, sonra güncel veriyi çek
    _loadCachedLocks().then((_) {
      _fetchAndSetLocks();
    });

    // Webhook bağlantısını başlat (test için simüle edilmiş URL)
    _initializeWebhookConnection();
    _startRealtimeSync();
  }

  Future<void> _loadCachedLocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedLocksString = prefs.getString('cached_locks');
      if (cachedLocksString != null) {
        final List<dynamic> decoded = json.decode(cachedLocksString);
        if (mounted) {
          setState(() {
            _locks = decoded.cast<Map<String, dynamic>>();
          });
        }
        print('✅ Önbellekten ${_locks.length} kilit yüklendi.');
      }
    } catch (e) {
      print('❌ Önbellek yükleme hatası: $e');
    }
  }

  Future<void> _cacheLocks(List<Map<String, dynamic>> locks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(locks);
      await prefs.setString('cached_locks', encoded);
      print('💾 Kilitler önbelleğe kaydedildi.');
    } catch (e) {
      print('❌ Önbellek kaydetme hatası: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama yeniden açıldığında cihazları yenile
      _fetchAndSetLocks();
    }
  }

  void _startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _refreshSharedLocksStatus();
    });
  }

  Future<void> _refreshSharedLocksStatus() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final apiService = ApiService(context.read<AuthRepository>());
      final allKeys = await apiService.getKeyList();
      final Map<String, Map<String, dynamic>> latestByLockId = {
        for (final k in allKeys) (k['lockId']?.toString() ?? ''): k
      };
      bool changed = false;
      for (int i = 0; i < _locks.length; i++) {
        final lockId = _locks[i]['lockId']?.toString() ?? '';
        if (lockId.isEmpty) continue;
        final latest = latestByLockId[lockId];
        if (latest == null) continue;
        final keyState = latest['keyState'] ?? 0;
        final isLocked = keyState == 0 || keyState == 2;
        final status = isLocked ? l10n.statusLocked : l10n.statusUnlocked;
        final battery = latest['electricQuantity'] ?? latest['battery'] ?? _locks[i]['battery'] ?? 0;
        if (_locks[i]['isLocked'] != isLocked || _locks[i]['status'] != status || _locks[i]['battery'] != battery) {
          _locks[i]['isLocked'] = isLocked;
          _locks[i]['status'] = status;
          _locks[i]['battery'] = battery;
          changed = true;
        }
      }
      if (changed && mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

          void _initializeWebhookConnection() {
    // TTLock webhook olaylarını dinle (şimdilik sadece TTLock)
    // Not: Webhook server çalışmadığı için şu anda sadece loglama yapılacak
    context.read<TTLockWebhookBloc>().stream.listen((state) {
      if (state is TTLockWebhookEventReceivedState) {
        _handleTTLockWebhookEvent(state.ttlockEvent);
      }
    });
  }


  void _handleTTLockWebhookEvent(TTLockWebhookEventData event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    // TTLock webhook event'ini işle ve UI'ı güncelle
    final deviceIndex = _locks.indexWhere((lock) => lock['lockId'] == event.lockId);

    if (deviceIndex != -1) {
      setState(() {
        switch (event.eventType) {
          case '1': // lockOpened
          case '3': // lockOpenedFromApp
          case '4': // lockOpenedFromKeypad
          case '5': // lockOpenedFromFingerprint
          case '6': // lockOpenedFromCard
            _locks[deviceIndex]['isLocked'] = false;
            _locks[deviceIndex]['status'] = l10n.statusUnlocked;
            break;
          case '2': // lockClosed
            _locks[deviceIndex]['isLocked'] = true;
            _locks[deviceIndex]['status'] = l10n.statusLocked;
            break;
          case '7': // lowBattery
            // Düşük pil uyarısı - pil seviyesini güncelle
            if (event.batteryLevel != null) {
              _locks[deviceIndex]['battery'] = event.batteryLevel!;
            }
            break;
          case '8': // lockTampered
            // Kilit manipülasyon uyarısı
            _locks[deviceIndex]['status'] = l10n.statusSecurityWarning;
            break;
          default:
            break;
        }
      });

      // Kullanıcıya bildirim göster
      _showTTLockWebhookNotification(event);
    }
  }


  void _showTTLockWebhookNotification(TTLockWebhookEventData event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    String message = '';
    Color backgroundColor = Colors.blue;
    IconData iconData = Icons.lock;

    final lockName = _locks.firstWhere(
      (lock) => lock['lockId'] == event.lockId,
      orElse: () => {'name': l10n.unknownLock}
    )['name'];

    switch (event.eventType) {
      case '1': // lockOpened
        message = l10n.lockOpened(lockName);
        backgroundColor = Colors.green;
        iconData = Icons.lock_open;
        break;
      case '2': // lockClosed
        message = l10n.lockClosed(lockName);
        backgroundColor = Colors.red;
        iconData = Icons.lock;
        break;
      case '3': // lockOpenedFromApp
        message = l10n.lockOpenedApp(lockName);
        backgroundColor = Colors.blue;
        iconData = Icons.phone_android;
        break;
      case '4': // lockOpenedFromKeypad
        message = l10n.lockOpenedKeypad(lockName);
        backgroundColor = Colors.orange;
        iconData = Icons.dialpad;
        break;
      case '5': // lockOpenedFromFingerprint
        message = l10n.lockOpenedFingerprint(lockName);
        backgroundColor = Colors.purple;
        iconData = Icons.fingerprint;
        break;
      case '6': // lockOpenedFromCard
        message = l10n.lockOpenedCard(lockName);
        backgroundColor = Colors.teal;
        iconData = Icons.credit_card;
        break;
      case '7': // lowBattery
        message = l10n.lowBatteryWarning(lockName);
        backgroundColor = Colors.amber;
        iconData = Icons.battery_alert;
        break;
      case '8': // lockTampered
        message = l10n.lockTamperedWarning(lockName);
        backgroundColor = Colors.red;
        iconData = Icons.warning;
        break;
      default:
        message = l10n.lockStatusUpdated(lockName);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

            try {
              print('🔄 TTLock key listesi çekme işlemi başladı...');

              // TTLock key listesini çek (hem kendi hem paylaşılan kilitler)
              final apiService = ApiService(context.read<AuthRepository>());
              final allKeys = await apiService.getKeyList();

              // Kilitleri kendi ve paylaşılan olarak ayır
              final ttlockDevices = allKeys.where((key) => key['shared'] == false).toList();
              final sharedTTLockDevices = allKeys.where((key) => key['shared'] == true).toList();

              print('📊 TTLock Key List API Sonuçları:');
              print('  TTLock kendi kilitleri: ${ttlockDevices.length}');
              print('  TTLock paylaşılan kilitleri: ${sharedTTLockDevices.length}');
              print('  Toplam kilit: ${allKeys.length}');

              // Debug: Tüm kilitleri detaylı logla
              if (allKeys.isNotEmpty) {
                print('🔍 Tüm TTLock Kilit Detayları:');
                for (var i = 0; i < allKeys.length; i++) {
                  final lock = allKeys[i];
                  final sharedText = lock['shared'] ? '[PAYLAŞILAN]' : '[KENDİ]';
                  print('  ${i + 1}. $sharedText ID: ${lock['lockId']}, KeyID: ${lock['keyId']}, İsim: ${lock['name']}');
                }
              } else {
                print('⚠️  TTLock hesabında hiç kilit bulunamadı!');
                print('   Kilitleriniz paylaşıldığından emin olun.');
              }

              // Tüm kilitleri birleştir
              final allLocks = <Map<String, dynamic>>[];

              // TTLock kendi cihazlarını ekle
              for (final lock in ttlockDevices) {
                final lockId = lock['lockId']?.toString() ?? '';
                final lockAlias = lock['name'] ?? l10n.defaultLockName; // ApiService'den gelen name'i kullan
                final keyState = lock['keyState'] ?? 0;
                final electricQuantity = lock['battery'] ?? 0; // ApiService'den gelen battery'i kullan

                final isLocked = keyState == 0 || keyState == 2; 
                final status = isLocked ? l10n.statusLocked : l10n.statusUnlocked;

                print('🔋 Kilit $lockId: keyState=$keyState, battery=$electricQuantity');
                print('🏷️  Kilit adı: $lockAlias');

                allLocks.add({
                  'name': lockAlias,
                  'status': status,
                  'isLocked': isLocked,
                  'battery': electricQuantity > 0 ? electricQuantity : 85,
                  'lockData': lock['lockData'] ?? '',
                  'lockMac': lock['lockMac'] ?? '',
                  'lockId': lockId,
                  'deviceType': 'ttlock',
                  'source': 'ttlock',
                  'shared': false,
                });
              }

              // TTLock paylaşılmış cihazlarını ekle
              for (final lock in sharedTTLockDevices) {
                final lockId = lock['lockId']?.toString() ?? '';
                final lockAlias = lock['name'] ?? l10n.defaultSharedLockName; // ApiService'den gelen name'i kullan
                final keyState = lock['keyState'] ?? 0;
                final electricQuantity = lock['battery'] ?? 0; // ApiService'den gelen battery'i kullan

                final isLocked = keyState == 0 || keyState == 2; 
                final status = isLocked ? l10n.statusLocked : l10n.statusUnlocked;

                print('🔋 Paylaşılan kilit $lockId: keyState=$keyState, battery=$electricQuantity');

                allLocks.add({
                  'name': lockAlias,
                  'status': status,
                  'isLocked': isLocked,
                  'battery': electricQuantity > 0 ? electricQuantity : 85,
                  'lockData': lock['lockData'] ?? '',
                  'lockMac': lock['lockMac'] ?? '',
                  'lockId': lockId,
                  'deviceType': 'ttlock',
                  'source': 'ttlock_shared',
                  'shared': true,
                });
              }

              if (!mounted) return;
              setState(() {
                _locks = allLocks;
                _isLoading = false;
              });

              // Kilitleri önbelleğe kaydet
              _cacheLocks(allLocks);

              // Bildirimler için kilit konularına (topic) abone ol
              _subscribeToLockTopics(allLocks);

              print('✅ Toplam ${allLocks.length} TTLock cihazı yüklendi');
              print('  - ${ttlockDevices.length} TTLock kendi kilidi');
              print('  - ${sharedTTLockDevices.length} TTLock paylaşılmış kilidi');

              if (allLocks.isEmpty) {
                print('⚠️  UYARI: TTLock hesabınızda hiç kilit bulunamadı!');
                print('   TTLock hesabınızı kontrol edin: https://lock.ttlock.com');
              }
            } catch (e) {
              print('❌ Kilit listesi çekme hatası: $e');
              print('   Hata detayları: ${e.toString()}');

              // Token hatası mı kontrol et
              if (e.toString().contains('access_token') || e.toString().contains('token')) {
                print('   🔑 Öneri: TTLock hesabınıza tekrar giriş yapın');
              }

              setState(() {
      _isLoading = false;
    });

              String errorMessage = l10n.errorDevicesLoading;
              if (e.toString().contains('network') || e.toString().contains('connection')) {
                errorMessage = l10n.errorInternetConnection;
              } else if (e.toString().contains('timeout')) {
                errorMessage = l10n.errorServerTimeout;
              } else {
                errorMessage = '$errorMessage: ${e.toString()}';
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: l10n.retry,
                      textColor: Colors.white,
                      onPressed: _fetchAndSetLocks,
                    ),
                  ),
                );
              }
            }
          }

  Future<void> _addNewDevice(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Navigates to the new AddDevicePage and waits for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDevicePage()),
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
                'name': device['display_name'] ?? l10n.seamLockDefaultName,
                'status': properties['locked'] == true ? l10n.statusLocked : l10n.statusUnlocked,
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

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.seamDevicesAdded(seamDevices.length)),
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

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.lockAddedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // The body of the Scaffold will now be determined by the selected page
    final List<Widget> pages = [
      _buildMainContent(context), // Ana sayfa - Cihaz listesi
      const ProfilePage(), // Profil sayfası - Ben
    ];

    return ProgressHud(
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            // The body is now one of the pages from the list
            body: SafeArea(
              child: pages[_bottomNavIndex],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
            // Debug FAB removed for production
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // This is the content for the first tab (index 0)
    return Column(
      children: [
        _buildHeader(context),
        if (_isLoading && _locks.isNotEmpty)
           const LinearProgressIndicator(minHeight: 2, color: Color(0xFF1E90FF), backgroundColor: Colors.transparent),
        Expanded(
          child: _isLoading && _locks.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _locks.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noLocksFound,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _locks.length,
                      itemBuilder: (context, index) {
                        return _buildLockListItem(_locks[index], context);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.allLocks,
            style: const TextStyle(
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
                  icon: const Icon(Icons.cloud_sync, color: Colors.white),
                  onPressed: _fetchAndSetLocks,
                  tooltip: l10n.refreshLocks,
                ),
              ),
              const SizedBox(width: 8), // Spacing between icons
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.router, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GatewaysPage()),
                    );
                  },
                  tooltip: l10n.gateways,
                ),
              ),
              const SizedBox(width: 8), // Spacing between icons
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _addNewDevice(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockListItem(Map<String, dynamic> lock, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTTLockDevice = lock['source'] == 'ttlock';
    final isSharedTTLockDevice = lock['source'] == 'ttlock_shared';

    // Debug: Lock verilerini logla
    print('🔍 Building lock item: ${lock['name']} (ID: ${lock['lockId']})');
    print('   Source: ${lock['source']}, Shared: ${lock['shared']}');
    print('   All keys: ${lock.keys.join(', ')}');

    String statusText = '';
    if (lock['status'] == l10n.statusSecurityWarning) {
      statusText = l10n.securityWarning;
    } else {
      statusText = lock['isLocked'] == true ? l10n.locked : l10n.unlocked;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: const Color.fromRGBO(30, 30, 30, 0.85), // Dark semi-transparent background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LockDetailPage(
                  lock: lock,
                ),
              ),
            );

            // Lock detail sayfasından dönen sonucu işle
            if (result != null && result is Map<String, dynamic>) {
              if (result['action'] == 'lock_updated') {
                final updatedLock = Map<String, dynamic>.from(lock);
                final deviceId = result['device_id'];
                final newState = result['new_state'] as bool?;

                // Listede bu kilidi bul ve güncelle
                setState(() {
                  final index = _locks.indexWhere((lock) =>
                    (lock['seamDeviceId'] == deviceId) ||
                    (lock['lockId'] == deviceId) ||
                    (lock['lockData'] == deviceId)
                  );

                  if (index != -1) {
                    // Sadece durumu güncelle, diğer bilgileri koru
                    if (newState != null) {
                      _locks[index]['isLocked'] = newState;
                      _locks[index]['status'] = newState ? l10n.statusLocked : l10n.statusUnlocked;
                    }
                  }
                });

                if (!mounted) return;
                // Başarılı işlem için bildirim göster
                if (newState != null) {
                  final lockName = updatedLock['name'] ?? l10n.unknownLock;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$lockName ${newState ? l10n.locked.toLowerCase() : l10n.unlocked.toLowerCase()}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            }
          },
          onLongPress: () async {
            if (lock['shared'] == true) {
              // Paylaşılan kilit için paylaşımı iptal etme seçeneği
              final action = await _showSharedLockOptionsDialog(context, lock);
              if (action == 'cancel_share') {
                await _cancelLockShare(lock);
              }
            } else {
              // Kendi kilidi için silme seçeneği
              final shouldDelete = await _showDeleteConfirmationDialog(lock);
              if (shouldDelete) {
                _removeDevice(lock);
              }
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
                    color: lock['isLocked'] ? const Color(0xFF1E90FF) : Colors.amber,
                    size: 40,
                        ),
                      if (isTTLockDevice)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(76, 175, 80, 0.2), // Colors.green with 0.2 opacity
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color.fromRGBO(76, 175, 80, 0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, color: Colors.green, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                l10n.defaultLockName,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isSharedTTLockDevice)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 152, 0, 0.2), // Colors.orange with 0.2 opacity
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color.fromRGBO(255, 152, 0, 0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.share, color: Colors.orange, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                l10n.sharedLock,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        if (lock['deviceType'] != null)
                          Text(
                            l10n.deviceTypeLabel(lock['deviceType']),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Battery at bottom right
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.3),
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
                    const SizedBox(width: 4),
                    Text(
                      '${lock['battery'] ?? 0}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Wi-Fi icon at top right
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.wifi,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showSharedLockOptionsDialog(BuildContext context, Map<String, dynamic> lock) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.share, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                l10n.sharedLock,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${lock['name']} ${l10n.sharedWithYou}\n\n${l10n.whatDoYouWantToDo}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel_share'),
              child: Text(
                l10n.cancelShare,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelLockShare(Map<String, dynamic> lock) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // TTLock API ile paylaşımı iptal et
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('Access token not available');
      }

      // Paylaşımı iptal etmek için e-key'i sil
      await apiService.deleteEKey(
        accessToken: accessToken,
        keyId: lock['keyId'].toString(),
      );

      // Listeden kaldır
      setState(() {
        _locks.removeWhere((device) =>
          device['lockId'] == lock['lockId'] &&
          device['source'] == 'ttlock_shared'
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lock['name']} ${l10n.shareCancelled}'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shareCancelError(e.toString())), // Error message often technical, keeping as is or generic
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  Future<bool> _showDeleteConfirmationDialog(Map<String, dynamic> lock) async {
    final l10n = AppLocalizations.of(context)!;
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
              const Icon(Icons.warning, color: Colors.redAccent),
              const SizedBox(width: 12),
              Text(
                l10n.deleteDevice,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${lock['name']} ${l10n.deleteDeviceConfirmation}\n\n${l10n.deleteDeviceDisclaimer}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _removeDevice(Map<String, dynamic> lock) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _locks.removeWhere((device) =>
        device['name'] == lock['name'] &&
        (device['seamDeviceId'] == lock['seamDeviceId'] || device['lockId'] == lock['lockId'])
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${lock['name']} ${l10n.deviceRemoved}'),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: l10n.undo,
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

  // Her kilit için FCM topic aboneliği yap
  void _subscribeToLockTopics(List<Map<String, dynamic>> locks) {
    for (var lock in locks) {
      final lockId = lock['lockId']?.toString();
      if (lockId != null && lockId.isNotEmpty) {
        FirebaseMessaging.instance.subscribeToTopic('lock_$lockId');
        print('🔔 Subscribed to topic: lock_$lockId');
      }
    }
  }

  // Unused debug method removed

  Widget _buildBottomNavigationBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: _bottomNavIndex,
            onTap: (index) {
              setState(() => _bottomNavIndex = index);
            },
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            elevation: 0,
            selectedItemColor: const Color(0xFF1E90FF),
            unselectedItemColor: Colors.grey[500],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(_bottomNavIndex == 0 ? 8 : 6),
                  decoration: BoxDecoration(
                    color: _bottomNavIndex == 0
                        ? const Color(0xFF1E90FF).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _bottomNavIndex == 0 ? Icons.lock : Icons.lock_outline,
                    size: _bottomNavIndex == 0 ? 26 : 22,
                  ),
                ),
                label: l10n.devices,
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(_bottomNavIndex == 1 ? 8 : 6),
                  decoration: BoxDecoration(
                    color: _bottomNavIndex == 1
                        ? const Color(0xFF1E90FF).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _bottomNavIndex == 1 ? Icons.person : Icons.person_outline,
                    size: _bottomNavIndex == 1 ? 26 : 22,
                  ),
                ),
                label: l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
