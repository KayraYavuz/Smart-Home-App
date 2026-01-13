import 'package:equatable/equatable.dart';

abstract class FingerprintState extends Equatable {
  const FingerprintState();

  @override
  List<Object> get props => [];
}

class FingerprintInitial extends FingerprintState {}

class FingerprintLoading extends FingerprintState {}

class FingerprintsLoaded extends FingerprintState {
  final List<dynamic> fingerprints;

  const FingerprintsLoaded(this.fingerprints);

  @override
  List<Object> get props => [fingerprints];
}

class FingerprintOperationSuccess extends FingerprintState {}

class FingerprintOperationFailure extends FingerprintState {
  final String error;

  const FingerprintOperationFailure(this.error);

  @override
  List<Object> get props => [error];
}
