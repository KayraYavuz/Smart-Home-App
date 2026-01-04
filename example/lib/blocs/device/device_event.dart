import 'package:equatable/equatable.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object> get props => [];
}

class UnlockDevice extends DeviceEvent {
  final Map<String, dynamic> lock;

  const UnlockDevice(this.lock);

  @override
  List<Object> get props => [lock];
}

class LockDevice extends DeviceEvent {
    final Map<String, dynamic> lock;

  const LockDevice(this.lock);

  @override
  List<Object> get props => [lock];
}
