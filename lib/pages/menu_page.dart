import 'package:flutter/material.dart';
import 'edit_profile.dart';

// Import placeholder pages (create these in /pages/)
import 'announcement_page.dart';
import 'messages_page.dart';
import 'about_us_page.dart';
import 'e_portfolio_page.dart';
import 'qr_code_page.dart';
import 'analytics_page.dart';
import 'settings_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // ✅ Back to previous page
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// === PROFILE SECTION ===
              Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage("assets/profile.jpg"),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mary Jane Araco",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 🔽 Edit Profile link with hover effect
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHovering = true),
                        onExit: (_) => setState(() => _isHovering = false),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 13,
                              color: _isHovering ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// === MENU LIST ===
              Expanded(
                child: ListView(
                  children: [
                    _menuItem(Icons.campaign, "Announcements", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnnouncementPage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.message, "Messages", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessagesPage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.info, "About Us", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsPage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.description, "E-Portfolio", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EPortfolioPage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.qr_code_scanner, "QR Code", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRCodePage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.bar_chart, "Analytics", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnalyticsPage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.settings, "Settings", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              /// === SIGN OUT BUTTON ===
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add logout functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Sign Out",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// === Reusable Menu Item Widget ===
  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.red),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(thickness: 0.8, height: 0),
      ],
    );
  }
}
