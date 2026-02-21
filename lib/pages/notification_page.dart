import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/backend.dart';

const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  IconData _notifIcon(String type) {
    switch (type) {
      case 'new_event':
        return Icons.event_available_rounded;
      case 'event_approved':
        return Icons.check_circle_rounded;
      case 'event_cancelled':
        return Icons.event_busy_rounded;
      case 'cancel_requested':
        return Icons.pending_actions_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'new_event':
        return cbocPrimary;
      case 'event_approved':
        return Colors.green;
      case 'event_cancelled':
        return Colors.red.shade700;
      case 'cancel_requested':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              await BackendService.markAllNotificationsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All notifications marked as read')),
              );
            },
            child: const Text('Mark all read',
                style: TextStyle(color: cbocPrimary, fontSize: 13)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── UPCOMING EVENTS BANNER SECTION ──────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<UpcomingEvent>>(
              stream: BackendService.recentlyApprovedEventsStream(),
              builder: (context, snapshot) {
                final upcoming = snapshot.data ?? [];
                if (upcoming.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.campaign_rounded,
                              color: cbocPrimary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Upcoming Events',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: cbocPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: upcoming.length,
                        itemBuilder: (_, i) =>
                            _UpcomingEventBanner(event: upcoming[i]),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Divider(),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── IN-APP NOTIFICATIONS ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: cbocPrimary, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cbocPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<List<AppNotification>>(
            stream: BackendService.userNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(color: cbocPrimary)),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No activity yet',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notif = notifications[index];
                    final color = _notifColor(notif.type);
                    final icon = _notifIcon(notif.type);

                    return GestureDetector(
                      onTap: () async {
                        if (!notif.read) {
                          await BackendService.markNotificationRead(
                              notif.id);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: notif.read
                              ? Colors.white
                              : color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: notif.read
                              ? null
                              : Border.all(
                                  color: color.withOpacity(0.2), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 18, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontWeight: notif.read
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (!notif.read)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    notif.body,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeAgo(notif.createdAt),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: notifications.length,
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
    );
  }
}

// ── UPCOMING EVENT BANNER CARD (horizontal scroll) ────────────────────────────

class _UpcomingEventBanner extends StatelessWidget {
  final UpcomingEvent event;

  const _UpcomingEventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event.event;
    final daysUntil = event.date.difference(DateTime.now()).inDays;
    final daysText = daysUntil == 0
        ? 'Today'
        : daysUntil == 1
            ? 'Tomorrow'
            : 'In $daysUntil days';

    // Truncate description
    final shortDesc = e.description.length > 60
        ? '${e.description.substring(0, 60)}...'
        : e.description;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [cbocPrimary, cbocSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysText,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(event.date),
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            e.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            shortDesc.isEmpty ? e.venue : shortDesc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 11, color: Colors.white60),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  e.venue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}