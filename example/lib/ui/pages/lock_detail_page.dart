import 'package:yavuz_lock/fingerprint_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/device/device_bloc.dart';
import 'package:yavuz_lock/blocs/device/device_event.dart';
import 'package:yavuz_lock/blocs/device/device_state.dart';
import 'package:yavuz_lock/logs_page.dart';
import 'package:yavuz_lock/ui/pages/ekey/ekey_list_page.dart';
import 'package:yavuz_lock/ui/pages/lock_settings_page.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/ui/pages/share_lock_dialog.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/config.dart';
import 'package:yavuz_lock/passcode_page.dart';
import 'package:yavuz_lock/card_page.dart';
import 'package:yavuz_lock/face_page.dart';
import 'package:yavuz_lock/ui/pages/feature_pages.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class LockDetailPage extends StatefulWidget {
  final Map<String, dynamic> lock;



  const LockDetailPage({
    super.key,
    required this.lock,
  });

  @override
  _LockDetailPageState createState() => _LockDetailPageState();
}

class _LockDetailPageState extends State<LockDetailPage> with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _isLoadingConnectivity = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _checkConnectivity();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    print('🔄 Connectivity kontrolü başlatılıyor...');
    setState(() {
      _isLoadingConnectivity = true;
    });

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken != null) {
        print('🔑 Access token var, connectivity kontrolü yapılıyor...');
        final isConnected = await apiService.checkDeviceConnectivity(
          accessToken: accessToken,
          lockId: widget.lock['lockId'].toString(),
        );
        print('🔍 Lock detail connectivity sonucu: ${widget.lock['lockId']} -> ${isConnected ? 'ONLINE' : 'OFFLINE'}');
        if (!mounted) return;
        setState(() {
          _isOnline = isConnected;
        });
      } else {
        print('❌ Access token bulunamadı');
        if (!mounted) return;
        setState(() {
          _isOnline = false;
        });
      }
    } catch (e) {
      print('❌ Connectivity check hatası: $e');
      // Bağlantı hatası durumunda offline kabul edelim
      if (!mounted) return;
      setState(() {
        _isOnline = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConnectivity = false;
        });
      }
      print('✅ Connectivity kontrolü tamamlandı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => DeviceBloc(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              // Kilit adı
              Flexible(
                child: Text(
                  widget.lock['name'] ?? 'Yavuz Lock',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16, // Slightly smaller font
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),

              // Connectivity durumu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _isLoadingConnectivity
                      ? Colors.grey.withValues(alpha: 0.2)
                      : (_isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLoadingConnectivity
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isOnline ? Icons.wifi : Icons.wifi_off,
                            color: _isOnline ? Colors.green : Colors.red,
                            size: 14,
                          ),
                    const SizedBox(width: 2),
                    Text(
                      _isLoadingConnectivity ? '...' : (_isOnline ? l10n.online : l10n.offline),
                      style: TextStyle(
                        color: _isLoadingConnectivity
                            ? Colors.grey
                            : (_isOnline ? Colors.green : Colors.red),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Pil seviyesi
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getBatteryColor(widget.lock['battery'] ?? 85).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBatteryIcon(widget.lock['battery'] ?? 85),
                      color: _getBatteryColor(widget.lock['battery'] ?? 85),
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.lock['battery'] ?? 85}%',
                      style: TextStyle(
                        color: _getBatteryColor(widget.lock['battery'] ?? 85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Yetki durumu
              if (widget.lock['shared'] == true)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.sharedLock,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _checkConnectivity,
              tooltip: l10n.checkConnectivity,
            ),
          ],
        ),
        body: BlocConsumer<DeviceBloc, DeviceState>(
          listener: (context, state) {
            if (state is DeviceSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.operationSuccessful)),
              );

              // Ana sayfaya güncellenmiş kilit bilgilerini gönder
              final updatedLock = Map<String, dynamic>.from(widget.lock);
              if (state.newLockState != null) {
                updatedLock['isLocked'] = state.newLockState;
                updatedLock['status'] = state.newLockState! ? l10n.statusLocked : l10n.statusUnlocked;
              }

              // Kısa bir gecikmeden sonra sayfayı kapat
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(context).pop({
                  'action': 'lock_updated',
                  'lock': updatedLock,
                  'device_id': widget.lock['lockId'],
                  'new_state': state.newLockState
                });
              });
            }
            if (state is DeviceFailure) {
              // Bluetooth hata kodlarını çevir
              String errorMessage = state.error;
              
              if (state.error == 'BLUETOOTH_OFF') {
                errorMessage = l10n.bluetoothOffInstructions;
              } else if (state.error == 'LOCK_OUT_OF_RANGE') {
                errorMessage = l10n.lockOutOfRangeInstructions;
              } else if (state.error.startsWith('CONNECTION_FAILED:')) {
                errorMessage = l10n.lockConnectionFailedInstructions;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.operationFailedWithMsg(errorMessage))),
              );
            }
          },
          builder: (context, state) {
            final isLocked = widget.lock['isLocked'] ?? true;
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Ana kilit kontrol alanı
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (isLocked) {
                              context.read<DeviceBloc>().add(UnlockDevice(widget.lock, onlyBluetooth: true));
                            } else {
                              context.read<DeviceBloc>().add(LockDevice(widget.lock, onlyBluetooth: true));
                            }
                          },
                          child: Container(
                            width: 220,
                            height: 220,
                            margin: const EdgeInsets.only(top: 40, bottom: 40), // Add margin for spacing
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  color: _isLoadingConnectivity || state is DeviceLoading
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : (_isOnline
                                          ? AppColors.primary.withValues(alpha: 0.4)
                                          : AppColors.error.withValues(alpha: 0.3)),
                                  blurRadius: 40.0 * (_isLoadingConnectivity || state is DeviceLoading ? _pulseAnimation.value : 1.0),
                                  spreadRadius: 8.0 * (_isLoadingConnectivity || state is DeviceLoading ? _pulseAnimation.value : 1.0),
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: (_isLoadingConnectivity || state is DeviceLoading) ? _pulseAnimation.value : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _isOnline
                                            ? AppColors.primary.withValues(alpha: 0.6)
                                            : AppColors.error.withValues(alpha: 0.5),
                                        width: 3,
                                      ),
                                      gradient: RadialGradient(
                                        colors: [
                                          _isOnline
                                              ? AppColors.primary.withValues(alpha: 0.15)
                                              : AppColors.error.withValues(alpha: 0.15),
                                          _isOnline
                                              ? AppColors.primary.withValues(alpha: 0.05)
                                              : AppColors.error.withValues(alpha: 0.05),
                                        ],
                                      ),
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: Center(
                                child: state is DeviceLoading || _isLoadingConnectivity
                                    ? const CircularProgressIndicator(
                                        color: AppColors.primary,
                                      )
                                    : Icon(
                                        isLocked ? Icons.lock : Icons.lock_open,
                                        color: AppColors.primary,
                                        size: 80,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      
                      // Küçük Kilit Butonu (Uzaktan Erişim)
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E1E1E), // Dark background
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _remoteUnlock(context),
                                icon: const Icon(Icons.wifi_tethering, color: Colors.blue, size: 28),
                                tooltip: l10n.remoteUnlock,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.remoteAccess,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Alt kısım - Grid menü
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildGridMenuItem(
                              context,
                              icon: Icons.vpn_key,
                              label: l10n.electronicKeysMenu,
                              onTap: () => _showEKeys(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.password,
                              label: l10n.passcodesMenu,
                              onTap: () => _showPasswords(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.credit_card,
                              label: l10n.cardsMenu,
                              onTap: () => _showCards(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.fingerprint,
                              label: l10n.fingerprintMenu,
                              onTap: () => _showFingerprint(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.face,
                              label: l10n.facesMenu,
                              onTap: () => _showFaces(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.wifi_tethering,
                              label: l10n.remoteControlMenu,
                              onTap: () => _showRemoteControl(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.keyboard_alt,
                              label: l10n.wirelessKeypadMenu,
                              onTap: () => _showWirelessKeypad(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.sensor_door,
                              label: l10n.doorSensorMenu,
                              onTap: () => _showDoorSensor(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.qr_code,
                              label: l10n.qrCodeMenu,
                              onTap: () => _showQrCode(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.history,
                              label: l10n.recordsMenu,
                              onTap: () => _showRecords(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.share,
                              label: l10n.shareMenu,
                              onTap: () => _showShareLockDialog(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.settings,
                              label: l10n.settingsMenu,
                              onTap: () => _showSettings(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }





  Widget _buildGridMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LockSettingsPage(lock: widget.lock),
      ),
    ).then((val) {
      if (val == 'deleted') {
         Navigator.pop(context, 'deleted');
      }
    });
  }


  void _remoteUnlock(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final authRepository = context.read<AuthRepository>();
      final apiService = ApiService(authRepository);
      await apiService.getAccessToken();
      
      final accessToken = apiService.accessToken;
      if (accessToken == null) throw Exception('Erişim anahtarı alınamadı');

      // TTLock API ile uzaktan açma komutunu gönder
      print('🚀 TTLock /v3/lock/unlock API çağrısı başlatılıyor...');
      await apiService.sendRemoteUnlock(
        lockId: widget.lock['lockId'].toString(),
      );

      if (!mounted) return;

      print('✅ Uzaktan açma komutu başarıyla gönderildi');

      // Ana sayfaya güncelleme gönder
      Navigator.of(context).pop({
        'action': 'lock_updated',
        'lock': widget.lock,
        'device_id': widget.lock['lockId'],
        'new_state': false, // Uzaktan açıldı
      });

    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = l10n.remoteControlError;
      if (e.toString().contains('Gateway') || e.toString().contains('gateway')) {
         errorMessage = l10n.gatewayConnectionError;
      } else {
         errorMessage = l10n.errorWithMsg(e.toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showEKeys(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EKeyListPage(lock: widget.lock)),
    );
  }

  void _showPasswords(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final lockIdString = widget.lock['lockId']?.toString();
      if (lockIdString == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kilit ID bulunamadı.')),
        );
        return;
      }
      final lockId = int.tryParse(lockIdString);
      if (lockId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz Kilit ID formatı.')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasscodePage(
            lockId: lockId,
            clientId: ApiConfig.clientId,
            accessToken: authState.accessToken,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreleri görmek için giriş yapmalısınız.')),
      );
    }
  }

  void _showCards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardPage(lockId: widget.lock['lockId'].toString()),
      ),
    );
  }

  void _showFingerprint(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FingerprintPage(
          lockId: int.parse(widget.lock['lockId'].toString()),
          lockData: widget.lock['lockData'],
        ),
      ),
    );
  }

  void _showFaces(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacePage(
          lockId: int.parse(widget.lock['lockId'].toString()),
        ),
      ),
    );
  }

  void _showRemoteControl(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RemoteListPage(lockId: int.parse(widget.lock['lockId'].toString())),
        ),
    );
  }

  void _showWirelessKeypad(BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WirelessKeypadPage(lockId: int.parse(widget.lock['lockId'].toString())),
        ),
    );
  }

  void _showDoorSensor(BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DoorSensorPage(lockId: int.parse(widget.lock['lockId'].toString())),
        ),
    );
  }

  void _showQrCode(BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => QrCodePage(lockId: int.parse(widget.lock['lockId'].toString())),
        ),
    );
  }

  void _showRecords(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogsPage(
          lockId: widget.lock['lockId'].toString(),
          lockName: widget.lock['name'],
          lockData: widget.lock['lockData'],
        ),
      ),
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery >= 50) return Colors.green;
    if (battery >= 20) return Colors.orange;
    return Colors.red;
  }

  void _showShareLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ShareLockDialog(lock: widget.lock),
    );
  }

  IconData _getBatteryIcon(int battery) {
    if (battery >= 80) return Icons.battery_full;
    if (battery >= 60) return Icons.battery_6_bar;
    if (battery >= 40) return Icons.battery_5_bar;
    if (battery >= 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }
}