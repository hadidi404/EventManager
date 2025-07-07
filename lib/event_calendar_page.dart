import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'csv_service.dart'; // Your CSV loader

class EventCalendarPage extends StatefulWidget {
  const EventCalendarPage({super.key});

  @override
  State<EventCalendarPage> createState() => _EventCalendarPageState();
}

class _EventCalendarPageState extends State<EventCalendarPage> {
  List<Appointment> appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final events = await CSVService.loadEvents();

    final List<Appointment> loadedAppointments = events
        .map((event) {
          try {
            final dateTimeParts = event.dateTime.split(' ');
            final date = DateTime.parse(dateTimeParts[0]);
            final time = dateTimeParts.length > 1
                ? TimeOfDay(
                    hour: int.parse(dateTimeParts[1].split(':')[0]),
                    minute: int.parse(dateTimeParts[1].split(':')[1]),
                  )
                : const TimeOfDay(hour: 9, minute: 0); // default time

            final start = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
            final end = start.add(const Duration(hours: 1)); // default duration

            return Appointment(
              startTime: start,
              endTime: end,
              subject: event.name,
              color: Colors.blue,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<Appointment>()
        .toList();

    setState(() {
      appointments = loadedAppointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Calendar")),
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: AppointmentDataSource(appointments),
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        ),
      ),
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
