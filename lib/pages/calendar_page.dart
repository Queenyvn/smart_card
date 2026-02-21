import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../backend/backend.dart';

const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;

  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _posterUrlCtrl = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _descCtrl.dispose();
    _posterUrlCtrl.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  void _showEventDetail(BuildContext context, UpcomingEvent item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EventDetailSheet(item: item),
    );
  }

  void _openAddEventDialog() {
    final slotsCtrl = TextEditingController();

    _titleCtrl.clear();
    _venueCtrl.clear();
    _descCtrl.clear();
    _posterUrlCtrl.clear();
    _eventDate = null;
    _startTime = null;
    _endTime = null;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.grey.shade50,
          title: const Text('Add Event',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputField(_titleCtrl, 'Event Title'),
                const SizedBox(height: 12),
                _inputField(_venueCtrl, 'Venue'),
                const SizedBox(height: 12),
                _inputField(_descCtrl, 'Description', maxLines: 4),
                const SizedBox(height: 12),
                _inputField(_posterUrlCtrl, 'Event Poster URL'),
                const SizedBox(height: 16),
                _tappableField(
                  label: 'Select Date',
                  value: _eventDate == null
                      ? ''
                      : DateFormat('MM/dd/yyyy').format(_eventDate!),
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      initialDate: _eventDate ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => _eventDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tappableField(
                        label: 'Start Time',
                        value: _startTime == null
                            ? ''
                            : _startTime!.format(ctx),
                        icon: Icons.access_time,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: _startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => _startTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tappableField(
                        label: 'End Time',
                        value: _endTime == null ? '' : _endTime!.format(ctx),
                        icon: Icons.access_time,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: _endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => _endTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _inputField(slotsCtrl, 'Available Slots'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cbocPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                if (_eventDate == null ||
                    _startTime == null ||
                    _endTime == null ||
                    slotsCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all fields!')),
                  );
                  return;
                }
                final slots = int.tryParse(slotsCtrl.text);
                if (slots == null || slots <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid number of slots')),
                  );
                  return;
                }

                await BackendService.submitEventForApproval(
                  title: _titleCtrl.text,
                  venue: _venueCtrl.text,
                  description: _descCtrl.text,
                  date: _eventDate!,
                  start: _startTime!,
                  end: _endTime!,
                  posterUrl: _posterUrlCtrl.text.isEmpty
                      ? null
                      : _posterUrlCtrl.text,
                  availableSlots: slots,
                );

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Event submitted for admin approval')),
                );
              },
              child: const Text('Submit',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _tappableField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: Icon(icon),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Calendar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cbocPrimary,
          labelColor: cbocPrimary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'My Submissions'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cbocAccent,
        onPressed: _openAddEventDialog,
        child: const Icon(Icons.add, color: cbocPrimary),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventsTab(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onFocusedDayChanged: (d) => setState(() => _focusedDay = d),
            onSelectedDayChanged: (s, f) => setState(() {
              _selectedDay = s;
              _focusedDay = f;
            }),
            onDayCleared: () => setState(() => _selectedDay = null),
            sameDay: _sameDay,
            sameMonth: _sameMonth,
            onEventTap: _showEventDetail,
          ),
          const _MySubmissionsTab(),
        ],
      ),
    );
  }
}

// ── EVENTS TAB ─────────────────────────────────────────────────────────────────
// Shows ALL approved events + the user's own pending/rejected submissions on the
// same calendar view, clearly labelled with status badges.

