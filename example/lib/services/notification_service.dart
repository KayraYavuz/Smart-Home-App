import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    print("🚀 NotificationService: initialize() başladı...");
    if (_isInitialized) {
      print("⚠️ NotificationService: Zaten başlatılmış.");
      return;
    }

    try {
      // 0. Otomatik Başlatmayı Aç
      await _firebaseMessaging.setAutoInitEnabled(true);

      // 1. İzin İste - Hızlı işlem
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('🔔 İzin Durumu: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Kullanıcı bildirim izni verdi.');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Kullanıcı geçici izin verdi.');
      } else {
        print('❌ Kullanıcı izin vermedi.');
        _isInitialized = true; // İzin olmasa bile devam et, app açılsın
        return;
      }

      // 2. Arka Plan İşleyicisi - Hızlı
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Yerel Bildirim Ayarları (Foreground için) - Hızlı
      await _setupLocalNotifications();

      // 4. Token Alma - ARKA PLANA TAŞINDI (Non-blocking)
      // Bu işlem arka planda çalışır, UI'ı bloklamaz
      _fetchTokenAsync();

      // 5. Foreground Dinleme - Hemen kur
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("☀️ ÖN PLANDA MESAJ GELDİ!");
        print("☀️ Başlık: ${message.notification?.title}");
        print("☀️ Body: ${message.notification?.body}");
        print("☀️ Data: ${message.data}");
        _showLocalNotification(message);
      });

      // 6. Tıklama Dinleme - Hemen kur
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("👆 Bildirime tıklandı.");
      });

      _isInitialized = true;
      print("✅ NotificationService kurulumu tamamlandı (token arka planda alınıyor).");

    } catch (e) {
      print("❌ NotificationService Hatası: $e");
      _isInitialized = true; // Hata olsa bile app açılsın
    }
  }

  /// APNs ve FCM token'larını arka planda alır (UI'ı bloklamaz)
  void _fetchTokenAsync() async {
    try {
      print("⏳ APNs Token arka planda bekleniyor...");
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      int retry = 0;
      
      while (apnsToken == null && retry < 5) {
        await Future.delayed(const Duration(seconds: 2));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        retry++;
        print("⏳ APNs Token tekrar deneniyor ($retry/5)...");
      }

      if (apnsToken != null) {
        print("🍏 APNs Token alındı: $apnsToken");
        // APNs geldiyse FCM Token'ı al
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          print("\n🔥 FCM Token: $token\n");
        } else {
          print("❌ FCM Token alınamadı.");
        }
      } else {
        print("⚠️ APNs Token 10 saniye boyunca alınamadı. Push bildirimler çalışmayabilir.");
      }
    } catch (e) {
      print("❌ Token alma hatası: $e");
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
    
    // Android Kanalı Oluştur (Önemli)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Acil Bildirimler',
      description: 'Kapı kilit olayları',
      importance: Importance.max,
    );
    
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    // iOS için Foreground sunum seçenekleri
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true,
      sound: true,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Acil Bildirimler',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}