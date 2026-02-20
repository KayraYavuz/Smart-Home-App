import 'package:equatable/equatable.dart';

abstract class AppLockState extends Equatable {
  const AppLockState();

  @override
  List<Object> get props => [];
}

class LockInitial extends AppLockState {}

class LockLoading extends AppLockState {}

class LockLoaded extends AppLockState {
  final List<Map<String, dynamic>> locks;
  final List<Map<String, dynamic>> gateways;

  const LockLoaded(this.locks, {this.gateways = const []});

  @override
  List<Object> get props => [locks, gateways];
}

class LockFailure extends AppLockState {
  final String error;

  const LockFailure(this.error);

  @override
  List<Object> get props => [error];
}
