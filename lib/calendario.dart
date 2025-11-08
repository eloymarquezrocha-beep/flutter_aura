import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:glass/glass.dart'; // <-- necesario para asGlass()

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
    _selectedDays.add(_focusedDay);
    _selectedEvents = ValueNotifier(_getEventsForDay(_focusedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
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

  void _addEvent(DateTime day) {
    final TextEditingController titleController = TextEditingController();
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Agregar Evento',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold, fontFamily: 'MonosRegular'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
                decoration: InputDecoration(
                  hintText: 'Título del evento',
                  hintStyle: const TextStyle(color: Colors.white70, fontFamily: 'MonosRegular'),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  final newEvent = Event(
                    titleController.text.trim(),
                    time: selectedTime,
                    date: day,
                  );
                  setState(() {
                    _events.putIfAbsent(day, () => []).add(newEvent);
                    _selectedEvents.value = _getEventsForDay(day);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Guardar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ BARRA DE NAVEGACIÓN INFERIOR (sin cambios)
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
        automaticallyImplyLeading: false, // <- quita flecha
        backgroundColor: const Color.fromARGB(0, 26, 26, 26),
        title: const Text(
          'Calendario de Eventos',
          style: TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
        ),
        centerTitle: true,
      ),

      // FAB centrado
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 44, 94, 122),
        onPressed: () => _addEvent(_focusedDay),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      /// ✅ CONTENIDO DEL CALENDARIO (sin cambios en layout)
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
              titleTextStyle:
                  TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'MonosRegular'),
              formatButtonDecoration: BoxDecoration(
                color: Color.fromARGB(255, 44, 94, 122),
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              formatButtonTextStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontFamily: 'MonosRegular'),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: Colors.white70, size: 28),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: Colors.white70, size: 28),
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white, fontFamily: 'MonosRegular',),
              weekendTextStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255),fontFamily: 'MonosRegular',),
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
                color: Color.fromARGB(255, 255, 255, 255),
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
                      style: TextStyle(color: Colors.white54, fontFamily: 'MonosRegular'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];




                    // Dismissible para borrar deslizando (solo modifica esto)
                    return Dismissible(
                      key: ValueKey('${event.title}-${event.date}-$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: const Color.fromARGB(255, 255, 6, 6),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          _events[event.date]?.remove(event);
                          _selectedEvents.value = _getEventsForDay(event.date);
                        });




                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 74, 74, 74),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color.fromARGB(255, 44, 94, 122)),
                        ),
                        child: ListTile(
                          title: Text(
                            event.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'MonosRegular'),
                          ),
                          subtitle: Text(
                            "${DateFormat('dd MMM yyyy').format(event.date)}"
                            "${event.time != null ? ' • ${event.time!.format(context)}' : ''}",
                            style: const TextStyle(color: Colors.white70, fontFamily: 'MonosItalic'),
                          ),
                          trailing: const Icon(Icons.event, color: Color.fromARGB(255, 44, 94, 122)),
                        ),
                      )
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      /// ✅ Bottom Nav agregado al final (sin cambios funcionales)
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

/// Modelo básico de Evento
class Event {
  final String title;
  final TimeOfDay? time;
  final DateTime date;

  const Event(this.title, {this.time, required this.date});

  @override
  String toString() => '$title (${DateFormat('dd/MM/yyyy').format(date)})';
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
