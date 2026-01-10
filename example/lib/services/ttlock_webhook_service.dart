import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yavuz_lock/blocs/ttlock_webhook/ttlock_webhook_bloc.dart';
import 'package:yavuz_lock/blocs/ttlock_webhook/ttlock_webhook_event.dart';
import 'package:yavuz_lock/blocs/ttlock_webhook/ttlock_webhook_state.dart';

class TTLockWebhookService {
  static final TTLockWebhookService _instance = TTLockWebhookService._internal();
  factory TTLockWebhookService() => _instance;
  TTLockWebhookService._internal();

  TTLockWebhookBloc? _bloc;
  String? _webhookUrl;

  // For simulating webhook events if needed, or connecting to a backend WebSocket
  final StreamController<TTLockWebhookEventData> _eventController =
      StreamController<TTLockWebhookEventData>.broadcast();

  Stream<TTLockWebhookEventData> get eventStream => _eventController.stream;

  void setBloc(TTLockWebhookBloc bloc) {
    _bloc = bloc;
    // When the BLoC is set, start listening to its events to dispatch through the service
    _bloc?.stream.listen((state) {
      if (state is TTLockWebhookEventReceivedState) {
        // This is a bit circular if the service dispatches to the bloc, then listens to the bloc
        // A direct communication from backend to service, then service to bloc is more typical.
        // For simulation purposes or if backend pushes to this service's method, it works.
      }
    });
  }

  void startListening(String webhookUrl) {
    _webhookUrl = webhookUrl;
    print('TTLock Webhook Service initialized. Ready to process events for: $webhookUrl');
    // In a real app, this would typically connect to a backend WebSocket
    // or register the webhook URL with the TTLock API if dynamic registration is supported
    // and this client acts as a proxy for a server.
  }

  void stopListening() {
    _eventController.close();
    print('TTLock Webhook Service stopped.');
  }

  /// This method would be called by your backend server
  /// (which receives the actual webhooks from TTLock)
  /// or directly for simulation purposes.
  Future<void> handleIncomingWebhook(Map<String, dynamic> payload) async {
    try {
      final eventData = TTLockWebhookEventData.fromJson(payload);

      _eventController.add(eventData); // Add to internal stream for other listeners
      _bloc?.add(TTLockWebhookEventReceived(eventData)); // Dispatch to BLoC

      print('✅ Processed TTLock Webhook event: ${eventData.eventType} for lock ${eventData.lockId}');
    } catch (e) {
      print('❌ Error processing incoming webhook payload: $e');
    }
  }

  // Helper to simulate an event if needed for testing
  void simulateWebhookEvent(TTLockWebhookEventData event) {
    _eventController.add(event);
    _bloc?.add(TTLockWebhookEventReceived(event));
  }

  /// Sends an event to the configured webhook URL
  Future<void> sendEvent({required String eventType, required Map<String, dynamic> data}) async {
    if (_webhookUrl == null || _webhookUrl!.isEmpty) {
      print('❌ Webhook URL is not configured.');
      return;
    }

    try {
      final payload = {
        'eventType': eventType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...data,
      };

      print('🚀 Sending webhook event to $_webhookUrl');
      final response = await http.post(
        Uri.parse(_webhookUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Webhook sent successfully: ${response.statusCode}');
      } else {
        print('⚠️ Webhook sent but returned error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Webhook send error: $e');
    }
  }
}