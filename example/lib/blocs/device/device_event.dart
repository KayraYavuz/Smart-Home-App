import 'package:equatable/equatable.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object> get props => [];
}

class UnlockDevice extends DeviceEvent {
  final Map<String, dynamic> lock;
  final bool onlyBluetooth;

  const UnlockDevice(this.lock, {this.onlyBluetooth = false});

  @override
  List<Object> get props => [lock, onlyBluetooth];
}

class LockDevice extends DeviceEvent {
    final Map<String, dynamic> lock;
    final bool onlyBluetooth;

  const LockDevice(this.lock, {this.onlyBluetooth = false});

  @override
  List<Object> get props => [lock, onlyBluetooth];
}
