import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const YakBiseoApp());
}

class YakBiseoApp extends StatelessWidget {
  const YakBiseoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약비서',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
