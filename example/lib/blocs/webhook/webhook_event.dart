import 'package:equatable/equatable.dart';
import 'package:ttlock_flutter_example/api_service.dart';

abstract class WebhookEvent extends Equatable {
  const WebhookEvent();

  @override
  List<Object?> get props => [];
}

class ConnectWebhook extends WebhookEvent {
  final String websocketUrl;

  const ConnectWebhook(this.websocketUrl);

  @override
  List<Object?> get props => [websocketUrl];
}

class DisconnectWebhook extends WebhookEvent {}

class WebhookEventReceived extends WebhookEvent {
  final SeamWebhookEvent webhookEvent;

  const WebhookEventReceived(this.webhookEvent);

  @override
  List<Object?> get props => [webhookEvent];
}

class SimulateWebhookEvent extends WebhookEvent {
  final SeamWebhookEvent simulatedEvent;

  const SimulateWebhookEvent(this.simulatedEvent);

  @override
  List<Object?> get props => [simulatedEvent];
}
