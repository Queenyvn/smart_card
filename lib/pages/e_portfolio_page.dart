import 'package:flutter/material.dart';

class EPortfolioPage extends StatelessWidget {
  const EPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("E Portfolio"),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          "E Portfolio will appear here",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
