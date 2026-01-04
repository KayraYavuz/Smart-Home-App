import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:ttlock_flutter_example/blocs/scan/scan_event.dart';
import 'package:ttlock_flutter_example/blocs/scan/scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  StreamSubscription? _scanSubscription;
  final List<TTLockScanModel> _locks = [];
  StreamController<TTLockScanModel>? _scanController;

  ScanBloc() : super(ScanInitial()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<AddLock>(_onAddLock);
  }

  void _onStartScan(StartScan event, Emitter<ScanState> emit) {
    emit(ScanLoading());
    _scanController = StreamController<TTLockScanModel>();
    
    TTLock.startScanLock((lock) {
      if (!_locks.any((element) => element.lockMac == lock.lockMac)) {
        _locks.add(lock);
        _scanController?.add(lock);
      }
    });

    _scanSubscription = _scanController?.stream.listen((lock) {
      emit(ScanLoaded(List.from(_locks)));
    });
  }

  void _onStopScan(StopScan event, Emitter<ScanState> emit) {
    TTLock.stopScanLock();
    _scanSubscription?.cancel();
    _scanController?.close();
    emit(ScanLoaded(List.from(_locks)));
  }

  void _onAddLock(AddLock event, Emitter<ScanState> emit) {
    emit(ScanLoading());
    try {
      Map<String, dynamic> map = {};
      map["lockMac"] = event.lock.lockMac;
      map["lockVersion"] = event.lock.lockVersion;

      print('Initializing lock: ${event.lock.lockName} (${event.lock.lockMac})');

      TTLock.initLock(map, (lockData) {
        print('Lock initialized successfully: $lockData');

        // Başarıyla eklenen kilidi state'e ekle
        final addedLock = {
          'name': event.lock.lockName.isNotEmpty ? event.lock.lockName : 'TTLock Kilit',
          'status': 'Kilitli',
          'isLocked': true,
          'battery': 85, // Varsayılan pil seviyesi
          'lockData': lockData,
          'lockMac': event.lock.lockMac,
          'deviceType': 'ttlock',
          'lockId': lockData.toString(), // lockId olarak lockData kullan
        };

        emit(AddLockSuccess(addedLock));
      }, (errorCode, errorMsg) {
        print('Lock initialization failed: $errorCode - $errorMsg');
        emit(ScanFailure('Kilit eklenirken hata oluştu: $errorMsg'));
      });
    } catch (e) {
      print('Exception during lock addition: $e');
      emit(ScanFailure('Beklenmeyen hata: $e'));
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _scanController?.close();
    return super.close();
  }
}
