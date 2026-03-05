import 'package:flutter/material.dart';
import 'user_profile.dart';
import 'notification_page.dart';
import 'scanner_page.dart';
import 'menu_page.dart';
import 'calendar_page.dart';
import 'messages_page.dart';
import 'settings_page.dart';
import 'e_portfolio_page.dart';
import 'qr_code_page.dart';
import 'analytics_page.dart';
import 'scanner_page.dart';
import '../backend/backend.dart';
import 'cavite_map_widget.dart';
import 'post_feed_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = "Loading...";
  String? _userLogoUrl;
  // Key to force-rebuild the entire page when Home is tapped
  Key _pageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await BackendService.fetchUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile['name'] ?? profile['username'] ?? "User";
        _userLogoUrl = profile['logoUrl'];
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Restart home page by refreshing key
      setState(() {
        _selectedIndex = 0;
        _pageKey = UniqueKey();
      });
      _loadUserProfile();
      return;
    }

    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScannerPage()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesPage()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _pageKey,
      backgroundColor: const Color(0xFFF5F5F5),
      body: _HomeBody(
        userName: _userName,
        userLogoUrl: _userLogoUrl,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

// ── MAIN SCROLLABLE BODY ─────────────────────────────────────────────────────
// Uses a CustomScrollView with SliverList so the "Feed" header sticks
// and the posts stream below it in an infinite-scroll pattern.

class _HomeBody extends StatefulWidget {
  final String userName;
  final String? userLogoUrl;

  const _HomeBody({required this.userName, required this.userLogoUrl});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  bool _isHovering = false;

  // ── static content sections ──────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UserProfilePage())),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: widget.userLogoUrl != null
                      ? NetworkImage(widget.userLogoUrl!) as ImageProvider
                      : const AssetImage("assets/profile.jpg"),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome back,",
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(widget.userName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHovering = true),
                    onExit: (_) => setState(() => _isHovering = false),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const UserProfilePage())),
                      child: Text("View Profile",
                          style: TextStyle(
                            fontSize: 12,
                            color: _isHovering ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 28),
                Positioned(
                  right: 0,
                    top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Search contacts...",
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
            suffixIcon: Icon(Icons.search, color: Colors.red, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dashboard",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              TextButton(
                style: ButtonStyle(
                  overlayColor:
                      MaterialStateProperty.all(Colors.transparent),
                  foregroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return states.contains(MaterialState.hovered)
                        ? Colors.red
                        : Colors.grey;
                  }),
                ),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MenuPage())),
                child: const Text("Show More",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dashCard(context, Icons.description, "E-Portfolio",
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EPortfolioPage()))),
              _dashCard(context, Icons.qr_code_scanner, "QR Code",
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRCodePage()))),
              _dashCard(context, Icons.bar_chart, "Analytics",
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashCard(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 95,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.red),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _mapSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const CaviteMapSection(),
    );
  }

  Widget _recentlyInteracted(BuildContext context) {
    final people = [
      {'name': 'Arjon Fulgencio', 'role': 'Business Owner', 'img': 'assets/profile.jpg'},
      {'name': 'Athala Odiver', 'role': 'Marketing Specialist', 'img': 'assets/profile.jpg'},
      {'name': 'Khyla Diaz', 'role': 'Tech Entrepreneur', 'img': 'assets/profile.jpg'},
    ];

    final controller = PageController(viewportFraction: 0.82);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text("Recently Interacted With...",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: PageView.builder(
              controller: controller,
              itemCount: people.length,
              itemBuilder: (context, i) {
                final p = people[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: AssetImage(p['img']!),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(p['role']!,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const UserProfilePage())),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text("View Profile",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutuals() {
    final mutuals = [
      {'name': 'Dr. Olivia Wilson', 'title': 'Consultant - Physiotherapy', 'img': 'assets/profile.jpg'},
      {'name': 'Jonathan Patterson', 'title': 'Consultant - Internal Medicine', 'img': 'assets/profile.jpg'},
      {'name': 'Athala Odiver', 'title': 'Marketing Specialist', 'img': 'assets/profile.jpg'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mutuals",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...mutuals.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(m['img']!),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['name']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(m['title']!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── FEED STICKY HEADER ───────────────────────────────────────────────────

  Widget _feedStickyHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.dynamic_feed_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text("Feed",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Create Post box
          _CreatePostInline(
            userLogoUrl: widget.userLogoUrl,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Post>>(
        stream: BackendService.feedStream(),
        builder: (context, snap) {
          final posts = snap.data ?? [];
          final isLoading =
              snap.connectionState == ConnectionState.waiting && posts.isEmpty;

          // Static "above-fold" content items
          final staticSlivers = <Widget>[
            // Header + search + dashboard in one card group
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _header(context),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _searchBar(),
                  const SizedBox(height: 8),
                  _dashboard(context),
                  const SizedBox(height: 8),
                  _mapSection(),
                  const SizedBox(height: 8),
                  _recentlyInteracted(context),
                  const SizedBox(height: 8),
                  _mutuals(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Sticky Feed header
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyFeedHeader(
                child: _feedStickyHeader(context),
              ),
            ),
          ];

          if (isLoading) {
            return CustomScrollView(
              slivers: [
                ...staticSlivers,
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  ),
                ),
              ],
            );
          }

          if (posts.isEmpty) {
            return CustomScrollView(
              slivers: [
                ...staticSlivers,
                SliverToBoxAdapter(child: _allCaughtUp()),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              ...staticSlivers,
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < posts.length) {
                      return _FeedPostCard(post: posts[index]);
                    }
                    // After all posts
                    return _allCaughtUp();
                  },
                  childCount: posts.length + 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _allCaughtUp() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("You're all caught up!",
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text("No more posts to show right now.",
              style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── STICKY HEADER DELEGATE ───────────────────────────────────────────────────

class _StickyFeedHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyFeedHeader({required this.child});

  @override
  double get minExtent => 130;
  @override
  double get maxExtent => 130;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyFeedHeader oldDelegate) => true;
}

// ── CREATE POST INLINE ───────────────────────────────────────────────────────

class _CreatePostInline extends StatelessWidget {
  final String? userLogoUrl;
  const _CreatePostInline({this.userLogoUrl});

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: userLogoUrl != null
                ? NetworkImage(userLogoUrl!) as ImageProvider
                : const AssetImage('assets/profile.jpg'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openSheet(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text("What's on your mind?",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openSheet(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_outlined,
                  color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CREATE POST BOTTOM SHEET ─────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name;
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    setState(() => _isLoading = true);

    String? imageUrl;
    if (_imageBytes != null && _imageFileName != null) {
      imageUrl =
          await BackendService.uploadPostImage(_imageBytes!, _imageFileName!);
    }

    final result =
        await BackendService.createPost(content: text, imageUrl: imageUrl);
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(result.success ? 'Post shared!' : result.message ?? 'Failed'),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Create Post",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            maxLength: 1000,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5)),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
            ),
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(
                        () { _imageBytes = null; _imageFileName = null; }),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_outlined,
                    color: Colors.red, size: 18),
                label: const Text("Photo",
                    style: TextStyle(color: Colors.red, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(110, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Post",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── FEED POST CARD ────────────────────────────────────────────────────────────

class _FeedPostCard extends StatefulWidget {
  final Post post;

  const _FeedPostCard({required this.post});

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  late bool _liked;
  late int _likesCount;
  bool _showComments = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _liked = widget.post.likedByMe;
    _likesCount = widget.post.likesCount;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _toggleLike() async {
    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });
    await BackendService.toggleLike(widget.post.id, !_liked);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await BackendService.addComment(postId: widget.post.id, content: text);
  }

  void _showLikesPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LikesSheet(postId: widget.post.id),
    );
  }

  void _showAllCommentsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AllCommentsSheet(
        post: widget.post,
        onCommentSubmitted: () => setState(() {}),
      ),
    );
  }

  void _showSharePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ShareSheet(post: widget.post),
    );
  }

  void _showOriginalPostPopup(BuildContext context, Post original) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OriginalPostSheet(originalPost: original),
    );
  }

  @override
  void _showPostOptions(BuildContext context) {
    final isOwner = widget.post.uid == BackendService.currentUid;
    if (!isOwner) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF1976D2)),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                _showEditPostSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text('Are you sure you want to delete this post? This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final result = await BackendService.deletePost(widget.post.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result.success ? 'Post deleted.' : result.message ?? 'Failed'),
                      backgroundColor: result.success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditPostSheet(BuildContext context) {
    final ctrl = TextEditingController(text: widget.post.content);
    bool saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Post', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 6,
                minLines: 3,
                maxLength: 1000,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Edit your post...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                  filled: true, fillColor: const Color(0xFFF9F9F9),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    setS(() => saving = true);
                    final result = await BackendService.editPost(
                      postId: widget.post.id,
                      newContent: ctrl.text,
                    );
                    setS(() => saving = false);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result.success ? 'Post updated!' : result.message ?? 'Failed'),
                        backgroundColor: result.success ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget build(BuildContext context) {
    final post = widget.post;
    final comments = post.comments;
    final previewComments =
        comments.length > 2 ? comments.sublist(0, 2) : comments;
    final hasMore = comments.length > 2;
    final isRepost = post.isRepost && post.originalPost != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Repost banner (sharer label) ──────────────────────────────────
          if (isRepost) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundImage: post.authorLogoUrl != null
                        ? NetworkImage(post.authorLogoUrl!) as ImageProvider
                        : const AssetImage('assets/profile.jpg'),
                  ),
                  const SizedBox(width: 7),
                  Text(post.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF333333))),
                  const SizedBox(width: 5),
                  const Icon(Icons.repeat_rounded,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('shared a post',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Text(_timeAgo(post.createdAt),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ],

          // ── Sharer's caption (if any) ─────────────────────────────────────
          if (isRepost && post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(post.content,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ),

          // ── ORIGINAL POST embedded card ────────────────────────────────────
          if (isRepost)
            _OriginalPostCard(
              original: post.originalPost!,
              timeAgo: _timeAgo,
              onTap: () =>
                  _showOriginalPostPopup(context, post.originalPost!),
            ),

          // ── Normal post: author row ────────────────────────────────────────
          if (!isRepost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.authorLogoUrl != null
                        ? NetworkImage(post.authorLogoUrl!) as ImageProvider
                        : const AssetImage('assets/profile.jpg'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_timeAgo(post.createdAt),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showPostOptions(context),
                    child: const Icon(Icons.more_horiz, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // ── Normal post content ───────────────────────────────────────────
          if (!isRepost && post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(post.content,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ),

          // ── Normal post image ──────────────────────────────────────────────
          if (!isRepost && post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Image.network(post.imageUrl!,
                  fit: BoxFit.cover, width: double.infinity, height: 220),
            ),

          // ── Like + comment count row ──────────────────────────────────────
          if (_likesCount > 0 || comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  if (_likesCount > 0) ...[
                    GestureDetector(
                      onTap: () => _showLikesPopup(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.thumb_up,
                                size: 10, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text('$_likesCount',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (comments.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showAllCommentsPopup(context),
                      child: Text(
                          '${comments.length} comment${comments.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.underline)),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionBtn(
                  icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: 'Like',
                  color: _liked ? Colors.red : Colors.grey,
                  onTap: _toggleLike,
                ),
                _actionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comment',
                  color: Colors.grey,
                  onTap: () =>
                      setState(() => _showComments = !_showComments),
                ),
                _actionBtn(
                  icon: Icons.repeat_rounded,
                  label: 'Share',
                  color: Colors.grey,
                  onTap: () => _showSharePopup(context),
                ),
              ],
            ),
          ),

          // ── Inline comments ───────────────────────────────────────────────
          if (_showComments) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...previewComments.map((c) => _commentTile(c)),
                  if (hasMore)
                    GestureDetector(
                      onTap: () => _showAllCommentsPopup(context),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          'See all ${comments.length} comments',
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  _commentInput(),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _commentTile(PostComment c) {
    final isOwner = c.uid == BackendService.currentUid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 14, backgroundImage: AssetImage('assets/profile.jpg')),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      if (isOwner)
                        GestureDetector(
                          onTap: () => _showCommentOptions(c),
                          child: const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(c.content, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(PostComment c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF1976D2)),
              title: const Text('Edit Comment'),
              onTap: () { Navigator.pop(context); _showEditCommentDialog(c); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Comment', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final result = await BackendService.deleteComment(
                    postId: widget.post.id, commentId: c.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result.success ? 'Comment deleted.' : result.message ?? 'Failed'),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditCommentDialog(PostComment c) {
    final ctrl = TextEditingController(text: c.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final result = await BackendService.editComment(
                postId: widget.post.id,
                commentId: c.id,
                newContent: ctrl.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.success ? 'Comment updated!' : result.message ?? 'Failed'),
                  backgroundColor: result.success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _commentInput() {
    return Row(
      children: [
        const CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/profile.jpg')),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              hintStyle:
                  const TextStyle(fontSize: 12, color: Colors.grey),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.red, size: 16),
                onPressed: _submitComment,
              ),
            ),
            onSubmitted: (_) => _submitComment(),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── ORIGINAL POST EMBEDDED CARD (inside repost) ───────────────────────────────
// Tappable — opens _OriginalPostSheet with full detail + Follow button

class _OriginalPostCard extends StatelessWidget {
  final Post original;
  final String Function(DateTime) timeAgo;
  final VoidCallback onTap;

  const _OriginalPostCard({
    required this.original,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original author header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: original.authorLogoUrl != null
                        ? NetworkImage(original.authorLogoUrl!)
                            as ImageProvider
                        : const AssetImage('assets/profile.jpg'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(original.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(timeAgo(original.createdAt),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Inline Follow hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_outlined,
                            size: 12, color: Colors.red),
                        SizedBox(width: 3),
                        Text('Follow',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            if (original.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  original.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            // Image
            if (original.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    original.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  ),
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── ORIGINAL POST FULL POPUP ──────────────────────────────────────────────────
// Shows the original post in full, with a Follow button on the author

class _OriginalPostSheet extends StatefulWidget {
  final Post originalPost;
  const _OriginalPostSheet({required this.originalPost});

  @override
  State<_OriginalPostSheet> createState() => _OriginalPostSheetState();
}

class _OriginalPostSheetState extends State<_OriginalPostSheet> {
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final following =
        await BackendService.isFollowing(widget.originalPost.uid);
    if (mounted) setState(() => _isFollowing = following);
  }

  Future<void> _toggleFollow() async {
    setState(() => _followLoading = true);
    if (_isFollowing) {
      await BackendService.unfollowUser(widget.originalPost.uid);
    } else {
      await BackendService.followUser(widget.originalPost.uid);
    }
    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followLoading = false;
      });
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.originalPost;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4)),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                // Author + Follow
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: post.authorLogoUrl != null
                          ? NetworkImage(post.authorLogoUrl!)
                              as ImageProvider
                          : const AssetImage('assets/profile.jpg'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(_timeAgo(post.createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    // ── FOLLOW / FOLLOWING button ──────────────────────────
                    GestureDetector(
                      onTap: _followLoading ? null : _toggleFollow,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.grey.shade100
                              : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isFollowing
                                ? Colors.grey.shade300
                                : Colors.red,
                          ),
                        ),
                        child: _followLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.red))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isFollowing
                                        ? Icons.check
                                        : Icons.person_add_outlined,
                                    size: 14,
                                    color: _isFollowing
                                        ? Colors.grey.shade600
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                    style: TextStyle(
                                      color: _isFollowing
                                          ? Colors.grey.shade600
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Content
                if (post.content.isNotEmpty)
                  Text(post.content,
                      style: const TextStyle(fontSize: 15, height: 1.5)),

                // Image
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(post.imageUrl!,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Like / comment counts for original
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.thumb_up,
                          size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('${post.likesCount} likes',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 14),
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text('${post.comments.length} comments',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── LIKES BOTTOM SHEET ────────────────────────────────────────────────────────

class _LikesSheet extends StatefulWidget {
  final String postId;
  const _LikesSheet({required this.postId});

  @override
  State<_LikesSheet> createState() => _LikesSheetState();
}

class _LikesSheetState extends State<_LikesSheet> {
  List<Map<String, dynamic>> _likers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikers();
  }

  Future<void> _fetchLikers() async {
    final likers = await BackendService.fetchPostLikers(widget.postId);
    if (mounted) setState(() { _likers = likers; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.thumb_up, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text('People who liked this',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red))
                : _likers.isEmpty
                    ? const Center(
                        child: Text('No likes yet',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: controller,
                        itemCount: _likers.length,
                        itemBuilder: (_, i) {
                          final person = _likers[i];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage: person['logoUrl'] != null
                                  ? NetworkImage(person['logoUrl'])
                                      as ImageProvider
                                  : const AssetImage('assets/profile.jpg'),
                            ),
                            title: Text(
                              person['name'] ?? person['username'] ?? 'User',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              person['userType'] ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.thumb_up,
                                  size: 12, color: Colors.white),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── ALL COMMENTS BOTTOM SHEET ─────────────────────────────────────────────────

class _AllCommentsSheet extends StatefulWidget {
  final Post post;
  final VoidCallback onCommentSubmitted;
  const _AllCommentsSheet(
      {required this.post, required this.onCommentSubmitted});

  @override
  State<_AllCommentsSheet> createState() => _AllCommentsSheetState();
}

class _AllCommentsSheetState extends State<_AllCommentsSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    _controller.clear();
    await BackendService.addComment(postId: widget.post.id, content: text);
    widget.onCommentSubmitted();
    if (mounted) setState(() => _submitting = false);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text('${comments.length} Comment${comments.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Text('No comments yet. Be the first!',
                        style: TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  AssetImage('assets/profile.jpg'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F3F3),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(c.authorName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text(c.content,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.3)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, top: 4),
                                    child: Text(_timeAgo(c.createdAt),
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // Comment input
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              left: 16, right: 16, top: 10,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle:
                          const TextStyle(fontSize: 13, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      suffixIcon: _submitting
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.red)))
                          : IconButton(
                              icon: const Icon(Icons.send,
                                  color: Colors.red, size: 18),
                              onPressed: _submit,
                            ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SHARE BOTTOM SHEET ────────────────────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final Post post;
  const _ShareSheet({required this.post});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _captionCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _sharePost() async {
    setState(() => _isLoading = true);
    final result = await BackendService.repostPost(
      originalPost: widget.post,
      caption: _captionCtrl.text.trim(),
    );
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            result.success ? 'Post shared to your feed!' : result.message ?? 'Failed'),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.repeat_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Share Post',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Optional caption
          TextField(
            controller: _captionCtrl,
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Add a comment... (optional)',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Colors.red, width: 1.5)),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              counterStyle:
                  const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          // Original post preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: post.authorLogoUrl != null
                          ? NetworkImage(post.authorLogoUrl!) as ImageProvider
                          : const AssetImage('assets/profile.jpg'),
                    ),
                    const SizedBox(width: 8),
                    Text(post.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                if (post.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3)),
                ],
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(post.imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sharePost,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.repeat_rounded,
                      color: Colors.white, size: 18),
              label: Text(_isLoading ? 'Sharing...' : 'Share to Feed',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}