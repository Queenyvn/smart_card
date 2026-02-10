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
  final _posterUrlCtrl = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // =====================================================
  // ADD EVENT DIALOG
  // =====================================================
  void _openAddEventDialog() {
    final _slotsCtrl = TextEditingController();

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
              const SizedBox(height: 16),
              _inputField(_posterUrlCtrl, 'Event Poster URL'),
              const SizedBox(height: 18),

              // ==========================
              // DATE FIELD 
              // ==========================
              TextField(
                readOnly: true, 
                decoration: InputDecoration(
                  labelText: 'Select Date',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                controller: TextEditingController(
                  text: _eventDate == null
                      ? ''
                      : DateFormat('MM/dd/yyyy').format(_eventDate!), // SHOW DATE
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    initialDate: _eventDate ?? DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _eventDate = picked); // UPDATE FIELD
                  }
                },
              ),

              // ==========================
              // START TIME FIELD
              // ==========================
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      controller: TextEditingController(
                        text: _startTime == null ? '' : _startTime!.format(context),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 12), // spacing between start and end time

                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      controller: TextEditingController(
                        text: _endTime == null ? '' : _endTime!.format(context),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),

              // SLOTS FIELD
              const SizedBox(height: 12),
              _inputField(_slotsCtrl, 'Number of Available Slots'),
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
              if (_eventDate == null ||
                  _startTime == null ||
                  _endTime == null ||
                  _slotsCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields!')),
                );
                return;
              }

              final availableSlots = int.tryParse(_slotsCtrl.text);
              if (availableSlots == null || availableSlots <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter a valid number of available slots'),
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
                posterUrl:
                    _posterUrlCtrl.text.isEmpty ? null : _posterUrlCtrl.text,
                availableSlots: availableSlots,
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
  // DATE FIELD WIDGET
  // =====================================================
  Widget _dateField() {
    return TextField(
      readOnly: true, // NEW
      decoration: InputDecoration(
        labelText: 'Select Date',
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      controller: TextEditingController(
        text: _eventDate == null
            ? ''
            : DateFormat('MM/dd/yyyy').format(_eventDate!), // NEW
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          initialDate: _eventDate ?? DateTime.now(),
        );
        if (picked != null) {
          setState(() => _eventDate = picked); // CHANGED
        }
      },
    );
  }

  // =====================================================
  // TIME FIELD WIDGET
  // =====================================================
  Widget _timeField({
    required String label,
    required TimeOfDay? value,
    required Function(TimeOfDay) onPick,
  }) {
    return TextField(
      readOnly: true, // NEW
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      controller: TextEditingController(
        text: value == null ? '' : value.format(context), // NEW
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) {
          onPick(picked); // CHANGED
        }
      },
    );
  }

  // =====================================================
  // INPUT FIELD (UNCHANGED)
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

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              todayDecoration: BoxDecoration(
                color: cbocAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: cbocPrimary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: cbocSecondary,
                shape: BoxShape.circle,
              ),
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
                          '${item.event.venue}\n'
                          '${DateFormat('MMMM dd, yyyy').format(item.date)} • '
                          '${item.event.startTime.format(context)} - '
                          '${item.event.endTime.format(context)}',
                        ),
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

