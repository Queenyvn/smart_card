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

  final Set<String> _attendingEvents = {};

  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _posterUrlCtrl = TextEditingController(); // NEW: controller for URL input

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // =====================================================
  // EVENT DETAILS
  // =====================================================
  void _showEventDetails(UpcomingEvent item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(item.event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.event.venue,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(item.event.description),
            const SizedBox(height: 12),
            if (item.event.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.event.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              '${_formatDate(item.date)}\n'
              '${_formatTime(item.event.startTime)} - ${_formatTime(item.event.endTime)}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cbocPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _attendEvent(item.event, item.date),
            child: const Text('Attend'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ADD EVENT DIALOG
  // =====================================================
  void _openAddEventDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.grey.shade50,
        title: const Text(
          'Add Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _inputField(_titleCtrl, 'Event Title'),
              const SizedBox(height: 12),
              _inputField(_venueCtrl, 'Venue'),
              const SizedBox(height: 12),
              _inputField(_descCtrl, 'Description', maxLines: 4),

              // EVENT POSTER URL INPUT
              const SizedBox(height: 16),
              _inputField(_posterUrlCtrl, 'Event Poster URL'),

              const SizedBox(height: 18),

              _actionButton('Select Date', () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );
                if (picked != null) setState(() => _eventDate = picked);
              }),

              _actionButton('Start Time', () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) _startTime = picked;
              }),

              _actionButton('End Time', () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) _endTime = picked;
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cbocPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              if (_eventDate == null || _startTime == null || _endTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select date, start, and end time!'),
                  ),
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
                posterUrl: _posterUrlCtrl.text.isEmpty ? null : _posterUrlCtrl.text, // use URL
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event submitted for admin approval'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // UI HELPERS
  // =====================================================
  Widget _inputField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: cbocSecondary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  // =====================================================
  // CALENDAR + EVENTS LIST
  // =====================================================
  String _formatDate(DateTime date) =>
      DateFormat('MMMM dd, yyyy').format(date);

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  Future<void> _attendEvent(CalendarEvent event, DateTime date) async {
    final key = '${event.title}-${date.toIso8601String()}';
    if (_attendingEvents.contains(key)) return;

    final result =
        await BackendService.attendEvent(event: event, date: date);

    if (result.success) {
      setState(() => _attendingEvents.add(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now attending this event!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title:
            const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cbocPrimary,
        onPressed: _openAddEventDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: BackendService.getEventsForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: cbocAccent, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: cbocPrimary, shape: BoxShape.circle),
              markerDecoration:
                  const BoxDecoration(color: cbocSecondary, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UpcomingEvent>>(
              stream: BackendService.approvedEventsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final monthEvents = snapshot.data!
                    .where((e) =>
                        e.date.year == _focusedDay.year &&
                        e.date.month == _focusedDay.month)
                    .toList();

                return ListView(
                  children: monthEvents.map((item) {
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text(item.event.title),
                        subtitle: Text(
                          '${item.event.venue}\n${_formatDate(item.date)} • '
                          '${_formatTime(item.event.startTime)} - ${_formatTime(item.event.endTime)}',
                        ),
                        onTap: () => _showEventDetails(item),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
