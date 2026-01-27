import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends LoginEvent {
  final String username;
  final String password;

  const LoginButtonPressed({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class SyncPassword extends LoginEvent {
  final String username;
  final String password;
  final String code;

  const SyncPassword({required this.username, required this.password, required this.code});

  @override
  List<Object> get props => [username, password, code];
}
