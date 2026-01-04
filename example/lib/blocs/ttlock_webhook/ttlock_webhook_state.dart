import 'package:equatable/equatable.dart';

abstract class TTLockWebhookState extends Equatable {
  const TTLockWebhookState();

  @override
  List<Object?> get props => [];
}

class TTLockWebhookInitial extends TTLockWebhookState {}

class TTLockWebhookConnected extends TTLockWebhookState {
  final String webhookUrl;
  final dynamic latestEvent;

  const TTLockWebhookConnected(this.webhookUrl, {this.latestEvent});

  @override
  List<Object?> get props => [webhookUrl, latestEvent];
}

class TTLockWebhookDisconnected extends TTLockWebhookState {}

class TTLockWebhookEventReceivedState extends TTLockWebhookState {
  final dynamic ttlockEvent;

  const TTLockWebhookEventReceivedState(this.ttlockEvent);

  @override
  List<Object?> get props => [ttlockEvent];
}
