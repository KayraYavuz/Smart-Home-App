part of 'passcode_cubit.dart';

abstract class PasscodeState extends Equatable {
  const PasscodeState();
  @override
  List<Object> get props => [];
}

class PasscodeInitial extends PasscodeState {}
class PasscodeLoading extends PasscodeState {}
class PasscodeLoadSuccess extends PasscodeState {
  final List<Passcode> passcodes;
  const PasscodeLoadSuccess(this.passcodes);
  @override
  List<Object> get props => [passcodes];
}
class PasscodeLoadFailure extends PasscodeState {
  final String error;
  const PasscodeLoadFailure(this.error);
    @override
  List<Object> get props => [error];
}
