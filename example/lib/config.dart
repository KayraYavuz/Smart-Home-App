class ApiConfig {
  // IMPORTANT: Replace with your own client_id from TTLock developer portal
  static String clientId = '71d83b61847a4e159001e7d98df71952';
  // IMPORTANT: Replace with your own client_secret from TTLock developer portal
  static String clientSecret = 'e51c0a87a2854053983509b630b21894';
  // IMPORTANT: Replace with your redirect_uri from TTLock developer portal (must match exactly)
  // If you get error 10007, try setting this to empty string: ''
  // Many portals don't require redirect_uri for password grant type
  // Common values: 'https://api.ttlock.com/oauth2/callback' or 'https://euapi.ttlock.com/oauth2/callback'
  static String redirectUri = ''; // Try empty first, add if portal requires it

  // IMPORTANT: Replace with your REAL TTLock account credentials
  // Username can be email or phone number (with country code, e.g., +905551234567)
  static String username = 'ahmetkayrayavuz@gmail.com';
  // Password will be MD5 hashed automatically
  static String password = 'Basaksehir180604';
}

class TTLockConfig {
  // TTLock Webhook Callback URL (kendi sunucunuzun URL'i)
  // Bu URL, TTLock'un olay bildirimlerini göndereceği endpoint
  static const String webhookCallbackUrl = "https://your-server.com/api/ttlock/webhook";

  // TTLock Webhook Secret (callback doğrulaması için)
  static const String webhookSecret = "your_ttlock_webhook_secret";

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
  static const String seamApiKey = "seam_testVYUG_4XPSRdR42pbuCFf33Yhvmx8t";

  // Seam API Base URL
  static const String baseUrl = "https://connect.getseam.com";

  // Webhook Secret (üretim ortamında güvenli bir yerden alınmalı)
  static const String webhookSecret = "your_webhook_secret_here";
}

class GatewayConfig {
  //test account ttlock uid,  https://api.ttlock.com/v3/user/getUid
  static int uid = 17498;
  //test account ttlock login password
  static String ttlockLoginPassword = '111111';
  // custom gateway name
  static String gatewayName = 'My gateway 1';
}

class LockConfig {
  static String lockData = "";
  static String lockMac = "";
}

