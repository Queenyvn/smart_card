import 'package:flutter/material.dart';
import 'user_profile.dart';
import 'menu_page.dart';
import 'calendar_page.dart';
import 'messages_page.dart';  
import 'settings_page.dart';
import 'e_portfolio_page.dart';
import 'qr_code_page.dart';
import 'analytics_page.dart';
import 'scanner_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();  
}

class _HomePageState extends State<HomePage> {
  bool _isHovering = false;
  int _selectedIndex = 0;
  
  /// Mutuals List below the recently interacted carousel
Widget _mutualsList() {
  final List<Map<String, String>> mutuals = [
    {
      'name': 'Dr. Olivia Wilson',
      'title': 'Consultant - Physiotherapy',
      'img': 'assets/profile.jpg',
    },
    {
      'name': 'Jonathan Patterson',
      'title': 'Consultant - Internal Medicine',
      'img': 'assets/profile.jpg',
    },
    {
      'name': 'Athala Odiver',
      'title': 'Marketing Specialist',
      'img': 'assets/profile.jpg',
    },
  ];

  return Column(
    children: mutuals.map((person) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage(person['img']!),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person['title']!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList(),
  );
}


  // Handle navigation when tapping bottom nav items
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        // Home (already here)
        break;
      case 1:
        // Navigate to Calendar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        );
        break;
      case 2:
        // Navigate to Scan
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScannerPage()),
        );
        break;
      case 3:
        // Navigate to Chat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesPage()),
        );
        break;
      case 4:
        // Navigate to Settings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
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
                          // View Profile button with hover effect
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

              ///  SEARCH BAR
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
                  TextButton(
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered)) {
                            return Colors.red;
                          }
                          return Colors.grey;
                        },
                      ),
                    ),
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _dashboardCard(Icons.description, "E-Portfolio", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EPortfolioPage()),
                    );
                  }),
                  _dashboardCard(Icons.qr_code_scanner, "QR Code", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRCodePage()),
                    );
                  }),
                  _dashboardCard(Icons.bar_chart, "Analytics", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsPage()),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              /// RECENTLY INTERACTED USERS
              const Text("Recently Interacted With...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _recentlyInteractedCarousel(context),

              const SizedBox(height: 24),
              const Text("Mutuals",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  _mutualsList(),
            ],
          ),
        ),
      ),

      ///  Bottom Navigation Bar (only in HomePage)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
  Widget _dashboardCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

  /// Recently Interacted Carousel
  Widget _recentlyInteractedCarousel(BuildContext context) {
    final PageController controller = PageController(viewportFraction: 0.85);

    final List<Map<String, String>> people = [
      {
        'name': 'Arjon Fulgencio',
        'role': 'Business Owner',
        'img': 'assets/profile.jpg',
      },
      {
        'name': 'Athala Odiver',
        'role': 'Marketing Specialist',
        'img': 'assets/profile.jpg',
      },
      {
        'name': 'Khyla Diaz',
        'role': 'Tech Entrepreneur',
        'img': 'assets/profile.jpg',
      },
    ];

    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: controller,
        itemCount: people.length,
        itemBuilder: (context, index) {
          final person = people[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: AssetImage(person['img']!),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              person['role']!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserProfilePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "View Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
