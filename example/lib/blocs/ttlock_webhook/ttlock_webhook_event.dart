import 'package:equatable/equatable.dart';

abstract class TTLockWebhookBlocEvent extends Equatable {
  const TTLockWebhookBlocEvent();

  @override
  List<Object> get props => [];
}

class TTLockWebhookConnectRequested extends TTLockWebhookBlocEvent {
  final String webhookUrl;

  const TTLockWebhookConnectRequested(this.webhookUrl);

  @override
  List<Object> get props => [webhookUrl];
}

class TTLockWebhookDisconnectRequested extends TTLockWebhookBlocEvent {
  const TTLockWebhookDisconnectRequested();
}

class TTLockWebhookEventReceived extends TTLockWebhookBlocEvent {
  final dynamic ttlockEvent;

  const TTLockWebhookEventReceived(this.ttlockEvent);

  @override
  List<Object> get props => [ttlockEvent];
}
