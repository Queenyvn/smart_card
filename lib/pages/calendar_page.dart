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

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _posterUrlCtrl = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

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
                        value:
                            _startTime == null ? '' : _startTime!.format(ctx),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cbocAccent,
        onPressed: _openAddEventDialog,
        child: const Icon(Icons.add, color: cbocPrimary),
      ),
      body: StreamBuilder<List<UpcomingEvent>>(
        stream: BackendService.approvedEventsStream(),
        builder: (context, snapshot) {
          final allEvents = snapshot.data ?? [];
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  allEvents.isEmpty;

          final visibleEvents = allEvents.where((e) {
            if (_selectedDay != null) {
              return _sameDay(e.date, _selectedDay!);
            }
            return _sameMonth(e.date, _focusedDay);
          }).toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          Map<DateTime, List<UpcomingEvent>> eventMap = {};
          for (final e in allEvents) {
            final key =
                DateTime(e.date.year, e.date.month, e.date.day);
            eventMap.putIfAbsent(key, () => []).add(e);
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null && _sameDay(day, _selectedDay!),
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return eventMap[key] ?? [];
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      if (_selectedDay != null &&
                          _sameDay(selected, _selectedDay!)) {
                        _selectedDay = null;
                      } else {
                        _selectedDay = selected;
                      }
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) {
                    setState(() {
                      _focusedDay = focused;
                      _selectedDay = null;
                    });
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
                      _selectedDay != null
                          ? DateFormat('MMMM d, yyyy').format(_selectedDay!)
                          : DateFormat('MMMM yyyy').format(_focusedDay),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cbocPrimary,
                      ),
                    ),
                    if (_selectedDay != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDay = null),
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
                    : visibleEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedDay != null
                                      ? 'No events on this day'
                                      : 'No events this month',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                12, 10, 12, 80),
                            itemCount: visibleEvents.length,
                            itemBuilder: (_, i) {
                              final item = visibleEvents[i];
                              return _EventCard(
                                item: item,
                                onTap: () =>
                                    _showEventDetail(context, item),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── EVENT CARD ────────────────────────────────────────────────────────────────

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

class _EventDetailSheet extends StatelessWidget {
  final UpcomingEvent item;
  const _EventDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final e = item.event;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(item.date);
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
                    child: Image.network(
                      e.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
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
                        value: dateStr,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: timeStr,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.location_on_rounded,
                        label: 'Venue',
                        value: e.venue,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.event_seat_rounded,
                        label: 'Available Slots',
                        value: item.availableSlots.toString(),
                      ),
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
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cbocAccent,
                            minimumSize:
                                const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: const Text('Attend Event',
                              style: TextStyle(
                                  color: cbocPrimary,
                                  fontWeight: FontWeight.bold)),
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
            color: cbocAccent,
            borderRadius: BorderRadius.circular(8),
          ),
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