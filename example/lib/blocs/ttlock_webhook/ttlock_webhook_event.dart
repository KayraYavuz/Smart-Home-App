import 'package:equatable/equatable.dart';

/// TTLock Webhook Event Data Model
class TTLockWebhookEventData {
  final String lockId;
  final String eventType;
  final String timestamp;
  final int? batteryLevel; // Add batteryLevel field
  final String? accessMethod; // Add accessMethod field
  final Map<String, dynamic> data;

  TTLockWebhookEventData({
    required this.lockId,
    required this.eventType,
    required this.timestamp,
    this.batteryLevel, // Make it optional
    this.accessMethod, // Make it optional
    required this.data,
  });

  factory TTLockWebhookEventData.fromJson(Map<String, dynamic> json) {
    return TTLockWebhookEventData(
      lockId: json['lockId']?.toString() ?? 'unknown',
      eventType: json['eventType']?.toString() ?? 'unknown',
      timestamp: (json['date']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString()),
      batteryLevel: json['batteryLevel'] != null ? int.tryParse(json['batteryLevel'].toString()) : null, // Parse batteryLevel
      accessMethod: json['accessMethod']?.toString(), // Parse accessMethod
      data: json,
    );
  }
}

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
  final TTLockWebhookEventData ttlockEvent;

  const TTLockWebhookEventReceived(this.ttlockEvent);

  @override
  List<Object> get props => [ttlockEvent];
}
