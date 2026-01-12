import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/device/device_bloc.dart';
import 'package:yavuz_lock/blocs/device/device_event.dart';
import 'package:yavuz_lock/blocs/device/device_state.dart';
import 'package:yavuz_lock/logs_page.dart';
import 'package:yavuz_lock/ui/pages/lock_settings_page.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/ui/pages/share_lock_dialog.dart';
import 'package:yavuz_lock/ui/pages/gateway_management_dialog.dart';
import 'package:yavuz_lock/ui/pages/ekey_detail_page.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/config.dart';
import 'package:yavuz_lock/passcode_page.dart';
import 'package:yavuz_lock/card_page.dart';

class LockDetailPage extends StatefulWidget {
  final Map<String, dynamic> lock;


  const LockDetailPage({
    Key? key,
    required this.lock,
  }) : super(key: key);

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
        setState(() {
          _isOnline = isConnected;
        });
      } else {
        print('❌ Access token bulunamadı');
        setState(() {
          _isOnline = false;
        });
      }
    } catch (e) {
      print('❌ Connectivity check hatası: $e');
      // Bağlantı hatası durumunda offline kabul edelim
      setState(() {
        _isOnline = false;
      });
    } finally {
      setState(() {
        _isLoadingConnectivity = false;
      });
      print('✅ Connectivity kontrolü tamamlandı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceBloc(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              // Kilit adı
              Expanded(
                child: Text(
                  widget.lock['name'] ?? 'TTLock Kilidi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),

              // Connectivity durumu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _isLoadingConnectivity
                      ? Colors.grey.withValues(alpha: 0.2)
                      : (_isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
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
                      _isLoadingConnectivity ? '...' : (_isOnline ? 'Online' : 'Offline'),
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
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getBatteryColor(widget.lock['battery'] ?? 85).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
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
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Paylaşılan',
                    style: TextStyle(
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
              tooltip: 'Bağlantıyı Kontrol Et',
            ),
          ],
        ),
        body: BlocConsumer<DeviceBloc, DeviceState>(
          listener: (context, state) {
            if (state is DeviceSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('İşlem başarılı')),
              );

              // Ana sayfaya güncellenmiş kilit bilgilerini gönder
              final updatedLock = Map<String, dynamic>.from(widget.lock);
              if (state.newLockState != null) {
                updatedLock['isLocked'] = state.newLockState;
                updatedLock['status'] = state.newLockState! ? 'Kilitli' : 'Açık';
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('İşlem başarısız: ${state.error}')),
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
                              context.read<DeviceBloc>().add(UnlockDevice(widget.lock));
                            } else {
                              context.read<DeviceBloc>().add(LockDevice(widget.lock));
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
                                return Container(
                                  transform: Matrix4.identity()..scale(
                                    (_isLoadingConnectivity || state is DeviceLoading) ? _pulseAnimation.value : 1.0
                                  ),
                                  transformAlignment: Alignment.center,
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
                              label: 'Elektronik\nAnahtarlar',
                              onTap: () => _showEKeys(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.password,
                              label: 'Şifreler',
                              onTap: () => _showPasswords(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.credit_card,
                              label: 'Kartlar',
                              onTap: () => _showCards(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.fingerprint,
                              label: 'Parmak\nİzi',
                              onTap: () => _showFingerprint(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.wifi_tethering,
                              label: 'Uzaktan\nKumanda',
                              onTap: () => _showRemoteControl(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.history,
                              label: 'Kayıtlar',
                              onTap: () => _showRecords(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.share,
                              label: 'Paylaş',
                              onTap: () => _showShareLockDialog(context),
                            ),
                            _buildGridMenuItem(
                              context,
                              icon: Icons.settings,
                              label: 'Ayarlar',
                              onTap: () => _showSettings(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Büyük kilit butonunun hemen sağ altında Gateway/Remote Unlock butonu
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 + 80, // Kilit butonunun sağ tarafı
                  top: MediaQuery.of(context).size.height * 0.25, // Adjusted position
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.95),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _remoteUnlock(context),
                      icon: const Icon(Icons.wifi_tethering, color: Colors.white, size: 24),
                      tooltip: 'Uzaktan Aç (TTLock API)',
                      padding: EdgeInsets.zero,
                    ),
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
    try {
      // Önce gateway kontrolü yap
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      // Gateway listesini kontrol et
      final gateways = await apiService.getGatewayList();

      if (gateways.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Gateway Gerekli', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Bu kilidi uzaktan açmak için Gateway cihazı gerekli.\n\nÖnce resmi TTLock uygulaması ile kilide bağlanıp "Uzaktan Açma" özelliğini etkinleştirin.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
        return;
      }

      // Connectivity kontrolü
      final isConnected = await apiService.checkDeviceConnectivity(
        accessToken: accessToken,
        lockId: widget.lock['lockId'].toString(),
      );

      if (!isConnected) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Bağlantı Hatası', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Kilit çevrimiçi değil. Uzaktan açma için Gateway\'in aktif olması gerekir.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
        return;
      }

      // TTLock API ile uzaktan açma komutunu gönder
      print('🚀 TTLock /v3/lock/unlock API çağrısı başlatılıyor...');
      await apiService.sendRemoteUnlock(
        lockId: widget.lock['lockId'].toString(),
      );

      if (!mounted) return;

      print('✅ Uzaktan açma komutu başarıyla gönderildi');

      // Başarılı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔓 Uzaktan açma komutu gönderildi'),
          backgroundColor: Colors.green,
        ),
      );

      // Ana sayfaya güncelleme gönder
      Navigator.of(context).pop({
        'action': 'lock_updated',
        'lock': widget.lock,
        'device_id': widget.lock['lockId'],
        'new_state': false, // Uzaktan açıldı
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uzaktan kontrol hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEKeys(BuildContext context) async {
    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final eKeys = await apiService.getLockEKeys(
        accessToken: accessToken,
        lockId: widget.lock['lockId'].toString(),
      );      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Elektronik Anahtarlar', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: eKeys.isEmpty
                ? const Center(
                    child: Text(
                      'Bu kilit için elektronik anahtar bulunamadı.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: eKeys.length,
                    itemBuilder: (context, index) {
                      final eKey = eKeys[index];
                      final isOwner = eKey['userType'] == 1;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOwner ? Colors.blue : Colors.orange,
                          child: Icon(
                            isOwner ? Icons.person : Icons.share,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          eKey['keyName'] ?? 'Anahtar ${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          isOwner ? 'Sahip' : 'Paylaşılan',
                          style: TextStyle(
                            color: isOwner ? Colors.blue : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                           Navigator.pop(context); // Close dialog first
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => EKeyDetailPage(
                                 eKey: eKey,
                                 lockId: widget.lock['lockId'].toString(),
                                 lockName: widget.lock['name'] ?? '',
                                 isOwner: true, // Assuming current user is admin for now
                               ),
                             ),
                           );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Elektronik anahtar yükleme hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPasswords(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final lockIdString = widget.lock['lockId']?.toString();
      if (lockIdString == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kilit ID bulunamadı.')),
        );
        return;
      }
      final lockId = int.tryParse(lockIdString);
      if (lockId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geçersiz Kilit ID formatı.')),
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
        SnackBar(content: Text('Şifreleri görmek için giriş yapmalısınız.')),
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

  void _showFingerprint(BuildContext context) async {
    try {
      final apiService = ApiService(context.read<AuthRepository>());
      await apiService.getAccessToken();

      final accessToken = apiService.accessToken;
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final fingerprints = await apiService.getLockFingerprints(
        accessToken: accessToken,
        lockId: widget.lock['lockId'].toString(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Parmak İzi', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: fingerprints.isEmpty
                ? const Center(
                    child: Text(
                      'Bu kilit için tanımlı parmak izi bulunamadı.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: fingerprints.length,
                    itemBuilder: (context, index) {
                      final fingerprint = fingerprints[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.fingerprint, color: Colors.white),
                        ),
                        title: Text(
                          fingerprint['fingerprintName'] ?? 'Parmak İzi ${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Parmak İzi ID: ${fingerprint['fingerprintId'] ?? 'Bilinmiyor'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Icon(
                          fingerprint['fingerprintStatus'] == 1 ? Icons.check_circle : Icons.cancel,
                          color: fingerprint['fingerprintStatus'] == 1 ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parmak izi yükleme hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRemoteControl(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GatewayManagementDialog(),
    );
  }

  void _showRecords(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogsPage(
          lockId: widget.lock['lockId'].toString(),
          lockName: widget.lock['name'],
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