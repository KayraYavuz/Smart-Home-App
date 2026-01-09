import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // IMPORTANT: Replace with your own client_id from TTLock developer portal
  static String clientId = dotenv.env['TTLOCK_CLIENT_ID'] ?? '';
  // IMPORTANT: Replace with your own client_secret from TTLock developer portal
  static String clientSecret = dotenv.env['TTLOCK_CLIENT_SECRET'] ?? '';
  // IMPORTANT: Replace with your redirect_uri from TTLock developer portal (must match exactly)
  // If you get error 10007, try setting this to empty string: ''
  // Many portals don't require redirect_uri for password grant type
  // Common values: 'https://api.ttlock.com/oauth2/callback' or 'https://euapi.ttlock.com/oauth2/callback'
  static String redirectUri = ''; // Try empty first, add if portal requires it

  // IMPORTANT: Replace with your REAL TTLock account credentials
  // Username can be email or phone number (with country code, e.g., +905551234567)
  static String username = dotenv.env['TTLOCK_USERNAME'] ?? '';
  // Password will be MD5 hashed automatically - TTLock web sitesindeki gerçek şifrenizi yazın
  static String password = dotenv.env['TTLOCK_PASSWORD'] ?? ''; // BU ŞİFREYI KONTROL EDİN!

  // DEBUG: Test credentials (TTLock test account)
  // Uncomment to test with TTLock test account
  // static String username = 'test@example.com';
  // static String password = 'testpassword';
}

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

class SeamConfig {
  // Seam Sandbox API Anahtarı
  static String seamApiKey = dotenv.env['SEAM_API_KEY'] ?? "";

  // Seam API Base URL
  static const String baseUrl = "https://connect.getseam.com";

  // Webhook Secret (üretim ortamında güvenli bir yerden alınmalı)
  static const String webhookSecret = "your_webhook_secret_here";
}

class GatewayConfig {
  //test account ttlock uid,  https://api.ttlock.com/v3/user/getUid
  static int uid = 17498;
  //test account ttlock login password
  static String ttlockLoginPassword = dotenv.env['TTLOCK_PASSWORD'] ?? '111111';

  // custom gateway name
  static String gatewayName = 'My gateway 1';
}

class LockConfig {
  static String lockData = "";
  static String lockMac = "";
}

