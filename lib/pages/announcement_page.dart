import 'package:flutter/material.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  String _searchQuery = "";

  final List<Map<String, String>> _events = [
    {
      "title": "Digital Business Networking Night",
      "description":
          "An evening of networking with entrepreneurs, startups, and digital professionals."
    },
    {
      "title": "AI for Small Businesses",
      "description":
          "Learn how AI tools can streamline operations and boost productivity."
    },
    {
      "title": "Startup Pitch Day",
      "description":
          "Watch startups pitch ideas to investors and industry leaders."
    },
    {
      "title": "Marketing Strategy Workshop",
      "description":
          "A hands-on session on building high-converting digital campaigns."
    },
    {
      "title": "E-Commerce Growth Summit",
      "description":
          "Discover trends and tools to scale your online store effectively."
    },
    {
      "title": "Leadership & Innovation Forum",
      "description":
          "Insights from leaders on innovation, culture, and growth."
    },
    {
      "title": "Financial Literacy for Entrepreneurs",
      "description":
          "Understand cash flow, budgeting, and smart financial decisions."
    },
    {
      "title": "Branding & Personal Identity Talk",
      "description":
          "Build a strong personal and business brand in the digital age."
    },
    {
      "title": "Tech & Networking Mixer",
      "description":
          "Casual mixer for tech founders, developers, and creatives."
    },
    {
      "title": "Future of Digital Communities",
      "description":
          "A discussion on how digital platforms shape business communities."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _events.where((event) {
      return event["title"]!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Events"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ///  SEARCH BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search events...",
                  suffixIcon: Icon(Icons.search, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// EVENT LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _EventCard(
                    title: event["title"]!,
                    description: event["description"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String description;

  const _EventCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          /// 30% IMAGE
          Container(
            width: MediaQuery.of(context).size.width * 0.3 - 16,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              image: DecorationImage(
                image: AssetImage("assets/event.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// 70% DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Attend",
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
        ],
      ),
    );
  }
} 
