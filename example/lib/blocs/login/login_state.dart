import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginSyncRequired extends LoginState {
  final String username;
  final String password;

  const LoginSyncRequired({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class LoginTTLockWebRedirect extends LoginState {}

class LoginFailure extends LoginState {
  final String error;

  const LoginFailure(this.error);

  @override
  List<Object> get props => [error];
}
