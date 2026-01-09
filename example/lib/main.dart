import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ttlock_flutter/ttlock.dart'; // TTLock SDK import
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ttlock_flutter_example/blocs/auth/auth_bloc.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_event.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_state.dart';
import 'package:ttlock_flutter_example/blocs/ttlock_webhook/ttlock_webhook_bloc.dart';
import 'package:ttlock_flutter_example/services/ttlock_webhook_service.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/home_page.dart';
import 'package:ttlock_flutter_example/ui/pages/login_page.dart';
import 'package:ttlock_flutter_example/ui/pages/splash_page.dart';
import 'package:ttlock_flutter_example/ui/theme.dart';
import 'package:ttlock_flutter_example/l10n/app_localizations.dart';
import 'package:ttlock_flutter_example/locale_provider.dart';
import 'package:ttlock_flutter_example/config.dart' as app_config;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(AppInitialization());
}


class AppInitialization extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // Hata durumunda
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Firebase Başlatma Hatası:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        // Başarılı olursa ana uygulamayı başlat
        if (snapshot.connectionState == ConnectionState.done) {
          final authRepository = AuthRepository();
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => LocaleProvider()),
              RepositoryProvider.value(value: authRepository),
              RepositoryProvider(create: (context) => ApiService(authRepository)),
              BlocProvider(create: (context) => AuthBloc(authRepository)),
              BlocProvider(create: (context) => TTLockWebhookBloc(TTLockWebhookService())),
            ],
            child: MyApp(),
          );
        }

        // Yüklenirken Splash ekranını göster
        return MaterialApp(
          home: SplashPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
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