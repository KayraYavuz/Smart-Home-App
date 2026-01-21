import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/scan/scan_event.dart';
import 'package:yavuz_lock/blocs/scan/scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ApiService apiService;
  StreamSubscription? _scanSubscription;
  final List<TTLockScanModel> _locks = [];
  StreamController<TTLockScanModel>? _scanController;

  ScanBloc({required this.apiService}) : super(ScanInitial()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<AddLock>(_onAddLock);
  }

  Future<void> _onStartScan(StartScan event, Emitter<ScanState> emit) async {
    if (emit.isDone) return;
    emit(ScanLoading());
    
    // Bluetooth durumunu kontrol et
    final Completer<TTBluetoothState> btStateCompleter = Completer();
    TTLock.getBluetoothState((state) {
      if (!btStateCompleter.isCompleted) {
        btStateCompleter.complete(state);
      }
    });
    
    final btState = await btStateCompleter.future;
    if (emit.isDone) return;

    if (btState != TTBluetoothState.turnOn) {
      emit(const ScanFailure('Bluetooth kapalı veya yetkisiz. Lütfen Bluetooth\'u açın.'));
      return;
    }

    _locks.clear();
    _scanController?.close();
    _scanController = StreamController<TTLockScanModel>();
    
    TTLock.startScanLock((lock) {
      if (!_locks.any((element) => element.lockMac == lock.lockMac)) {
        _locks.add(lock);
        if (!(_scanController?.isClosed ?? true)) {
          _scanController?.add(lock);
        }
      }
    });

    // Stream'i dinle ve her yeni kilitte state'i güncelle
    try {
      await emit.forEach<TTLockScanModel>(
        _scanController!.stream,
        onData: (lock) => ScanLoaded(List.from(_locks)),
      );
    } catch (e) {
      print('Scan stream error: $e');
    }
  }

  void _onStopScan(StopScan event, Emitter<ScanState> emit) {
    TTLock.stopScanLock();
    _scanSubscription?.cancel();
    _scanController?.close();
    if (!emit.isDone) {
      emit(ScanLoaded(List.from(_locks)));
    }
  }

  Future<void> _onAddLock(AddLock event, Emitter<ScanState> emit) async {
    if (emit.isDone) return;
    // Show connecting state with specific lock name
    emit(ScanConnecting('${event.lock.lockName.isNotEmpty ? event.lock.lockName : "Kilit"} bağlanılıyor...'));

    try {
      // TTLock initLock için gerekli parametre haritası
      Map<String, dynamic> map = {
        'lockMac': event.lock.lockMac,
        'lockName': event.lock.lockName, // Dökümantasyona göre eklendi
        'lockVersion': event.lock.lockVersion,
        'isInited': event.lock.isInited,
      };

      print('🏗️ Bluetooth Başlatma İşlemi Başlıyor...');
      print('   Kilit Adı: ${event.lock.lockName}');
      print('   Kilit MAC: ${event.lock.lockMac}');
      print('   Kilit Versiyonu: ${event.lock.lockVersion}');
      print('   Sinyal Gücü (RSSI): ${event.lock.rssi}');
      print('   Kilit Başlatılmış mı? (isInited): ${event.lock.isInited}');

      final Completer<String> initCompleter = Completer();

      // 1. Bluetooth üzerinden kilidi başlat
      TTLock.initLock(map, (lockData) {
        if (!initCompleter.isCompleted) {
          print('✅ Bluetooth Handshake Başarılı!');
          initCompleter.complete(lockData);
        }
      }, (errorCode, errorMsg) {
        if (!initCompleter.isCompleted) {
          String detailedError = errorMsg;
          
          print('🔍 Ham Hata Alındı - Kod: $errorCode (${errorCode.runtimeType}), Mesaj: $errorMsg');

          // TTLock spesifik hata kodlarını anlamlandır
          if (errorCode.toString().contains('4')) {
            detailedError = 'Kilit ayar modunda değil. Lütfen tuş takımına dokunup ışıkları yaktıktan sonra tekrar deneyin.';
          } else if (errorCode.toString().contains('5')) {
            detailedError = 'Bu kilit zaten başka bir hesaba veya bu hesaba kayıtlı. Önce kilidi sıfırlamanız gerekir.';
          } else if (errorCode.toString().contains('1')) {
            detailedError = 'Bluetooth bağlantısı kilit tarafından reddedildi veya zaman aşımına uğradı.';
          } else {
            // Bilinmeyen veya 'fail' durumları için daha açıklayıcı olalım
            detailedError = 'Bluetooth bağlantısı kurulamadı ($errorMsg). Kilit başka bir hesaba bağlı olabilir, Bluetooth önbelleği dolmuş olabilir veya kilit koruma modunda olabilir.';
          }

          print('❌ Bluetooth Handshake Hatası: $errorCode - $detailedError');
          initCompleter.completeError('BT_ERROR (Kod: $errorCode): $detailedError');
        }
      });

      // Bluetooth işlemini bekle
      String lockData;
      try {
        lockData = await initCompleter.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('⏳ Bluetooth Başlatma Zaman Aşımı!');
            throw TimeoutException('Kilit yanıt vermedi. Lütfen daha yakın olun ve kilidi uyandırın.');
          },
        );
      } catch (e) {
        if (emit.isDone) return;
        String userFriendlyError = e is TimeoutException ? e.message! : e.toString();
        emit(ScanFailure(userFriendlyError));
        return;
      }

      if (emit.isDone) return;
      print('☁️ Kilit Buluta Kaydediliyor...');

      try {
        // 2. Bluetooth'tan alınan lockData'yı TTLock Cloud'a kaydet
        final apiResult = await apiService.initializeLock(
          lockData: lockData,
          lockAlias: event.lock.lockName.isNotEmpty ? event.lock.lockName : 'Yavuz Lock',
        );

        if (emit.isDone) return;
        print('Lock registered successfully on Cloud: $apiResult');
        print('🎉 Kilit Başarıyla Kuruldu!');

        final addedLock = {
          'name': apiResult['lockAlias'] ?? event.lock.lockName,
          'status': 'Kilitli',
          'isLocked': true,
          'battery': apiResult['electricQuantity'] ?? 100,
          'lockData': lockData,
          'lockMac': event.lock.lockMac,
          'deviceType': 'ttlock',
          'lockId': apiResult['lockId'].toString(),
        };

        emit(AddLockSuccess(addedLock));
      } catch (apiError) {
        print('❌ Bulut Kayıt Hatası: $apiError');
        
        String userFriendlyApiError = _parseApiErrorMessage(apiError.toString());

        // DÖKÜMANTASYON UYARISI: Bulut kaydı başarısız olursa kilidi Bluetooth üzerinden resetle!
        print('♻️ Bulut kaydı başarısız olduğu için kilit Bluetooth üzerinden temizleniyor...');
        TTLock.resetLock(lockData, () {
          print('✅ Kilit başarıyla temizlendi (tekrar denenebilir).');
        }, (errorCode, errorMsg) {
          print('⚠️ Kilit temizlenemedi: $errorMsg');
        });

        if (emit.isDone) return;
        emit(ScanFailure('Bulut Kayıt Hatası: $userFriendlyApiError'));
      }
    } catch (e) {
      if (emit.isDone) return;
      print('Unexpected exception during lock addition: $e');
      emit(ScanFailure('Beklenmeyen hata: $e'));
    }
  }

  String _parseApiErrorMessage(String errorMsg) {
    // API hata kodlarını yakala ve Türkçeleştir
    if (errorMsg.contains('errcode: 30003') || errorMsg.contains('errcode: -1027')) {
      return 'Bu kilit zaten başka bir kullanıcıya kayıtlı. Lütfen önce önceki hesaptan silin.';
    } else if (errorMsg.contains('errcode: 20002') || errorMsg.contains('errcode: -2018')) {
      return 'Bu işlem için yetkiniz yok (Yönetici değilsiniz).';
    } else if (errorMsg.contains('errcode: 10003') || errorMsg.contains('errcode: 10004')) {
      return 'Oturum süreniz dolmuş. Lütfen çıkış yapıp tekrar girin.';
    } else if (errorMsg.contains('errcode: -2025')) {
      return 'Kilit dondurulmuş (Frozen). İşlem yapılamaz.';
    } else if (errorMsg.contains('errcode: 80000')) {
      return 'Zaman damgası hatası. Lütfen telefonunuzun saat ve tarih ayarlarını kontrol edin.';
    } else if (errorMsg.contains('errcode: -4063')) {
      return 'Lütfen önce bu kilidi veya diğer kilitlerinizi hesabınızdan silin.';
    } else if (errorMsg.contains('errcode: 10000') || errorMsg.contains('errcode: 10001')) {
      return 'Uygulama kimlik doğrulama hatası (Client ID/Secret geçersiz).';
    } else if (errorMsg.contains('errcode: 90000')) {
      return 'Sunucu tarafında bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
    } else if (errorMsg.contains('errcode: 1')) {
      return 'İşlem sunucu tarafından reddedildi.';
    }
    
    return errorMsg; // Eşleşme yoksa orijinal hatayı dön
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _scanController?.close();
    return super.close();
  }
}
