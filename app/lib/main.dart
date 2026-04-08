import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialiser Firebase (auth SMS)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser Supabase (données)
  await SupabaseConfig.initialize();

  runApp(const CartelApp());
}

class CartelApp extends StatelessWidget {
  const CartelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isLoggedIn = authService.isLoggedIn;

    return MaterialApp(
      title: 'Cartel Conciergeries',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/complete-profile': (_) => const CompleteProfileScreen(),
      },
    );
  }
}
