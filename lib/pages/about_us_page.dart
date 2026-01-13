import 'package:flutter/material.dart';

/// BRAND COLORS
const Color kBrandRed = Color(0xFFFF3B30);
const Color kLightBackground = Color(0xFFF4F6FB);
const Color kDarkBackground = Color(0xFF121212);
const Color kCardLight = Colors.white;
const Color kCardDark = Color(0xFF1E1E1E);

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabContent(String title, String body) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? kCardDark
            : kCardLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackground : kLightBackground,
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
           
           
            // Top header with curved background
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.black87, Colors.black]
                          : [kBrandRed.withOpacity(0.1), kLightBackground],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      "assets/logo.png",
                      height: 120,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  right: 24,
                  child: Text(
                    "Cavite Business\nOwners Club",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            // Tab Navigation
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                indicatorColor: kBrandRed,
                labelColor: kBrandRed,
                unselectedLabelColor:
                    isDark ? Colors.white70 : Colors.black54,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Vision'),
                  Tab(text: 'Mission'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(
                    "About Us",
                    "The Cavite Business Owners Club (CBOC) is a professional community of entrepreneurs, innovators, and business leaders. It is dedicated to fostering collaboration, growth, and mutual support among Cavite-based business owners.\n\nThrough shared learning, networking opportunities, and meaningful partnerships, CBOC aims to strengthen local businesses and build a sustainable entrepreneurial ecosystem.",
                  ),
                  _buildTabContent(
                    "Our Vision",
                    "To become the leading platform for Cavite entrepreneurs to connect, collaborate, and grow their businesses while uplifting the community and fostering sustainable economic development.",
                  ),
                  _buildTabContent(
                    "Our Mission",
                    "To empower business owners through mentorship, collaboration, and networking opportunities, creating value-driven engagement that benefits both businesses and communities.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
