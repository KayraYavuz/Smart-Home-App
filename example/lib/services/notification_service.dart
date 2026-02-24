import "package:flutter/foundation.dart";
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🌙 Arka Planda Bildirim Geldi: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Local storage key
  static const String _notificationsKey = 'local_notifications_history';
  static const String _unreadCountKey = 'unread_notification_count';

  // ValueNotifier for unread count to update UI reactively
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  bool _isInitialized = false;

  Future<void> initialize() async {
    debugPrint("🚀 NotificationService: initialize() başladı...");
    if (_isInitialized) return;
    


    try {
      await _firebaseMessaging.setAutoInitEnabled(true);

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized || 
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ Bildirim izni var.');
      } else {
        debugPrint('❌ Bildirim izni yok.');
        _isInitialized = true;
        return;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await _setupLocalNotifications();
      await _loadUnreadCount(); // Load initial unread count
      _fetchTokenAsync();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("☀️ Ön planda mesaj geldi: ${message.data}");
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("👆 Bildirime tıklandı.");
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("❌ NotificationService Hatası: $e");
      _isInitialized = true;
    }
  }

  void _fetchTokenAsync() async {
    try {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      int retry = 0;
      while (apnsToken == null && retry < 5) {
        await Future.delayed(const Duration(seconds: 2));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        retry++;
      }

      if (apnsToken != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) debugPrint("\n🔥 FCM Token: $token\n");
      }
    } catch (e) {
      debugPrint("❌ Token alma hatası: $e");
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/launcher_icon');

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

    await _localNotificationsPlugin.initialize(initializationSettings);
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Kilit Bildirimleri',
      description: 'Kapı kilit olayları ve uyarıları',
      importance: Importance.max,
    );
    
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true,
      sound: true,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    
    String title = notification?.title ?? 'Kilit İşlemi';
    String body = notification?.body ?? '';

    // --- TTLock Lock Name Mapping ---
    String? lockName;
    String? lockId = message.data['lockId']?.toString();

    // Try to find lock name in local cache
    if (lockId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedLocksStr = prefs.getString('cached_locks');
        if (cachedLocksStr != null) {
          final List<dynamic> cachedLocks = jsonDecode(cachedLocksStr);
          final lock = cachedLocks.firstWhere(
            (l) => l['lockId']?.toString() == lockId,
            orElse: () => null,
          );
          if (lock != null) {
            lockName = lock['name'] ?? lock['lockAlias'] ?? lock['lockName'];
          }
        }
      } catch (e) {
        debugPrint("Cache lookup error: $e");
      }
    }

    // If no explicit notification, build one from data
    if (notification == null) {
      if (message.data.isNotEmpty) {
        final name = lockName ?? message.data['lockName'] ?? message.data['lockAlias'] ?? 'Kilit';
        final username = message.data['username'] ?? message.data['sender'] ?? 'Biri';
        final action = message.data['message'] ?? 'işlem yaptı';
        
        title = name;
        body = '$username $action';
        
        if (body.trim().isEmpty) return;
      } else {
        return;
      }
    } else {
      // If we have a notification but it's generic, try to use lockName
      if (lockName != null && !title.contains(lockName) && !body.contains(lockName)) {
        title = lockName;
      }
    }

    await _localNotificationsPlugin.show(
      notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Kilit Bildirimleri',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Save notification locally and update badge
    await saveNotification(title, body, message.data);
  }

  // --- Local Storage & Badge Methods ---

  Future<void> _loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      unreadCount.value = prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      debugPrint("Error loading unread count: $e");
    }
  }

  Future<void> saveNotification(String title, String body, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Save to history
      final List<String> history = prefs.getStringList(_notificationsKey) ?? [];
      
      final newNotification = {
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
      };
      
      // Add to beginning
      history.insert(0, jsonEncode(newNotification));
      
      // Limit history to 50 items
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      await prefs.setStringList(_notificationsKey, history);

      // 2. Increment unread count
      int currentCount = prefs.getInt(_unreadCountKey) ?? 0;
      currentCount++;
      await prefs.setInt(_unreadCountKey, currentCount);
      unreadCount.value = currentCount;
      
      debugPrint("✅ Notification saved locally. Unread count: $currentCount");

    } catch (e) {
      debugPrint("❌ Error saving notification locally: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList(_notificationsKey) ?? [];
      
      return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint("❌ Error getting notifications: $e");
      return [];
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Reset unread count
      await prefs.setInt(_unreadCountKey, 0);
      unreadCount.value = 0;
      
      // Mark all items as read
      final List<String> history = prefs.getStringList(_notificationsKey) ?? [];
      final List<String> updatedHistory = [];
      
      for (var itemStr in history) {
        final item = jsonDecode(itemStr) as Map<String, dynamic>;
        item['read'] = true;
        updatedHistory.add(jsonEncode(item));
      }
      
      await prefs.setStringList(_notificationsKey, updatedHistory);
      
      // Clear badge
      await clearBadge();
      
    } catch (e) {
      debugPrint("❌ Error marking notifications as read: $e");
    }
  }

  Future<void> clearBadge() async {
    try {
      // Clear local notifications plugin badge (supported on iOS/MacOS)
      // For Android, this usually clears the grouping or badge count if supported by launcher
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
         await _firebaseMessaging.setForegroundNotificationPresentationOptions(badge: false);
         await _firebaseMessaging.setForegroundNotificationPresentationOptions(badge: true); // Reset setting
      }
      // Note: flutter_local_notifications doesn't have a direct 'clearBadge' for all platforms
      // but cancelling all notifications usually clears the badge on Android
      // await _localNotificationsPlugin.cancelAll(); 
      // User might not want to clear active notifications from tray, just the badge/count.
      // Modifying badge count directly is platform specific. 
      // For iOS, the 'badge' permission handles it. 
      
      debugPrint("🧹 Badge clearance attempted.");
    } catch (e) {
      debugPrint("❌ Error clearing badge: $e");
    }
  }
}
