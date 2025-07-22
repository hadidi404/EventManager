import 'package:flutter/material.dart';
import 'event_crud_service.dart';

class CompletedEventsPage extends StatelessWidget {
  const CompletedEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final completedEvents = EventCrudService.completedEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Events'),
        backgroundColor: Colors.green,
      ),
      body: completedEvents.isEmpty
          ? const Center(child: Text('No completed events.'))
          : ListView.builder(
              itemCount: completedEvents.length,
              itemBuilder: (context, index) {
                final event = completedEvents[index].value;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(event.name),
                    subtitle: Text(
                      'Date & Time: ${event.dateTime}\nAttendees: ${event.attendees}\nAmount: ₱${event.amount}',
                    ),
                    tileColor: Colors.green[50],
                  ),
                );
              },
            ),
    );
  }
}
