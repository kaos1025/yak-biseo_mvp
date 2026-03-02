import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'firebase_options.dart';

import 'package:myapp/core/service_locator.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 서비스 로케이터 및 로컬 DB 초기화
  await setupServiceLocator();

  runApp(const YakBiseoApp());
}

class YakBiseoApp extends StatelessWidget {
  const YakBiseoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [routeObserver],
      home: const HomeScreen(),
    );
  }
}
