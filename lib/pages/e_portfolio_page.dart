import 'package:flutter/material.dart';
import 'user_profile.dart';

class EPortfolioPage extends StatelessWidget {
  const EPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    // redirects to profile page //
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfilePage(),
        ),
      );
    });

    // Keep an empty scaffold while navigation occurs
    return const Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
    );
  }
}
