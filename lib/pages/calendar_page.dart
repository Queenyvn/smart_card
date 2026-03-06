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
  // 3 tabs: Events | My Schedule | My Submissions
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
    _tabController = TabController(length: 3, vsync: this);
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

  /// Opens History as a full-screen slide-in page — no separate file needed.
  void _openHistoryPage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const _HistoryPage(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
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
                        content:
                            Text('Please enter a valid number of slots')),
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
        actions: [
          IconButton(
            tooltip: 'Event History',
            onPressed: () => _openHistoryPage(context),
            icon: Container(
              child: const Icon(Icons.history_rounded,
                  color: Colors.grey, size: 20),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cbocPrimary,
          labelColor: cbocPrimary,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'My Schedule'),
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
          const _MyScheduleTab(),
          const _MySubmissionsTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// HISTORY PAGE — full-screen slide-in, no separate file
// =============================================================================

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Event History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: const _HistoryBody(),
    );
  }
}

// =============================================================================
// EVENTS TAB
// =============================================================================

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
    return StreamBuilder<List<UpcomingEvent>>(
      stream: BackendService.approvedEventsStream(),
      builder: (context, approvedSnap) {
        return StreamBuilder<List<UserSubmittedEvent>>(
          stream: BackendService.mySubmittedEventsStream(),
          builder: (context, mySnap) {
            return StreamBuilder<List<AttendedEvent>>(
              stream: BackendService.myScheduleStream(),
              builder: (context, scheduleSnap) {
                final approvedEvents = approvedSnap.data ?? [];
                final myEvents = mySnap.data ?? [];
                final myRsvpEvents = scheduleSnap.data ?? [];

                final isLoading =
                    approvedSnap.connectionState == ConnectionState.waiting &&
                        approvedEvents.isEmpty;

                final myVisibleSubmissions = myEvents
                    .where((e) =>
                        e.status == 'pending' ||
                        e.status == 'rejected' ||
                        e.status == 'cancel_requested')
                    .toList();

                final Map<DateTime, List<dynamic>> markerMap = {};
                for (final e in approvedEvents) {
                  final key = DateTime(e.date.year, e.date.month, e.date.day);
                  markerMap.putIfAbsent(key, () => []).add(e);
                }
                for (final e in myVisibleSubmissions) {
                  final key = DateTime(e.date.year, e.date.month, e.date.day);
                  markerMap.putIfAbsent(key, () => []).add(e);
                }

                final Set<DateTime> rsvpDays = myRsvpEvents
                    .map((e) =>
                        DateTime(e.date.year, e.date.month, e.date.day))
                    .toSet();

                final List<UpcomingEvent> visibleApproved =
                    approvedEvents.where((e) {
                  if (selectedDay != null)
                    return sameDay(e.date, selectedDay!);
                  return sameMonth(e.date, focusedDay);
                }).toList()
                      ..sort((a, b) => a.date.compareTo(b.date));

                final List<UserSubmittedEvent> visibleMine =
                    myVisibleSubmissions.where((e) {
                  if (selectedDay != null)
                    return sameDay(e.date, selectedDay!);
                  return sameMonth(e.date, focusedDay);
                }).toList()
                      ..sort((a, b) => a.date.compareTo(b.date));

                final bool nothingVisible =
                    visibleApproved.isEmpty && visibleMine.isEmpty;

                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) =>
                            selectedDay != null && sameDay(day, selectedDay!),
                        eventLoader: (day) {
                          final key =
                              DateTime(day.year, day.month, day.day);
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
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            final key =
                                DateTime(day.year, day.month, day.day);
                            final hasEvents =
                                (markerMap[key] ?? []).isNotEmpty;
                            final isRsvpd = rsvpDays.contains(key);
                            if (!hasEvents && !isRsvpd)
                              return const SizedBox();
                            return Positioned(
                              bottom: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasEvents)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: cbocSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (isRsvpd)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Legend
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          _dot(cbocSecondary),
                          const SizedBox(width: 4),
                          Text('Events',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                          _dot(Colors.green.shade500),
                          const SizedBox(width: 4),
                          Text('My RSVP',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
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
                                ? DateFormat('MMMM d, yyyy')
                                    .format(selectedDay!)
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: cbocPrimary))
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
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 10, 12, 80),
                                  children: [
                                    if (visibleMine.isNotEmpty) ...[
                                      _sectionLabel(
                                          Icons.person_pin_rounded,
                                          'My Submitted Events'),
                                      ...visibleMine.map((e) =>
                                          _SubmittedEventCard(event: e)),
                                      if (visibleApproved.isNotEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 6),
                                          child: Divider(),
                                        ),
                                    ],
                                    if (visibleApproved.isNotEmpty) ...[
                                      if (visibleMine.isNotEmpty)
                                        _sectionLabel(
                                            Icons.event_available_rounded,
                                            'Upcoming Events'),
                                      ...visibleApproved.map(
                                        (item) => _EventCard(
                                          item: item,
                                          onTap: () =>
                                              onEventTap(context, item),
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
      },
    );
  }

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _sectionLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cbocPrimary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cbocPrimary)),
        ],
      ),
    );
  }
}

