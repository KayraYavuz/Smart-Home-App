import 'package:equatable/equatable.dart';
import 'package:ttlock_flutter_example/blocs/ttlock_webhook/ttlock_webhook_event.dart';

abstract class TTLockWebhookState extends Equatable {
  const TTLockWebhookState();

  @override
  List<Object?> get props => [];
}

class TTLockWebhookInitial extends TTLockWebhookState {}

class TTLockWebhookConnected extends TTLockWebhookState {
  final String webhookUrl;
  final TTLockWebhookEventData? latestEvent;

  const TTLockWebhookConnected(this.webhookUrl, {this.latestEvent});

  @override
  List<Object?> get props => [webhookUrl, latestEvent];
}

class TTLockWebhookDisconnected extends TTLockWebhookState {}

class TTLockWebhookEventReceivedState extends TTLockWebhookState {
  final TTLockWebhookEventData ttlockEvent;

  const TTLockWebhookEventReceivedState(this.ttlockEvent);

  @override
  List<Object?> get props => [ttlockEvent];
}
