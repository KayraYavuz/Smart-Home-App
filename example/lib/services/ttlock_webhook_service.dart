import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ttlock_flutter_example/api_service.dart';

class TTLockWebhookService {
  static TTLockWebhookService? _instance;
  HttpServer? _server;
  final StreamController<TTLockWebhookEvent> _eventController = StreamController<TTLockWebhookEvent>.broadcast();

  // Singleton pattern
  static TTLockWebhookService get instance {
    _instance ??= TTLockWebhookService._();
    return _instance!;
  }

  TTLockWebhookService._();

  // Gerçek zamanlı olayları dinlemek için stream
  Stream<TTLockWebhookEvent> get eventStream => _eventController.stream;

  // Webhook sunucusunu başlat
  Future<void> startListening(String webhookUrl) async {
    // URL'den port bilgisini çıkar (varsayılan 8080)
    final uri = Uri.parse(webhookUrl);
    final int port = uri.hasPort ? uri.port : 8080;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('TTLock Webhook server started on port $port');
      print('Webhook URL: http://localhost:$port/ttlock/webhook');

      _server!.listen((HttpRequest request) async {
        if (request.method == 'POST' && request.uri.path == uri.path) {
          await _handleWebhookRequest(request);
        } else {
          request.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..write('Method not allowed')
            ..close();
        }
      });
    } catch (e) {
      print('Failed to start TTLock webhook server: $e');
      // Gerçek uygulamada ngrok veya benzeri tunneling servisi kullan
      print('For development, use ngrok: ngrok http $port');
    }
  }

  // Webhook isteğini işle
  Future<void> _handleWebhookRequest(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final payload = jsonDecode(body) as Map<String, dynamic>;

      // TTLock webhook olayını işle
      final event = ApiService.processTTLockWebhookEvent(payload);
      if (event != null) {
        _eventController.add(event);
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..write('OK')
        ..close();
    } catch (e) {
      print('Error handling TTLock webhook request: $e');
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Bad Request')
        ..close();
    }
  }

  // Sunucuyu durdur
  void stopListening() {
    _server?.close();
    _eventController.close();
    print('TTLock Webhook server stopped');
  }

  // Webhook test için simülasyon olayı gönder
  void simulateWebhookEvent(TTLockWebhookEvent event) {
    _eventController.add(event);
  }
}
