part of 'face_bloc.dart';

abstract class FaceEvent extends Equatable {
  const FaceEvent();

  @override
  List<Object> get props => [];
}

class LoadFaces extends FaceEvent {
  final int lockId;

  const LoadFaces(this.lockId);

  @override
  List<Object> get props => [lockId];
}

class AddFace extends FaceEvent {
  final int lockId;
  final String featureData;
  final int addType;
  final String name;
  final int startDate;
  final int endDate;

  const AddFace({
    required this.lockId,
    required this.featureData,
    required this.addType,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [lockId, featureData, addType, name, startDate, endDate];
}

class DeleteFace extends FaceEvent {
  final int lockId;
  final int faceId;

  const DeleteFace(this.lockId, this.faceId);

  @override
  List<Object> get props => [lockId, faceId];
}

class ClearAllFaces extends FaceEvent {
  final int lockId;

  const ClearAllFaces(this.lockId);

  @override
  List<Object> get props => [lockId];
}

class ChangeFacePeriod extends FaceEvent {
  final int lockId;
  final int faceId;
  final int startDate;
  final int endDate;

  const ChangeFacePeriod({
    required this.lockId,
    required this.faceId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [lockId, faceId, startDate, endDate];
}

class RenameFace extends FaceEvent {
  final int lockId;
  final int faceId;
  final String name;

  const RenameFace({
    required this.lockId,
    required this.faceId,
    required this.name,
  });

  @override
  List<Object> get props => [lockId, faceId, name];
}
