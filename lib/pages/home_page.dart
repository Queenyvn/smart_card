import 'package:flutter/material.dart';
import 'user_profile.dart'; // <-- import profile page
import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isHovering = false;
  int _selectedIndex = 0;

  // Handle navigation when tapping bottom nav items
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      // Navigate to Profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserProfilePage()),
      );
    }
    // index 0 = Home (already here)
    // index 2 = placeholder for Settings/Other
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage("assets/profile.jpg"),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Welcome",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text("Mary Jane Araco",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          // 🔽 View Profile button with hover effect
                          MouseRegion(
                            onEnter: (_) =>
                                setState(() => _isHovering = true),
                            onExit: (_) =>
                                setState(() => _isHovering = false),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const UserProfilePage()),
                                );
                              },
                              child: Text(
                                "View Profile",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isHovering
                                      ? Colors.red
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const Icon(Icons.notifications, size: 28),
                ],
              ),
              const SizedBox(height: 20),

              /// 🔍 SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search contacts...",
                    suffixIcon: Icon(Icons.search, color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// 📊 DASHBOARD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Dashboard",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// from other source text button                          
//                  TextButton(
//                    onPressed: () {},
//                    child: Row(
//                      children: const [
//                        Text("Show All", style: TextStyle(color: Colors.red)),
//                        Icon(Icons.arrow_forward_ios,
//                            color: Colors.red, size: 16),
//                      ],
//                    ),
//                  )
// START TO COMMENT HERE FOR BUTTON FROM FLUTTER TEMPLATES
                  TextButton(
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(Colors.transparent), // no splash
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered)) {
                            return Colors.red; // hover color
                            }
                            return Colors.grey; // default color
                        },
                      ),
                    ),
                    // PUSH TO MENU PAGE 
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MenuPage()),
                      );
                    },
                    child: const Text(
                      "Show More",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
//      verticalSpacer,
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _dashboardCard(Icons.description, "E-Portfolio"),
                  _dashboardCard(Icons.qr_code_scanner, "QR Code"),
                  _dashboardCard(Icons.bar_chart, "Analytics"),
                ],
              ),
              const SizedBox(height: 24),

              /// RECENTLY INTERACTED USERS
              const Text("Recently Interacted With...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _contactCard("Juan Dela Cruz", "Business Owner",
                  "assets/profile.jpg"),
              _contactCard("Ana Santos", "Marketing Specialist",
                  "assets/profile.jpg"),
              _contactCard("Carlos Reyes", "Tech Entrepreneur",
                  "assets/profile.jpg"),
            ],
          ),
        ),
      ),

      /// 🔽 Bottom Navigation Bar (only in HomePage)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // <-- keeps icons aligned
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: "Scan",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            ),
        ],
      ),

    );
  }

  /// Dashboard card widget
  Widget _dashboardCard(IconData icon, String title) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Contact card widget
  Widget _contactCard(String name, String role, String imgPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: AssetImage(imgPath)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(role, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

