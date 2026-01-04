import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/blocs/webhook/webhook_event.dart';
import 'package:ttlock_flutter_example/blocs/webhook/webhook_state.dart';

class WebhookBloc extends Bloc<WebhookEvent, WebhookState> {
  final WebhookService _webhookService;
  StreamSubscription<SeamWebhookEvent>? _eventSubscription;

  WebhookBloc(this._webhookService) : super(WebhookInitial()) {
    on<ConnectWebhook>(_onConnectWebhook);
    on<DisconnectWebhook>(_onDisconnectWebhook);
    on<WebhookEventReceived>(_onWebhookEventReceived);
    on<SimulateWebhookEvent>(_onSimulateWebhookEvent);
  }

  void _onConnectWebhook(ConnectWebhook event, Emitter<WebhookState> emit) async {
    emit(WebhookConnecting());

    try {
      _webhookService.connect(event.websocketUrl);

      // Webhook olaylarını dinle
      _eventSubscription = _webhookService.eventStream.listen(
        (webhookEvent) {
          add(WebhookEventReceived(webhookEvent));
        },
        onError: (error) {
          emit(WebhookError('Connection error: $error'));
        },
      );

      emit(WebhookConnected());
    } catch (e) {
      emit(WebhookError('Failed to connect: $e'));
    }
  }

  void _onDisconnectWebhook(DisconnectWebhook event, Emitter<WebhookState> emit) {
    _eventSubscription?.cancel();
    _webhookService.disconnect();
    emit(WebhookDisconnected());
  }

  void _onWebhookEventReceived(WebhookEventReceived event, Emitter<WebhookState> emit) {
    final webhookEvent = event.webhookEvent;

    // Mevcut state'e yeni event'i ekle
    if (state is WebhookConnected) {
      final currentEvents = (state as WebhookConnected).events;
      final updatedEvents = List<SeamWebhookEvent>.from(currentEvents)..add(webhookEvent);

      emit(WebhookConnected(events: updatedEvents, latestEvent: webhookEvent));
    }
  }

  void _onSimulateWebhookEvent(SimulateWebhookEvent event, Emitter<WebhookState> emit) {
    _webhookService.simulateWebhookEvent(event.simulatedEvent);
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _webhookService.disconnect();
    return super.close();
  }
}
