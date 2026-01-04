import 'package:equatable/equatable.dart';

abstract class LockEvent extends Equatable {
  const LockEvent();

  @override
  List<Object> get props => [];
}

class FetchLocks extends LockEvent {}
