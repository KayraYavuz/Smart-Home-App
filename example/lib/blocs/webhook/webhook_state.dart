import 'package:equatable/equatable.dart';
import 'package:ttlock_flutter_example/api_service.dart';

abstract class WebhookState extends Equatable {
  const WebhookState();

  @override
  List<Object?> get props => [];
}

class WebhookInitial extends WebhookState {}

class WebhookConnecting extends WebhookState {}

class WebhookConnected extends WebhookState {
  final List<SeamWebhookEvent> events;
  final SeamWebhookEvent? latestEvent;

  const WebhookConnected({
    this.events = const [],
    this.latestEvent,
  });

  @override
  List<Object?> get props => [events, latestEvent];
}

class WebhookDisconnected extends WebhookState {}

class WebhookError extends WebhookState {
  final String message;

  const WebhookError(this.message);

  @override
  List<Object?> get props => [message];
}
