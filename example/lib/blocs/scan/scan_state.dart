import 'package:equatable/equatable.dart';
import 'package:ttlock_flutter/ttlock.dart';

abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object> get props => [];
}

class ScanInitial extends ScanState {}

class ScanLoading extends ScanState {}

class ScanLoaded extends ScanState {
  final List<TTLockScanModel> locks;
  final List<Map<String, dynamic>> gateways;

  const ScanLoaded({this.locks = const [], this.gateways = const []});

  @override
  List<Object> get props => [locks, gateways];
}

class ScanFailure extends ScanState {
  final String error;

  const ScanFailure(this.error);

  @override
  List<Object> get props => [error];
}

class AddLockSuccess extends ScanState {
  final Map<String, dynamic> addedLock;

  const AddLockSuccess(this.addedLock);

  @override
  List<Object> get props => [addedLock];
}

class ScanConnecting extends ScanState {
  final String lockName;
  
  const ScanConnecting(this.lockName);

  @override
  List<Object> get props => [lockName];
}
