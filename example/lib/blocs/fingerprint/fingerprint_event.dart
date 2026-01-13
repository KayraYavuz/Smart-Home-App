import 'package:equatable/equatable.dart';

abstract class FingerprintEvent extends Equatable {
  const FingerprintEvent();

  @override
  List<Object> get props => [];
}

class LoadFingerprints extends FingerprintEvent {
  final int lockId;

  const LoadFingerprints(this.lockId);

  @override
  List<Object> get props => [lockId];
}

class AddFingerprint extends FingerprintEvent {
  final int lockId;
  final String fingerprintNumber;
  final String fingerprintName;
  final int startDate;
  final int endDate;

  const AddFingerprint({
    required this.lockId,
    required this.fingerprintNumber,
    required this.fingerprintName,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [lockId, fingerprintNumber, fingerprintName, startDate, endDate];
}

class DeleteFingerprint extends FingerprintEvent {
  final int lockId;
  final int fingerprintId;

  const DeleteFingerprint(this.lockId, this.fingerprintId);

  @override
  List<Object> get props => [lockId, fingerprintId];
}

class ChangeFingerprintPeriod extends FingerprintEvent {
  final int lockId;
  final int fingerprintId;
  final int startDate;
  final int endDate;

  const ChangeFingerprintPeriod({
    required this.lockId,
    required this.fingerprintId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [lockId, fingerprintId, startDate, endDate];
}

class ClearAllFingerprints extends FingerprintEvent {
  final int lockId;

  const ClearAllFingerprints(this.lockId);

  @override
  List<Object> get props => [lockId];
}

class RenameFingerprint extends FingerprintEvent {
  final int lockId;
  final int fingerprintId;
  final String fingerprintName;

  const RenameFingerprint({
    required this.lockId,
    required this.fingerprintId,
    required this.fingerprintName,
  });

  @override
  List<Object> get props => [lockId, fingerprintId, fingerprintName];
}
