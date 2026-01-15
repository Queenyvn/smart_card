import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// ===============================
/// MODEL: Single Calendar Event
/// ===============================
class CalendarEvent {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
  });
}

/// =======================================
/// HELPER MODEL: Event + Its Actual Date
/// Used for listing monthly events
/// =======================================
class UpcomingEvent {
  final DateTime date;
  final CalendarEvent event;

  UpcomingEvent({
    required this.date,
    required this.event,
  });
}

/// ===============================
/// CALENDAR PAGE
/// ===============================
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  /// Currently focused month
  DateTime _focusedDay = DateTime.now();

  /// Selected calendar day
  DateTime? _selectedDay;

  /// Stores all events (grouped by date)
  final Map<DateTime, List<CalendarEvent>> _events = {};

  /// ===============================
  /// INITIAL DEMO EVENTS (Proposal)
  /// ===============================
  @override
  void initState() {
    super.initState();

    // TEMPORARY EVENTS FOR PROPOSAL DEMO
    _addEvent(
      'Project Proposal Meeting',
      DateTime.now().add(const Duration(days: 1)),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
    );

    _addEvent(
      'CBOC General Assembly',
      DateTime.now().add(const Duration(days: 4)),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 22, minute: 0),
    );

    _addEvent(
      'Entrepreneurship Workshop',
      DateTime.now().add(const Duration(days: 9)),
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
    );
  }

  /// ===================================
  /// GET EVENTS FOR A SPECIFIC DAY
  /// ===================================
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  /// ===================================
  /// GET ALL EVENTS FOR THE CURRENT MONTH
  /// ===================================
  List<UpcomingEvent> _getMonthEvents() {
    final List<UpcomingEvent> monthEvents = [];

    _events.forEach((date, events) {
      if (date.year == _focusedDay.year &&
          date.month == _focusedDay.month) {
        for (var event in events) {
          monthEvents.add(
            UpcomingEvent(date: date, event: event),
          );
        }
      }
    });

    // Sort by date (earliest first)
    monthEvents.sort((a, b) => a.date.compareTo(b.date));
    return monthEvents;
  }

  /// ===============================
  /// ADD EVENT TO MAP
  /// ===============================
  void _addEvent(
    String title,
    DateTime date,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final key = DateTime(date.year, date.month, date.day);
    setState(() {
      _events.putIfAbsent(key, () => []);
      _events[key]!.add(
        CalendarEvent(
          title: title,
          startTime: start,
          endTime: end,
        ),
      );
    });
  }

  /// ===============================
  /// FORMAT TIME (UI DISPLAY)
  /// ===============================
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  /// ===============================
  /// ADD EVENT MODAL (Bottom Sheet)
  /// ===============================
  void _showAddEventModal() {
    final titleController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime =
        TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Event',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setModalState(() => startTime = picked);
                            }
                          },
                          child: Text('Start: ${_formatTime(startTime)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setModalState(() => endTime = picked);
                            }
                          },
                          child: Text('End: ${_formatTime(endTime)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        child: const Text('Change Date'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDate: selectedDate,
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        _addEvent(
                          titleController.text,
                          selectedDate,
                          startTime,
                          endTime,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Submit Event'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ===============================
  /// UI BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventModal,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          /// CALENDAR VIEW
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),

          /// MONTHLY EVENTS LIST (NO DATE CLICK REQUIRED)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Events This Month',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(
            height: 220,
            child: ListView(
              children: _getMonthEvents().map((item) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(item.event.title),
                    subtitle: Text(
                      '${item.date.year}-${item.date.month}-${item.date.day} • '
                      '${_formatTime(item.event.startTime)} – ${_formatTime(item.event.endTime)}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Attend'),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          /// SELECTED DAY EVENTS (OPTIONAL INTERACTION)
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a date'))
                : ListView(
                    children:
                        _getEventsForDay(_selectedDay!).map((event) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(event.title),
                          subtitle: Text(
                            '${_formatTime(event.startTime)} – ${_formatTime(event.endTime)}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Attend'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
