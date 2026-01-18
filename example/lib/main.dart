import 'package:yavuz_lock/blocs/fingerprint/fingerprint_bloc.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ttlock_flutter/ttlock.dart'; // TTLock SDK import

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_event.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/blocs/ttlock_webhook/ttlock_webhook_bloc.dart';
import 'package:yavuz_lock/blocs/face/face_bloc.dart';
import 'package:yavuz_lock/services/ttlock_webhook_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/home_page.dart';
import 'package:yavuz_lock/ui/pages/login_page.dart';
import 'package:yavuz_lock/ui/pages/splash_page.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/locale_provider.dart';
import 'package:yavuz_lock/config.dart' as app_config;
import 'package:firebase_core/firebase_core.dart'; // Firebase Import
import 'package:yavuz_lock/services/notification_service.dart'; // Bildirim Servisi

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("🏁 Main fonksiyonu başladı."); // DEBUG LOG

  // Firebase Başlatma
  try {
    print("🔥 Firebase.initializeApp() çağrılıyor..."); // DEBUG LOG
    await Firebase.initializeApp();
    print("✅ Firebase başarıyla başlatıldı");
    
    // Bildirim Servisini Başlat
    print("🚀 NotificationService başlatılıyor..."); // DEBUG LOG
    await NotificationService().initialize();
  } catch (e, stackTrace) {
    print("❌ Firebase/Notification başlatma hatası: $e");
    print("Stack Trace: $stackTrace");
    // Hata olsa bile uygulama açılmalı, bu yüzden burayı sessizce geçebiliriz veya loglayabiliriz
  }

  await dotenv.load(fileName: ".env");
  
  print('🚀 Uygulama başlatılıyor...');
  print('📝 .env yüklendi: ${dotenv.env.keys.length} adet anahtar bulundu.');
  print('⚙️  API Config: ClientId=${app_config.ApiConfig.clientId.isNotEmpty ? "OK" : "BOŞ"}, Username=${app_config.ApiConfig.username.isNotEmpty ? "OK" : "BOŞ"}');

  final authRepository = AuthRepository();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider(create: (context) => ApiService(authRepository)),
        RepositoryProvider(create: (context) => TTLockRepository(apiService: context.read<ApiService>())),
        BlocProvider(create: (context) => AuthBloc(authRepository, context.read<ApiService>())..add(AppStarted())),
        BlocProvider(create: (context) => TTLockWebhookBloc(TTLockWebhookService())),
        BlocProvider(create: (context) => FingerprintBloc(context.read<TTLockRepository>(), context.read<ApiService>())),
        BlocProvider(create: (context) => FaceBloc(context.read<TTLockRepository>(), context.read<ApiService>())),
      ],
      child: MyApp(),
    ),
  );
}




class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 2. AŞAMA: TTLock SDK Yapılandırması
    _initializeTTLockSDK();

    // Initialize TTLock Webhook Service
    TTLockWebhookService().startListening(app_config.TTLockConfig.webhookCallbackUrl);

    // Dispatch AppStarted event for AuthBloc
    context.read<AuthBloc>().add(AppStarted());
  }

  void _initializeTTLockSDK() {
     if (Platform.isIOS || Platform.isAndroid) {
      try {
        // 1. SDK Yapılandırması
        TTLock.setupApp(app_config.ApiConfig.clientId, app_config.ApiConfig.clientSecret);
        
        // 2. SDK Durum Kontrolü (Başlangıçta bir kez kontrol et)
        TTLock.getBluetoothState((status) {
          print("✅ TTLock SDK Bluetooth Başlangıç Durumu: $status");
        });

        print('✅ TTLock SDK başarıyla başlatıldı');
      } catch (e) {
        print('❌ TTLock SDK başlatma hatası: $e');
      }
    } else {
      print('ℹ️ TTLock SDK initialization is skipped on this platform (${Platform.operatingSystem}).');
    }
  }

  @override
  void dispose() {
    TTLockWebhookService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      locale: provider.locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''), // English
        const Locale('de', ''), // German
      ],
      theme: AppTheme.darkTheme,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return SplashPage();
          }
          if (state is Authenticated) {
            return HomePage();
          }
          if (state is Unauthenticated) {
            return LoginPage();
          }
          if (state is AuthFailure) {
            return LoginPage(); // Or a custom error page
          }
          return SplashPage();
        },
      ),
    );
  }
}