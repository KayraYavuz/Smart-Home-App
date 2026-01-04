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

  const LockLoaded(this.locks);

  @override
  List<Object> get props => [locks];
}

class LockFailure extends AppLockState {
  final String error;

  const LockFailure(this.error);

  @override
  List<Object> get props => [error];
}
