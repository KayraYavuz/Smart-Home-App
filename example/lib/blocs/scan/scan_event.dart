import 'package:equatable/equatable.dart';
import 'package:ttlock_flutter/ttlock.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object> get props => [];
}

class StartScan extends ScanEvent {}

class StopScan extends ScanEvent {}

class AddLock extends ScanEvent {
  final TTLockScanModel lock;

  const AddLock(this.lock);

  @override
  List<Object> get props => [lock];
}
