part of 'face_bloc.dart';

abstract class FaceState extends Equatable {
  const FaceState();

  @override
  List<Object> get props => [];
}

class FaceInitial extends FaceState {}

class FaceLoading extends FaceState {}

class FacesLoaded extends FaceState {
  final List<dynamic> faces;

  const FacesLoaded(this.faces);

  @override
  List<Object> get props => [faces];
}

class FaceOperationSuccess extends FaceState {}

class FaceOperationFailure extends FaceState {
  final String error;

  const FaceOperationFailure(this.error);

  @override
  List<Object> get props => [error];
}
