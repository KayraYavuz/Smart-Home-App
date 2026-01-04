import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_bloc.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_event.dart';
import 'package:ttlock_flutter_example/blocs/auth/auth_state.dart';
import 'package:ttlock_flutter_example/blocs/webhook/webhook_bloc.dart';
import 'package:ttlock_flutter_example/blocs/ttlock_webhook/ttlock_webhook_bloc.dart';
import 'package:ttlock_flutter_example/services/ttlock_webhook_service.dart';
import 'package:ttlock_flutter_example/api_service.dart';
import 'package:ttlock_flutter_example/repositories/auth_repository.dart';
import 'package:ttlock_flutter_example/home_page.dart';
import 'package:ttlock_flutter_example/ui/pages/login_page.dart';
import 'package:ttlock_flutter_example/ui/pages/splash_page.dart';
import 'package:ttlock_flutter_example/ui/theme.dart';
import 'package:ttlock_flutter_example/l10n/app_localizations.dart';
import 'package:ttlock_flutter_example/locale_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        BlocProvider(create: (context) => AuthBloc(AuthRepository())),
        BlocProvider(create: (context) => WebhookBloc(WebhookService.instance)),
        BlocProvider(create: (context) => TTLockWebhookBloc(TTLockWebhookService.instance)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
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
      theme: darkTheme,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // AuthBloc'u başlat
          context.read<AuthBloc>().add(AppStarted());

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