class _EventsTab extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime) onFocusedDayChanged;
  final void Function(DateTime, DateTime) onSelectedDayChanged;
  final VoidCallback onDayCleared;
  final bool Function(DateTime, DateTime) sameDay;
  final bool Function(DateTime, DateTime) sameMonth;
  final void Function(BuildContext, UpcomingEvent) onEventTap;

  const _EventsTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.onFocusedDayChanged,
    required this.onSelectedDayChanged,
    required this.onDayCleared,
    required this.sameDay,
    required this.sameMonth,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to both streams simultaneously
    return StreamBuilder<List<UpcomingEvent>>(
      stream: BackendService.approvedEventsStream(),
      builder: (context, approvedSnap) {
        return StreamBuilder<List<UserSubmittedEvent>>(
          stream: BackendService.mySubmittedEventsStream(),
          builder: (context, mySnap) {
            final approvedEvents = approvedSnap.data ?? [];
            final myEvents = mySnap.data ?? [];

            final isLoading =
                approvedSnap.connectionState == ConnectionState.waiting &&
                    approvedEvents.isEmpty;

            // Show user's own events that are: pending, rejected, or
            // cancel_requested. Approved ones already appear in approvedEvents.
            // Cancelled ones are hidden.
            final myVisibleSubmissions = myEvents
                .where((e) =>
                    e.status == 'pending' ||
                    e.status == 'rejected' ||
                    e.status == 'cancel_requested')
                .toList();

            // Build marker map for calendar dots
            final Map<DateTime, List<dynamic>> markerMap = {};
            for (final e in approvedEvents) {
              final key = DateTime(e.date.year, e.date.month, e.date.day);
              markerMap.putIfAbsent(key, () => []).add(e);
            }
            for (final e in myVisibleSubmissions) {
              final key = DateTime(e.date.year, e.date.month, e.date.day);
              markerMap.putIfAbsent(key, () => []).add(e);
            }

            // Filter by selected day / month
            final List<UpcomingEvent> visibleApproved =
                approvedEvents.where((e) {
              if (selectedDay != null) return sameDay(e.date, selectedDay!);
              return sameMonth(e.date, focusedDay);
            }).toList()
                  ..sort((a, b) => a.date.compareTo(b.date));

            final List<UserSubmittedEvent> visibleMine =
                myVisibleSubmissions.where((e) {
              if (selectedDay != null) return sameDay(e.date, selectedDay!);
              return sameMonth(e.date, focusedDay);
            }).toList()
                  ..sort((a, b) => a.date.compareTo(b.date));

            final bool nothingVisible =
                visibleApproved.isEmpty && visibleMine.isEmpty;

            return Column(
              children: [
                // ── CALENDAR ─────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: focusedDay,
                    selectedDayPredicate: (day) =>
                        selectedDay != null && sameDay(day, selectedDay!),
                    eventLoader: (day) {
                      final key = DateTime(day.year, day.month, day.day);
                      return markerMap[key] ?? [];
                    },
                    onDaySelected: (selected, focused) {
                      if (selectedDay != null &&
                          sameDay(selected, selectedDay!)) {
                        onDayCleared();
                      } else {
                        onSelectedDayChanged(selected, focused);
                      }
                    },
                    onPageChanged: (focused) {
                      onFocusedDayChanged(focused);
                      onDayCleared();
                    },
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                          color: cbocAccent, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(
                          color: cbocPrimary, shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(
                          color: cbocSecondary, shape: BoxShape.circle),
                      markerSize: 5,
                      markersMaxCount: 3,
                    ),
                  ),
                ),

                // ── DATE LABEL BAR ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded,
                          size: 16, color: cbocPrimary),
                      const SizedBox(width: 6),
                      Text(
                        selectedDay != null
                            ? DateFormat('MMMM d, yyyy').format(selectedDay!)
                            : DateFormat('MMMM yyyy').format(focusedDay),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cbocPrimary,
                        ),
                      ),
                      if (selectedDay != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: onDayCleared,
                          child: const Text('Show all',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── EVENT LIST ────────────────────────────────────────────
                Expanded(
                  child: isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: cbocPrimary))
                      : nothingVisible
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 48,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    selectedDay != null
                                        ? 'No events on this day'
                                        : 'No events this month',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 10, 12, 80),
                              children: [
                                // ── User's own pending / rejected events ──
                                if (visibleMine.isNotEmpty) ...[
                                  _sectionLabel(
                                      Icons.person_pin_rounded,
                                      'My Submitted Events'),
                                  ...visibleMine.map(
                                      (e) => _SubmittedEventCard(event: e)),
                                  if (visibleApproved.isNotEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 6),
                                      child: Divider(),
                                    ),
                                ],

                                // ── Approved public events ─────────────────
                                if (visibleApproved.isNotEmpty) ...[
                                  if (visibleMine.isNotEmpty)
                                    _sectionLabel(
                                        Icons.event_available_rounded,
                                        'Upcoming Events'),
                                  ...visibleApproved.map(
                                    (item) => _EventCard(
                                      item: item,
                                      onTap: () => onEventTap(context, item),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cbocPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cbocPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SUBMITTED EVENT CARD (calendar tab) ──────────────────────────────────────
// Shows user's pending / rejected / cancel_requested events with status badge
// and a "Cancel Request" button for pending ones.

class _SubmittedEventCard extends StatelessWidget {
  final UserSubmittedEvent event;
  const _SubmittedEventCard({required this.event});

  Color get _color {
    switch (event.status) {
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red.shade700;
      case 'cancel_requested':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (event.status) {
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      case 'cancel_requested':
        return 'Cancellation Requested';
      default:
        return event.status;
    }
  }

  IconData get _icon {
    switch (event.status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancel_requested':
        return Icons.pending_actions_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Submission',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Are you sure you want to cancel "${event.title}"?\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cbocPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result =
                  await BackendService.cancelPendingEvent(event.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result.success
                    ? 'Submission cancelled.'
                    : result.message ?? 'Could not cancel.'),
                backgroundColor:
                    result.success ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(event.date).toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _color),
                      ),
                      Text(
                        DateFormat('d').format(event.date),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Details + status badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_icon, size: 11, color: _color),
                                const SizedBox(width: 3),
                                Text(
                                  _label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _color,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.venue,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            '${event.startTime.format(context)} – ${event.endTime.format(context)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Status footer bar ────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            child: Row(
              children: [
                Icon(_icon, size: 13, color: _color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.status == 'pending'
                        ? 'Awaiting admin approval'
                        : event.status == 'rejected'
                            ? 'This event was not approved by admin'
                            : 'Cancellation pending admin approval',
                    style: TextStyle(fontSize: 11, color: _color),
                  ),
                ),
                // Show cancel button only for pending events
                if (event.status == 'pending')
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.close, size: 13),
                    label: const Text('Cancel Request',
                        style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: cbocPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

// ── MY SUBMISSIONS TAB ────────────────────────────────────────────────────────

class _MySubmissionsTab extends StatelessWidget {
  const _MySubmissionsTab();

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red.shade700;
      case 'cancel_requested':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Rejected';
      case 'cancel_requested':
        return 'Cancellation Requested';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancel_requested':
        return Icons.pending_actions_rounded;
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  void _showEditDialog(BuildContext context, UserSubmittedEvent event) {
    final titleCtrl = TextEditingController(text: event.title);
    final venueCtrl = TextEditingController(text: event.venue);
    final descCtrl = TextEditingController(text: event.description);
    final posterCtrl = TextEditingController(text: event.posterUrl ?? '');
    final slotsCtrl =
        TextEditingController(text: event.availableSlots.toString());
    DateTime selectedDate = event.date;
    TimeOfDay startTime = event.startTime;
    TimeOfDay endTime = event.endTime;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.grey.shade50,
          title: const Text('Edit Event',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _editField(titleCtrl, 'Event Title'),
                const SizedBox(height: 12),
                _editField(venueCtrl, 'Venue'),
                const SizedBox(height: 12),
                _editField(descCtrl, 'Description', maxLines: 4),
                const SizedBox(height: 12),
                _editField(posterCtrl, 'Event Poster URL'),
                const SizedBox(height: 16),
                _tappableEditField(
                  label: 'Date',
                  value: DateFormat('MM/dd/yyyy').format(selectedDate),
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      initialDate: selectedDate,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tappableEditField(
                        label: 'Start Time',
                        value: startTime.format(ctx),
                        icon: Icons.access_time,
                        onTap: () async {
                          final picked = await showTimePicker(
                              context: ctx, initialTime: startTime);
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tappableEditField(
                        label: 'End Time',
                        value: endTime.format(ctx),
                        icon: Icons.access_time,
                        onTap: () async {
                          final picked = await showTimePicker(
                              context: ctx, initialTime: endTime);
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _editField(slotsCtrl, 'Available Slots'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cbocPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                final slots = int.tryParse(slotsCtrl.text.trim());
                if (titleCtrl.text.trim().isEmpty ||
                    venueCtrl.text.trim().isEmpty ||
                    slots == null ||
                    slots <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all fields correctly.')),
                  );
                  return;
                }
                final result = await BackendService.updatePendingEvent(
                  eventId: event.id,
                  title: titleCtrl.text.trim(),
                  venue: venueCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  date: selectedDate,
                  start: startTime,
                  end: endTime,
                  posterUrl: posterCtrl.text.trim().isEmpty
                      ? null
                      : posterCtrl.text.trim(),
                  availableSlots: slots,
                );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.success
                      ? 'Event updated successfully.'
                      : result.message ?? 'Failed to update event.'),
                  backgroundColor:
                      result.success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _tappableEditField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: Icon(icon),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

    void _showCancelDialog(BuildContext context, UserSubmittedEvent event) {
    final bool isPending = event.status == 'pending';
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPending ? 'Cancel Event Submission' : 'Request Cancellation',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPending
                  ? 'Are you sure you want to cancel "${event.title}"? This action cannot be undone.'
                  : 'This event has been approved. Cancellation requires admin approval. Attendees will be notified once approved.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            if (!isPending) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Event'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cbocPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isPending) {
                final result =
                    await BackendService.cancelPendingEvent(event.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.success
                      ? 'Event submission cancelled.'
                      : result.message ?? 'Error cancelling event.'),
                ));
              } else {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please provide a reason.')),
                  );
                  return;
                }
                final result = await BackendService.requestEventCancellation(
                    event.id, reasonCtrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.success
                      ? 'Cancellation request submitted for admin review.'
                      : result.message ?? 'Error submitting request.'),
                ));
              }
            },
            child: Text(
              isPending ? 'Yes, Cancel' : 'Submit Request',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserSubmittedEvent>>(
      stream: BackendService.mySubmittedEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: cbocPrimary));
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'You haven\'t submitted any events yet.',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 80),
          itemCount: events.length,
          itemBuilder: (_, i) {
            final event = events[i];
            final isPast = event.date.isBefore(
                DateTime.now().subtract(const Duration(days: 1)));
            final canCancel = event.status == 'pending' ||
                (event.status == 'approved' && !isPast);
            final canEdit = event.status == 'pending';
            final statusColor = _statusColor(event.status);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(event.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(event.status),
                                size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(event.status),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(event.date),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (event.status == 'pending') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 13, color: Colors.orange),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Awaiting admin approval. You can cancel this submission.',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (event.status == 'cancel_requested') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pending_actions,
                              size: 13, color: Colors.blue),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cancellation pending admin approval.',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ── Action buttons ──────────────────────────────
                  if (canEdit || canCancel) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit button — only for pending events
                        if (canEdit)
                          TextButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, event),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text('Edit Event',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                        // Cancel button — guarded by canCancel
                        if (canCancel)
                          TextButton.icon(
                            onPressed: () =>
                                _showCancelDialog(context, event),
                            icon: const Icon(Icons.close, size: 14),
                            label: Text(
                              event.status == 'pending'
                                  ? 'Cancel Submission'
                                  : 'Request Cancellation',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: cbocPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── APPROVED EVENT CARD ───────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final UpcomingEvent item;
  final VoidCallback onTap;

  const _EventCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = item.event;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: cbocAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMM').format(item.date).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cbocPrimary),
                  ),
                  Text(
                    DateFormat('d').format(item.date),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cbocPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(e.venue,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${e.startTime.format(context)} – ${e.endTime.format(context)}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── EVENT DETAIL BOTTOM SHEET ─────────────────────────────────────────────────

class _EventDetailSheet extends StatefulWidget {
  final UpcomingEvent item;
  const _EventDetailSheet({required this.item});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  bool _isAttending = false;
  bool _loading = true;
  bool _rsvpInProgress = false;

  @override
  void initState() {
    super.initState();
    _checkAttendance();
  }

  Future<void> _checkAttendance() async {
    final attending = await BackendService.isAttendingEvent(widget.item.id);
    if (mounted) setState(() { _isAttending = attending; _loading = false; });
  }

  Future<void> _handleAttend() async {
    if (_isAttending) return;
    setState(() => _rsvpInProgress = true);
    final result = await BackendService.attendEvent(upcomingEvent: widget.item);
    if (mounted) {
      setState(() {
        _rsvpInProgress = false;
        if (result.success) _isAttending = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'You\'re attending "${widget.item.event.title}"!'
            : result.message ?? 'Could not RSVP at this time.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.item.event;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(widget.item.date);
    final timeStr =
        '${e.startTime.format(context)}  –  ${e.endTime.format(context)}';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.zero,
              children: [
                if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: Image.network(e.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  )
                else
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cbocPrimary, cbocSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    child: const Center(
                      child: Icon(Icons.event_rounded,
                          size: 52, color: Colors.white54),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      _infoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: dateStr),
                      const SizedBox(height: 10),
                      _infoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: timeStr),
                      const SizedBox(height: 10),
                      _infoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Venue',
                          value: e.venue),
                      const SizedBox(height: 10),
                      _infoRow(
                          icon: Icons.event_seat_rounded,
                          label: 'Available Slots',
                          value: widget.item.availableSlots.toString()),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('About this event',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cbocPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        e.description.isNotEmpty
                            ? e.description
                            : 'No description provided.',
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF444444)),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: cbocPrimary))
                            : ElevatedButton.icon(
                                onPressed:
                                    _isAttending || _rsvpInProgress
                                        ? null
                                        : _handleAttend,
                                icon: _rsvpInProgress
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: cbocPrimary,
                                            strokeWidth: 2))
                                    : Icon(
                                        _isAttending
                                            ? Icons.check_circle_rounded
                                            : Icons.event_available_rounded,
                                        color: cbocPrimary),
                                label: Text(
                                  _isAttending
                                      ? 'You\'re Attending!'
                                      : 'Attend Event',
                                  style: const TextStyle(
                                      color: cbocPrimary,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAttending
                                      ? Colors.green.shade50
                                      : cbocAccent,
                                  minimumSize:
                                      const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  disabledBackgroundColor:
                                      Colors.green.shade50,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      {required IconData icon,
      required String label,
      required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: cbocAccent, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: cbocPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}