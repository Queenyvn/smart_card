import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          "About Us",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // ✅ Back button
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER IMAGE (optional)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage("assets/about_banner.jpg"), // <-- Add a banner image in assets
                  fit: BoxFit.cover,
                ),
              ),
            ), 
            const SizedBox(height: 20),

            /// SECTION TITLE
            const Text(
              "Cavite Business Owners Club (CBOC)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),

            /// ABOUT US DESCRIPTION (from your prototype)
            const Text(
              "The Cavite Business Owners Club (CBOC) is a professional community "
              "of entrepreneurs, innovators, and business leaders across Cavite. "
              "Our mission is to foster collaboration, networking, and growth by "
              "providing a platform for business owners to share knowledge, build "
              "connections, and support each other’s ventures.\n\n"
              "Through events, digital platforms, and partnerships, we aim to "
              "empower Cavite-based businesses to thrive in today’s competitive "
              "marketplace while creating a positive impact in our local economy.",
              style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),

            /// VISION & MISSION SECTION
            const Text(
              "Our Vision",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "To become the leading business community in Cavite that empowers "
              "entrepreneurs and promotes sustainable growth.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              "Our Mission",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "To connect, support, and uplift Cavite-based business owners "
              "through networking opportunities, learning platforms, and "
              "collaborative initiatives that drive success and innovation.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
