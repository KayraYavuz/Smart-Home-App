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

  const DeviceSuccess({this.method, this.battery});

  @override
  List<Object> get props => [method ?? '', battery ?? 0];
}

class DeviceFailure extends DeviceState {
  final String error;

  const DeviceFailure(this.error);

  @override
  List<Object> get props => [error];
}
