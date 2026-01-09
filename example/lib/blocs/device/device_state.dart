import 'package:equatable/equatable.dart';

abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object> get props => [];
}

class DeviceInitial extends DeviceState {}

class DeviceLoading extends DeviceState {}

class DeviceSuccess extends DeviceState {
  final String? method;
  final int? battery;
  final bool? newLockState; // Yeni kilit durumu (true: kilitli, false: açık)

  const DeviceSuccess({this.method, this.battery, this.newLockState});

  @override
  List<Object> get props => [method ?? '', battery ?? 0, newLockState ?? false];
}

class DeviceFailure extends DeviceState {
  final String error;

  const DeviceFailure(this.error);

  @override
  List<Object> get props => [error];
}
