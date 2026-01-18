import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Arka planda gelen mesajları işleyen fonksiyon (Main fonksiyonunun dışında olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🌙 Arka Planda Bildirim Geldi: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    print("🚀 NotificationService initialize() başladı..."); // DEBUG LOG
    if (_isInitialized) {
      print("⚠️ NotificationService zaten başlatılmış."); // DEBUG LOG
      return;
    }

    try {
      // 1. İzin İste
      print("🔔 İzin isteniyor..."); // DEBUG LOG
      await _requestPermission();

      // 2. Arka Plan İşleyicisini Ayarla
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print("🌙 Arka plan işleyicisi ayarlandı."); // DEBUG LOG

      // 3. Yerel Bildirimleri (Foreground için) Ayarla
      await _setupLocalNotifications();
      print("🔔 Yerel bildirimler ayarlandı."); // DEBUG LOG

      // 4. Token Al (APNs Token Bekleme Eklendi)
      print("🔥 Token alınıyor... APNs Token bekleniyor..."); // DEBUG LOG
      
      // APNs Token'ın gelmesi için kısa bir süre bekle (iOS için kritik)
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        print("⏳ APNs Token henüz yok, 3 saniye bekleniyor...");
        await Future.delayed(const Duration(seconds: 3));
        apnsToken = await _firebaseMessaging.getAPNSToken();
      }

      print("🍏 APNs Token: $apnsToken");

      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
         print("\n\n**************************************************");
         print("🔥 FCM Token: $token");
         print("**************************************************\n\n");
      } else {
         print("❌ FCM Token hala NULL döndü!");
      }

      // 5. Ön Planda (Foreground) Mesaj Dinleme
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("☀️ Ön Planda Bildirim Geldi: ${message.notification?.title}");
        _showLocalNotification(message);
      });

      // 6. Uygulama Bildirime Tıklanarak Açıldığında
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("👆 Bildirime tıklandı: ${message.data}");
        // Burada ilgili sayfaya yönlendirme yapabilirsiniz
      });

      _isInitialized = true;
      print("✅ NotificationService başarıyla tamamlandı."); // DEBUG LOG

    } catch (e) {
      print("❌ NotificationService hatası: $e");
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('🔔 Bildirim İzni Durumu: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // App icon

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Yerel bildirime tıklandığında yapılacaklar
      },
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Sadece bildirim içeriği varsa göster
    if (message.notification == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'Acil Bildirimler', // title
      channelDescription: 'Kapı kilit olayları için bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
