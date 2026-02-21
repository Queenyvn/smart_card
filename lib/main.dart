import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // auto-generated

// Import pages
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/notification_page.dart';
import 'pages/messages_page.dart';
import 'pages/about_us_page.dart';
import 'pages/e_portfolio_page.dart';
import 'pages/qr_code_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';
import 'pages/user_profile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Firebase here, inside build
    final Future<FirebaseApp> _firebaseInitialization =
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    return FutureBuilder(
      future: _firebaseInitialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Firebase Initialization Error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return const SmartCallingCardApp(); 
        }

        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}


class SmartCallingCardApp extends StatelessWidget {
  const SmartCallingCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Digital Calling Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/menu': (context) => const MenuPage(),
        '/announcements': (context) => const NotificationPage(),
        '/messages': (context) => const MessagesPage(),
        '/about_us': (context) => const AboutUsPage(),
        '/e_portfolio': (context) => const EPortfolioPage(),
        '/qr_code': (context) => const QRCodePage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/settings': (context) => const SettingsPage(),
        '/user_profile': (context) => const UserProfilePage(),
      },
    );
  }
}
