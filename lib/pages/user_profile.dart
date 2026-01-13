import 'package:flutter/material.dart';
import 'edit_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isHovering = false;

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
      body: Padding(
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
              "Business Owner",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 🔽 Edit Profile button with hover effect
            MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(), // ✅ now loads real one
                    ),
                  );
                },
                child: Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 14,
                    color: _isHovering ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// Example extra details
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
              title: const Text("Tagaytay, Cavite, Philippines"),
            ),
          ],
        ),
      ),
    );
  }
}