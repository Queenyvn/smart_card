import 'package:flutter/material.dart';

class EPortfolioPage extends StatefulWidget {
  const EPortfolioPage({super.key});

  @override
  State<EPortfolioPage> createState() => _EPortfolioPageState();
}

class _EPortfolioPageState extends State<EPortfolioPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/profile.jpg"),
            ),
            const SizedBox(height: 12),
            const Text(
              "Mary Jane Araco",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Perfume Business Owner",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Perfume de Acre",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "A perfume company focused on designing distinctive, long-lasting fragrances that allow users to express their identity through scent.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            /// Contact & Address
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red),
              title: const Text("maryjane@email.com"),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.red),
              title: const Text("+63 912 345 6789"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text("Block 3 Lot 5, Tejeros Convention, Rosario, Cavite, 4106"),
            ),
          ],
        ),
      ),
    );
  }
}