// =============================================================================
// MY SCHEDULE TAB
// =============================================================================

class _MyScheduleTab extends StatelessWidget {
  const _MyScheduleTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<List<AttendedEvent>>(
      stream: BackendService.myScheduleStream(),
      builder: (context, snap) {
        final schedule = snap.data ?? [];
        final isLoading =
            snap.connectionState == ConnectionState.waiting && schedule.isEmpty;

        final thisMonth = schedule
            .where(
                (e) => e.date.year == now.year && e.date.month == now.month)
            .toList();

        final later = schedule
            .where((e) =>
                e.date.isAfter(DateTime(now.year, now.month + 1, 0)))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded,
                      color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(now),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green.shade700),
                      ),
                      Text(
                        '${thisMonth.length} event${thisMonth.length == 1 ? '' : 's'} this month',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                  child: CircularProgressIndicator(color: cbocPrimary))
            else if (schedule.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 52, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No upcoming events',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('RSVP to events in the Events tab',
                        style: TextStyle(
                            color: Colors.grey.shade300, fontSize: 12)),
                  ],
                ),
              ),
            ] else ...[
              if (thisMonth.isNotEmpty)
                _scheduleSection('This Month', thisMonth, context),
              if (later.isNotEmpty) ...[
                const SizedBox(height: 16),
                _scheduleSection('Coming Up', later, context),
              ],
              if (thisMonth.isEmpty && later.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'No events scheduled this month',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _scheduleSection(
      String title, List<AttendedEvent> events, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5)),
        ),
        ...events.map((e) => _ScheduleListItem(event: e)),
      ],
    );
  }
}

class _ScheduleListItem extends StatelessWidget {
  final AttendedEvent event;
  const _ScheduleListItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntil = event.date.difference(today).inDays;

    final urgencyColor = daysUntil == 0
        ? Colors.orange.shade700
        : daysUntil <= 3
            ? Colors.amber.shade700
            : Colors.green.shade600;

