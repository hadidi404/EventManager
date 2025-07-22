import 'package:event_manager_2/noti_service.dart';
import 'package:flutter/material.dart';
import 'utils/date_time_helper.dart';
import 'event.dart';
import 'event_crud_service.dart';
import 'pdf_service.dart';
import 'event_detail_page.dart';
import 'completed_events_page.dart';
import 'package:intl/intl.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  Set<int> _selectedIndexes = {};
  bool _selectionMode = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _attendeesController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final NotiService notiService = NotiService();

  @override
  void initState() {
    super.initState();
    notiService.initNotification();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await EventCrudService.loadEvents();
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final picked = await DateTimePickerHelper.pickDateTime(context);
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd hh:mm a').format(picked);
      setState(() {
        _dateTimeController.text = formatted;
      });
    }
  }

  void _addEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
              ),
              TextField(
                controller: _attendeesController,
                decoration: const InputDecoration(
                  labelText: 'Attendees/Organization',
                ),
              ),
              GestureDetector(
                onTap: _pickDateTime,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Select Date & Time',
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (₱)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newEvent = Event(
                name: _nameController.text,
                dateTime: _dateTimeController.text,
                attendees: _attendeesController.text,
                amount: _amountController.text,
              );

              EventCrudService.addEvent(newEvent);
              _nameController.clear();
              _attendeesController.clear();
              _dateTimeController.clear();
              _amountController.clear();
              Navigator.of(context).pop();
              _loadEvents();
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _onLongPress(int index) {
    setState(() {
      _selectionMode = true;
      _selectedIndexes.add(index);
    });
  }

  void _onTap(int visibleIndex) {
    if (_selectionMode) {
      setState(() {
        if (_selectedIndexes.contains(visibleIndex)) {
          _selectedIndexes.remove(visibleIndex);
          if (_selectedIndexes.isEmpty) _selectionMode = false;
        } else {
          _selectedIndexes.add(visibleIndex);
        }
      });
    } else {
      final entry = EventCrudService.visibleEvents[visibleIndex];
      final event = entry.value;
      final index = entry.key;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailPage(
            event: event,
            index: index,
            onUpdate: _loadEvents,
          ),
        ),
      );
    }
  }

  void _deleteSelected() {
    EventCrudService.deleteEventsByVisibleIndexes(_selectedIndexes);
    setState(() {
      _selectionMode = false;
      _selectedIndexes.clear();
    });
    _loadEvents();
  }

  void _generatePdf() {
    PDFService.generateAndPrintPDF();
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = EventCrudService.visibleEvents;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: _selectionMode
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectionMode = false;
                        _selectedIndexes.clear();
                      });
                    },
                  ),
                  Text('${_selectedIndexes.length} selected'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelected,
                  ),
                ],
              )
            : const Text(
                'Event Manager',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
      body: visibleEvents.isEmpty
          ? const Center(child: Text('No events added yet.'))
          : ListView.builder(
              itemCount: visibleEvents.length,
              itemBuilder: (context, visibleIndex) {
                final event = visibleEvents[visibleIndex].value;
                final isSelected = _selectedIndexes.contains(visibleIndex);

                return GestureDetector(
                  onLongPress: () => _onLongPress(visibleIndex),
                  onTap: () => _onTap(visibleIndex),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: ListTile(
                      title: Text(event.name),
                      subtitle: Text(
                        'Date & Time: ${event.dateTime}\nAttendees: ${event.attendees}\nAmount: ₱${event.amount}',
                      ),
                      isThreeLine: true,
                      tileColor: isSelected
                          ? Colors.blue[100]
                          : Colors.blue[50],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: !_selectionMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _addEventDialog,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _generatePdf,
                  child: const Icon(Icons.picture_as_pdf),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () async {
                    notiService.showNotification();
                  },
                  child: const Icon(Icons.notifications),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompletedEventsPage(),
                      ),
                    );
                  },
                  child: const Icon(Icons.check),
                ),
              ],
            )
          : null,
    );
  }
}
