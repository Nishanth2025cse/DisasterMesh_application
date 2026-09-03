import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DisasterMeshApp());
}

class DisasterMeshApp extends StatelessWidget {
  const DisasterMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.priorityHigh,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const LandingPage() : const SplashScreen(),
    );
  }
}
