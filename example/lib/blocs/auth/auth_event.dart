import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String accessToken;

  const LoggedIn(this.accessToken);

  @override
  List<Object> get props => [accessToken];
}

class LoggedOut extends AuthEvent {}
