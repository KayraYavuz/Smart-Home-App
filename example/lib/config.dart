import 'package:yavuz_lock/env/env.dart';

class ApiConfig {
  static const String baseUrl = 'https://euapi.ttlock.com';
  static String clientId = Env.ttlockClientId;
  static String clientSecret = Env.ttlockClientSecret;
  static String redirectUri = '';
  static String username = ''; // Boş bırakıldı
  static String password = ''; // Boş bırakıldı

  // Email config for verification codes — kept out of git via env.dart.
  // Fill smtpUser/smtpPassword in lib/env/env.dart (gitignored). Empty =
  // app-sent email disabled.
  static String smtpUser = Env.smtpUser;
  static String smtpPassword = Env.smtpPassword;

  // TTLock assigns this short prefix to our clientId internally.
  // It's returned as the username prefix in registerUser responses (e.g. "fihbg_username").
  static const String ttlockUsernamePrefix = 'fihbg_';
}
// DEBUG: Test credentials (TTLock test account)
// Uncomment to test with TTLock test account
// static String username = 'test@example.com';
// static String password = 'testpassword';

class TTLockConfig {
  // TTLock Webhook Callback URL (kendi sunucunuzun URL'i)
  // Bu URL, TTLock'un olay bildirimlerini göndereceği endpoint
  static const String webhookCallbackUrl =
      "https://ttlockcallback-ehrryn22fa-uc.a.run.app";

  // TTLock Webhook Secret (callback doğrulaması için)
  static const String webhookSecret =
      "your_webhook_secret"; // TTLock portal'dan alın

  // TTLock Event Types
  static const Map<String, String> eventTypes = {
    '1': 'Kilit Açıldı',
    '2': 'Kilit Kapandı',
    '3': 'Uygulamadan Açıldı',
    '4': 'Tuş Takımından Açıldı',
    '5': 'Parmak İzinden Açıldı',
    '6': 'Karttan Açıldı',
    '7': 'Düşük Pil',
    '8': 'Kilit Manipülasyonu',
  };
}

class GatewayConfig {
  //test account ttlock uid,  https://api.ttlock.com/v3/user/getUid
  static int uid = 17498;
  //test account ttlock login password
  static String ttlockLoginPassword = Env.ttlockPassword;

  // custom gateway name
  static String gatewayName = 'My gateway 1';
}

class LockConfig {
  static String lockData = "";
  static String lockMac = "";
}
