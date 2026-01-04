import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter_example/blocs/ttlock_webhook/ttlock_webhook_event.dart';
import 'package:ttlock_flutter_example/blocs/ttlock_webhook/ttlock_webhook_state.dart';
import 'package:ttlock_flutter_example/services/ttlock_webhook_service.dart';

class TTLockWebhookBloc extends Bloc<TTLockWebhookBlocEvent, TTLockWebhookState> {
  final TTLockWebhookService _webhookService;
  late StreamSubscription _webhookEventSubscription;

  TTLockWebhookBloc(this._webhookService) : super(TTLockWebhookInitial()) {
    on<TTLockWebhookConnectRequested>(_onConnectRequested);
    on<TTLockWebhookDisconnectRequested>(_onDisconnectRequested);
    on<TTLockWebhookEventReceived>(_onWebhookEventReceived);

    // TTLockWebhookService'den gelen olayları dinle
    _webhookEventSubscription = _webhookService.eventStream.listen((event) {
      add(TTLockWebhookEventReceived(event));
    });
  }

  void _onConnectRequested(TTLockWebhookConnectRequested event, Emitter<TTLockWebhookState> emit) {
    _webhookService.startListening(event.webhookUrl);
    emit(TTLockWebhookConnected(event.webhookUrl));
  }

  void _onDisconnectRequested(TTLockWebhookDisconnectRequested event, Emitter<TTLockWebhookState> emit) {
    _webhookService.stopListening();
    emit(TTLockWebhookDisconnected());
  }

  void _onWebhookEventReceived(TTLockWebhookEventReceived event, Emitter<TTLockWebhookState> emit) {
    // Gelen webhook olayını state'e ekle
    emit(TTLockWebhookEventReceivedState(event.ttlockEvent));
  }

  @override
  Future<void> close() {
    _webhookEventSubscription.cancel();
    _webhookService.stopListening();
    return super.close();
  }
}
