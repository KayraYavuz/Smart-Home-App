import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String clientId = (dotenv.env['TTLOCK_CLIENT_ID'] ?? '').trim();
  static String clientSecret = (dotenv.env['TTLOCK_CLIENT_SECRET'] ?? '').trim();
  static String redirectUri = ''; 
  static String username = (dotenv.env['TTLOCK_USERNAME'] ?? '').trim();
  static String password = (dotenv.env['TTLOCK_PASSWORD'] ?? '').trim();
}
  // DEBUG: Test credentials (TTLock test account)
  // Uncomment to test with TTLock test account
  // static String username = 'test@example.com';
  // static String password = 'testpassword';


class TTLockConfig {
  // TTLock Webhook Callback URL (kendi sunucunuzun URL'i)
  // Bu URL, TTLock'un olay bildirimlerini göndereceği endpoint
  static const String webhookCallbackUrl = "https://europe-west3-fenster-berlin-callback.cloudfunctions.net/ttlock-callback";

  // TTLock Webhook Secret (callback doğrulaması için)
  static const String webhookSecret = "your_webhook_secret"; // TTLock portal'dan alın

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
  static String ttlockLoginPassword = (dotenv.env['TTLOCK_PASSWORD'] ?? '111111').trim();

  // custom gateway name
  static String gatewayName = 'My gateway 1';
}

class LockConfig {
  static String lockData = "";
  static String lockMac = "";
}

