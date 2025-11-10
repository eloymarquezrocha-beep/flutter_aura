import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomCalendarScreen extends StatefulWidget {
  const CustomCalendarScreen({super.key});

  @override
  State<CustomCalendarScreen> createState() => _CustomCalendarScreenState();
}

class _CustomCalendarScreenState extends State<CustomCalendarScreen> {
  final Map<DateTime, List<Event>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  late final ValueNotifier<List<Event>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadEvents(); // ✅ cargar eventos guardados
    _selectedDays.add(_focusedDay);
    _selectedEvents = ValueNotifier(_getEventsForDay(_focusedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonData = {};

    _events.forEach((key, value) {
      jsonData[key.toIso8601String()] =
          value.map((e) => e.toJson()).toList();
    });

    await prefs.setString("events", jsonEncode(jsonData));
  }

  Future<void> _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("events");

    if (data == null) return;

    Map<String, dynamic> decoded = jsonDecode(data);

    decoded.forEach((key, value) {
      DateTime day = DateTime.parse(key);
      List<Event> events =
          (value as List).map((e) => Event.fromJson(e)).toList();
      _events[day] = events;
    });

    setState(() {
      _selectedEvents.value = _getEventsForDay(_focusedDay);
    });
  }

  List<Event> _getEventsForDay(DateTime day) => _events[day] ?? [];
  List<Event> _getEventsForDays(Iterable<DateTime> days) =>
      [for (final d in days) ..._getEventsForDay(d)];

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return _getEventsForDays(days);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_selectedDays.contains(selectedDay)) {
        _selectedDays.remove(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }
      _focusedDay = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });
    _selectedEvents.value = _getEventsForDays(_selectedDays);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _selectedDays.clear();
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  /// ✅ POPUP CENTRADO + Selector de fecha
  void _addEvent(DateTime day) {
    final TextEditingController titleController = TextEditingController();
    TimeOfDay? selectedTime;
    DateTime selectedDate = day;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Agregar Evento',
          style: TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
                decoration: const InputDecoration(
                  hintText: 'Título del evento',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                      style: const TextStyle(color: Colors.white70, fontFamily: 'MonosRegular'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (pickedDate != null) {
                        setModalState(() => selectedDate = pickedDate);
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedTime == null
                          ? 'Hora: No seleccionada'
                          : 'Hora: ${selectedTime!.format(context)}',
                      style: const TextStyle(color: Colors.white70, fontFamily: 'MonosRegular'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final newEvent = Event(
                titleController.text.trim(),
                time: selectedTime,
                date: selectedDate,
              );
              setState(() {
                _events.putIfAbsent(selectedDate, () => []).add(newEvent);
                _selectedEvents.value = _getEventsForDay(selectedDate);
              });
              await _saveEvents(); // ✅ Guardar al agregar
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _navButtonSelected(String asset) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(0, 13, 13, 13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(asset, width: 32, color: Colors.white),
    );
  }

  Widget _navButtonInactive(String asset, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(0, 13, 13, 13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(asset, width: 30, color: Colors.grey.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 19, 19, 19),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(0, 26, 26, 26),
        title: const Text(
          'Calendario de Eventos',
          style: TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
        ),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 44, 94, 122),
        onPressed: () => _addEvent(_focusedDay),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _selectedDays.contains(day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              titleTextStyle: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MonosRegular'),
              formatButtonDecoration: BoxDecoration(
                color: Color.fromARGB(255, 44, 94, 122),
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              formatButtonTextStyle:
                  TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: Colors.white70, size: 28),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: Colors.white70, size: 28),
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle:
                  TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
              weekendTextStyle:
                  TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 44, 94, 122),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(255, 44, 94, 122),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay eventos para este día',
                      style: TextStyle(
                          color: Colors.white54, fontFamily: 'MonosRegular'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Dismissible(
                      key: ValueKey('${event.title}-${event.date}-$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: const Color.fromARGB(255, 255, 6, 6),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        setState(() {
                          _events[event.date]?.remove(event);
                          _selectedEvents.value =
                              _getEventsForDay(event.date);
                        });
                        await _saveEvents(); // ✅ guardar al eliminar
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 74, 74, 74),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromARGB(255, 44, 94, 122)),
                        ),
                        child: ListTile(
                          title: Text(
                            event.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'MonosRegular'),
                          ),
                          subtitle: Text(
                            "${DateFormat('dd MMM yyyy').format(event.date)}"
                            "${event.time != null ? ' • ${event.time!.format(context)}' : ''}",
                            style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'MonosItalic'),
                          ),
                          trailing: const Icon(Icons.event,
                              color: Color.fromARGB(255, 44, 94, 122)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color.fromARGB(0, 13, 13, 13),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButtonInactive("assets/House.png", () {
              Navigator.pop(context);
            }),
            _navButtonSelected("assets/Calendar.png"),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String title;
  final TimeOfDay? time;
  final DateTime date;

  const Event(this.title, {this.time, required this.date});

  Map<String, dynamic> toJson() => {
        "title": title,
        "timeHour": time?.hour,
        "timeMinute": time?.minute,
        "date": date.toIso8601String(),
      };

  factory Event.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json["timeHour"] != null) {
      time = TimeOfDay(
        hour: json["timeHour"],
        minute: json["timeMinute"],
      );
    }
    return Event(
      json["title"],
      time: time,
      date: DateTime.parse(json["date"]),
    );
  }

  @override
  String toString() => '$title';
}

int getHashCode(DateTime key) =>
    key.day * 1000000 + key.month * 10000 + key.year;

Iterable<DateTime> daysInRange(DateTime start, DateTime end) sync* {
  var day = DateTime(start.year, start.month, start.day);
  final lastDay = DateTime(end.year, end.month, end.day);
  while (day.isBefore(lastDay) || isSameDay(day, lastDay)) {
    yield day;
    day = DateTime(day.year, day.month, day.day + 1);
  }
}
