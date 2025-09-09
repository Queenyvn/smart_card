import 'package:flutter/material.dart';

// Import your pages
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/edit_profile.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/announcement_page.dart';
import 'pages/messages_page.dart';
import 'pages/about_us_page.dart';
import 'pages/e_portfolio_page.dart';
import 'pages/qr_code_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';
import 'pages/user_profile.dart';

void main() {
  runApp(const SmartCallingCardApp());
}

class SmartCallingCardApp extends StatelessWidget {
  const SmartCallingCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Digital Calling Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red, // CBOC Red Branding
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Start with Login Page
      initialRoute: '/login',

      // Define routes for navigation
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/home': (context) => const HomePage(),
        '/menu': (context) => const MenuPage(),
        '/announcements': (context) => const AnnouncementPage(),
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
