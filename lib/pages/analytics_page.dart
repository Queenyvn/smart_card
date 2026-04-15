import 'package:flutter/material.dart';
import '../backend/backend.dart';
import 'e_portfolio_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // ── Connection count (fetched once on init) ──────────────────────────────
  int _connectionCount = 0;
  bool _countLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectionCount();
  }

  Future<void> _loadConnectionCount() async {
    final count = await BackendService.fetchConnectionCount();
    if (mounted) {
      setState(() {
        _connectionCount = count;
        _countLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Analytics"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== SUMMARY =====
            Row(
              children: [
                _summaryCard(
                  title: "Total Visits",
                  value: "129",
                  icon: Icons.remove_red_eye,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  title: "This Month",
                  value: "42",
                  icon: Icons.calendar_month,
                ),
                const SizedBox(width: 12),
                // ── Connections summary card — live from Firestore ──
                _countLoading
                    ? Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _cardDecoration(),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red),
                            ),
                          ),
                        ),
                      )
                    : _summaryCard(
                        title: "Connections",
                        value: "$_connectionCount",
                        icon: Icons.people_outline_rounded,
                      ),
              ],
            ),

            const SizedBox(height: 24),

            // ===== TAP MONITORING GRAPH =====
            Text(
              "Tap Monitoring (Weekly)",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Taps This Week",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BAR GRAPH
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _TapBar(day: "Mon", value: 30),
                        _TapBar(day: "Tue", value: 45),
                        _TapBar(day: "Wed", value: 20),
                        _TapBar(day: "Thu", value: 60),
                        _TapBar(day: "Fri", value: 80),
                        _TapBar(day: "Sat", value: 40),
                        _TapBar(day: "Sun", value: 55),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== CONNECTIONS SECTION — live from Firestore ================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Connections",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                // ── Live count badge ──
                if (!_countLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "$_connectionCount connected",
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── StreamBuilder feeds live accepted connections ──
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: BackendService.myConnectionsStream(),
              builder: (context, snap) {
                // Loading state
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Colors.red, strokeWidth: 2),
                    ),
                  );
                }

                final connections = snap.data ?? [];

                // Empty state
                if (connections.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 44, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text(
                          "No connections yet",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Connect with other members to grow your network.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black38, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // ── Connected members list ──
                return Column(
                  children: connections.map((member) {
                    final name = member['name'] as String? ?? 'Member';
                    final userType =
                        member['userType'] as String? ?? 'CBOC Member';
                    final logoUrl = member['logoUrl'] as String?;
                    final uid = member['uid'] as String? ?? '';
                    final connectionId =
                        member['connectionId'] as String? ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          // ── Avatar — tappable to view their e-portfolio ──
                          GestureDetector(
                            onTap: uid.isNotEmpty
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MemberEPortfolioPage(
                                            memberUid: uid),
                                      ),
                                    )
                                : null,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.red.shade100,
                              backgroundImage: logoUrl != null
                                  ? NetworkImage(logoUrl) as ImageProvider
                                  : null,
                              child: logoUrl == null
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ── Name + role — tappable to view e-portfolio ──
                          Expanded(
                            child: GestureDetector(
                              onTap: uid.isNotEmpty
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MemberEPortfolioPage(
                                              memberUid: uid),
                                        ),
                                      )
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userType,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Connected badge + disconnect option ──
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Connected badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.shade200),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 11, color: Colors.green),
                                    SizedBox(width: 3),
                                    Text(
                                      'Connected',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // ── 3-dot options menu ──
                              GestureDetector(
                                onTap: () => _showConnectionOptions(
                                    context, name, connectionId, uid),
                                child: const Icon(Icons.more_vert,
                                    size: 18, color: Colors.black38),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ===== RECENTLY INTERACTED =====
            Text(
              "Recently Interacted With",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            _recentItem(
              name: "Arjon Fulgencio",
              subtitle: "Business Owner",
            ),
            _recentItem(
              name: "Athala Odiver",
              subtitle: "Marketing Specialist",
            ),
            _recentItem(
              name: "Khyla Diaz",
              subtitle: "Tech Entrepreneur",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Options sheet for a connection (view portfolio / disconnect) ──────────
  void _showConnectionOptions(
      BuildContext context, String name, String connectionId, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            // View portfolio
            if (uid.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.person_outline, color: Color(0xFF1976D2)),
                title: const Text('View E-Portfolio'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberEPortfolioPage(memberUid: uid),
                    ),
                  );
                },
              ),
            // Disconnect
            ListTile(
              leading:
                  const Icon(Icons.link_off_rounded, color: Colors.red),
              title: Text('Disconnect from $name',
                  style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                // Confirm before removing
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Disconnect'),
                    content: Text(
                        'Are you sure you want to disconnect from $name?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Disconnect',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final result =
                      await BackendService.removeConnection(uid);
                  // Refresh connection count
                  _loadConnectionCount();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result.success
                          ? 'Disconnected from $name.'
                          : result.message ?? 'Failed'),
                      backgroundColor:
                          result.success ? Colors.green : Colors.red,
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

  // ===== SUMMARY CARD =====
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: Colors.black54),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== RECENT ITEM =====
  Widget _recentItem({
    required String name,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    );
  }

  // ===== CARD STYLE =====
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// ===== BAR COMPONENT =====
class _TapBar extends StatelessWidget {
  final String day;
  final double value;

  const _TapBar({
    required this.day,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: value,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}