    final urgencyBg = daysUntil == 0
        ? Colors.orange.shade50
        : daysUntil <= 3
            ? Colors.amber.shade50
            : Colors.green.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: urgencyColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: urgencyBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(event.date).toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: urgencyColor),
                  ),
                  Text(
                    DateFormat('d').format(event.date),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: urgencyColor),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(event.eventTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: urgencyBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            daysUntil == 0
                                ? 'Today!'
                                : daysUntil == 1
                                    ? 'Tomorrow'
                                    : 'In $daysUntil days',
                            style: TextStyle(
                                fontSize: 10,
                                color: urgencyColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(event.venue,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
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

// =============================================================================
// HISTORY BODY — content used inside _HistoryPage
// =============================================================================

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendedEvent>>(
      stream: BackendService.attendedEventsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: cbocPrimary));
        }

        final all = snap.data ?? [];

        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No event history yet.',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Events you RSVP to will appear here.',
                    style: TextStyle(
                        color: Colors.grey.shade300, fontSize: 12)),
              ],
            ),
          );
        }

        final upcoming = all.where((e) => !e.isPast).toList();
        final past = all.where((e) => e.isPast).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 80),
          children: [
            if (upcoming.isNotEmpty) ...[
              _sectionHeader(
                  Icons.upcoming_rounded, 'Upcoming', Colors.blue.shade700),
              ...upcoming.map((e) => _HistoryCard(event: e)),
              const SizedBox(height: 8),
            ],
            if (past.isNotEmpty) ...[
              _sectionHeader(
                  Icons.history_rounded, 'Past Events', cbocPrimary),
              ...past.map((e) => _HistoryCard(event: e)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AttendedEvent event;
  const _HistoryCard({required this.event});

  void _openFeedbackSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _FeedbackSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPast = event.isPast;
    final needsFeedback = isPast && !event.feedbackSubmitted;
    final statusColor = isPast
        ? (event.feedbackSubmitted
            ? Colors.green.shade600
            : Colors.grey.shade500)
        : Colors.blue.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade100
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(event.date).toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                      Text(
                        DateFormat('d').format(event.date),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                      Text(
                        DateFormat('yyyy').format(event.date),
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.eventTitle,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color:
                                  isPast ? Colors.black87 : Colors.black)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(event.venue,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _StatusPill(event: event),
                      if (event.feedbackSubmitted &&
                          event.rating != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < event.rating!
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (needsFeedback)
                  Tooltip(
                    message: 'Rate & Review',
                    child: GestureDetector(
                      onTap: () => _openFeedbackSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: cbocAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rate_review_outlined,
                            size: 16, color: cbocPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (event.feedbackSubmitted &&
              event.feedback != null &&
              event.feedback!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded,
                      size: 14, color: Colors.grey.shade300),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.feedback!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (needsFeedback) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Not yet reviewed',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ),
                  GestureDetector(
                    onTap: () => _openFeedbackSheet(context),
                    child: Text('Leave a review',
                        style: TextStyle(
                            fontSize: 11,
                            color: cbocPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final AttendedEvent event;
  const _StatusPill({required this.event});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    if (!event.isPast) {
      color = Colors.blue.shade600;
      icon = Icons.event_available_rounded;
      label = 'RSVP Confirmed';
    } else if (event.feedbackSubmitted) {
      color = Colors.green.shade600;
      icon = Icons.check_circle_rounded;
      label = 'Attended';
    } else {
      color = Colors.grey.shade500;
      icon = Icons.help_outline_rounded;
      label = 'Attended';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// FEEDBACK BOTTOM SHEET
// =============================================================================

class _FeedbackSheet extends StatefulWidget {
  final AttendedEvent event;
  const _FeedbackSheet({required this.event});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final _feedbackCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await BackendService.submitAttendanceFeedback(
      attendanceId: widget.event.id,
      rating: _rating,
      feedback: _feedbackCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _submitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'Thank you for your feedback!'
            : result.message ?? 'Failed to submit.'),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate & Review',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(widget.event.eventTitle,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('How would you rate this event?',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    _rating >= starIndex
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 40,
                    color: _rating >= starIndex
                        ? Colors.amber.shade500
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent!'][_rating],
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackCtrl,
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)...',
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: cbocPrimary, width: 1.5)),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              counterStyle:
                  const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: cbocPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Review',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =============================================================================
// MY SUBMISSIONS TAB
// =============================================================================

class _MySubmissionsTab extends StatelessWidget {
  const _MySubmissionsTab();

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'cancel_requested':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.grey.shade500;
      default:
        return Colors.orange.shade700;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'cancel_requested':
        return 'Cancel Requested';
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

  void _showCancelDialog(BuildContext context, UserSubmittedEvent event) {
    final bool isPending = event.status == 'pending';
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPending ? 'Cancel Submission' : 'Request Cancellation',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPending
                  ? 'Are you sure you want to cancel "${event.title}"? This cannot be undone.'
                  : 'This event is approved. Cancellation requires admin review. Attendees will be notified.',
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
              child: const Text('Keep Event')),
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
                      ? 'Submission cancelled.'
                      : result.message ?? 'Error.'),
                ));
              } else {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please provide a reason.')),
                  );
                  return;
                }
                final result =
                    await BackendService.requestEventCancellation(
                        event.id, reasonCtrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.success
                      ? 'Cancellation request submitted.'
                      : result.message ?? 'Error.'),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.grey.shade50,
          title: const Text('Edit Event',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(titleCtrl, 'Event Title'),
                const SizedBox(height: 12),
                _field(venueCtrl, 'Venue'),
                const SizedBox(height: 12),
                _field(descCtrl, 'Description', maxLines: 4),
                const SizedBox(height: 12),
                _field(posterCtrl, 'Event Poster URL'),
                const SizedBox(height: 16),
                _tapField(
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
                    if (picked != null)
                      setDialogState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _tapField(
                      label: 'Start',
                      value: startTime.format(ctx),
                      icon: Icons.access_time,
                      onTap: () async {
                        final p = await showTimePicker(
                            context: ctx, initialTime: startTime);
                        if (p != null) setDialogState(() => startTime = p);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tapField(
                      label: 'End',
                      value: endTime.format(ctx),
                      icon: Icons.access_time,
                      onTap: () async {
                        final p = await showTimePicker(
                            context: ctx, initialTime: endTime);
                        if (p != null) setDialogState(() => endTime = p);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _field(slotsCtrl, 'Available Slots'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
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
                        content: Text('Please fill in all fields.')),
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
                      ? 'Event updated.'
                      : result.message ?? 'Failed.'),
                  backgroundColor:
                      result.success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
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

  Widget _tapField({
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
                Text("You haven't submitted any events yet.",
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14)),
              ],
            ),
          );
        }

        final pending =
            events.where((e) => e.status == 'pending').toList();
        final approved =
            events.where((e) => e.status == 'approved').toList();
        final others = events
            .where(
                (e) => e.status != 'pending' && e.status != 'approved')
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 80),
          children: [
            if (pending.isNotEmpty) ...[
              _groupHeader('Pending Review', Colors.orange.shade700),
              ...pending.map((e) => _SubmissionCard(
                    event: e,
                    statusColor: _statusColor(e.status),
                    statusLabel: _statusLabel(e.status),
                    statusIcon: _statusIcon(e.status),
                    onEdit: () => _showEditDialog(context, e),
                    onCancel: () => _showCancelDialog(context, e),
                  )),
              const SizedBox(height: 8),
            ],
            if (approved.isNotEmpty) ...[
              _groupHeader('Approved', Colors.green.shade600),
              ...approved.map((e) => _SubmissionCard(
                    event: e,
                    statusColor: _statusColor(e.status),
                    statusLabel: _statusLabel(e.status),
                    statusIcon: _statusIcon(e.status),
                    onCancel: () => _showCancelDialog(context, e),
                  )),
              const SizedBox(height: 8),
            ],
            if (others.isNotEmpty) ...[
              _groupHeader('Other', Colors.grey.shade500),
              ...others.map((e) => _SubmissionCard(
                    event: e,
                    statusColor: _statusColor(e.status),
                    statusLabel: _statusLabel(e.status),
                    statusIcon: _statusIcon(e.status),
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _groupHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.4)),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final UserSubmittedEvent event;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const _SubmissionCard({
    required this.event,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = event.status == 'pending' && onEdit != null;
    final canCancel =
        (event.status == 'pending' || event.status == 'approved') &&
            onCancel != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(event.date),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startTime.format(context)} – ${event.endTime.format(context)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(event.venue,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canEdit || canCancel) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canEdit)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 13),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (canCancel)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 13),
                      label: Text(
                        event.status == 'pending'
                            ? 'Cancel'
                            : 'Request Cancel',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: cbocPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SUBMITTED EVENT CARD (calendar events tab)
// =============================================================================

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
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'cancel_requested':
        return 'Cancel Requested';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 44,
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
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _color),
                  ),
                  Text(
                    DateFormat('d').format(event.date),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(event.venue,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 11, color: _color),
                  const SizedBox(width: 3),
                  Text(_label,
                      style: TextStyle(
                          fontSize: 10,
                          color: _color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// APPROVED EVENT CARD
// =============================================================================

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
                  Text(DateFormat('MMM').format(item.date).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cbocPrimary)),
                  Text(DateFormat('d').format(item.date),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cbocPrimary)),
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

// =============================================================================
// EVENT DETAIL BOTTOM SHEET
// =============================================================================

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
    final attending =
        await BackendService.isAttendingEvent(widget.item.id);
    if (mounted)
      setState(() {
        _isAttending = attending;
        _loading = false;
      });
  }

  Future<void> _handleAttend() async {
    if (_isAttending) return;
    setState(() => _rsvpInProgress = true);
    final result =
        await BackendService.attendEvent(upcomingEvent: widget.item);
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
    final dateStr =
        DateFormat('EEEE, MMMM d, yyyy').format(widget.item.date);
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
                            : _isAttending
                                ? const _AttendingButton()
                                : ElevatedButton.icon(
                                    onPressed: _rsvpInProgress
                                        ? null
                                        : _handleAttend,
                                    icon: _rsvpInProgress
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Icon(
                                            Icons.event_available_rounded,
                                            color: Colors.white),
                                    label: const Text('Attend Event',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cbocPrimary,
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      elevation: 2,
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

// ── "You're Attending" button ─────────────────────────────────────────────────
class _AttendingButton extends StatelessWidget {
  const _AttendingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.12),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: Colors.green.shade600, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            "You're Attending!",
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}