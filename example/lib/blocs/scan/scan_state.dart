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

  const ScanLoaded(this.locks);

  @override
  List<Object> get props => [locks];
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
  final String message;
  
  const ScanConnecting(this.message);

  @override
  List<Object> get props => [message];
}
