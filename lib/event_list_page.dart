import 'package:event_manager_2/noti_service.dart';
import 'package:flutter/material.dart';
import 'event_calendar_page.dart';
import 'event.dart';
import 'csv_service.dart';
import 'pdf_service.dart';
import 'event_detail_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Event> _allEvents = [];
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
    final loadedEvents = await CSVService.loadAllEvents();
    setState(() {
      _allEvents = loadedEvents;
    });
  }

  Future<void> _saveEvents() async {
    await CSVService.saveEvents(_allEvents);
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        String formatted =
            "${fullDateTime.year}-${fullDateTime.month.toString().padLeft(2, '0')}-${fullDateTime.day.toString().padLeft(2, '0')} "
            "${pickedTime.format(context)}";

        setState(() {
          _dateTimeController.text = formatted;
        });
      }
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
              setState(() {
                _allEvents.add(
                  Event(
                    name: _nameController.text,
                    dateTime: _dateTimeController.text,
                    attendees: _attendeesController.text,
                    amount: _amountController.text,
                  ),
                );
              });
              _saveEvents();
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

  void _generatePdf() {
    PDFService.generateAndPrintPDF();
  }

  void _onLongPress(int index) {
    setState(() {
      _selectionMode = true;
      _selectedIndexes.add(index);
    });
  }

  void _onTap(int index) {
    if (_selectionMode) {
      setState(() {
        if (_selectedIndexes.contains(index)) {
          _selectedIndexes.remove(index);
          if (_selectedIndexes.isEmpty) _selectionMode = false;
        } else {
          _selectedIndexes.add(index);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailPage(event: _allEvents[index]),
        ),
      );
    }
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIndexes.clear();
    });
  }

  void _deleteSelected() {
    setState(() {
      // Map visible indexes to real indexes in _allEvents
      final visibleEvents = _allEvents
          .asMap()
          .entries
          .where((entry) => !entry.value.isDeleted)
          .toList();
      for (var visibleIndex in _selectedIndexes) {
        final realIndex = visibleEvents[visibleIndex].key;
        final event = _allEvents[realIndex];
        _allEvents[realIndex] = Event(
          name: event.name,
          dateTime: event.dateTime,
          attendees: event.attendees,
          amount: event.amount,
          isDeleted: true,
        );
      }
      _selectionMode = false;
      _selectedIndexes.clear();
    });
    _saveEvents();
    _loadEvents(); // Refresh list to hide deleted events
  }

  @override
  Widget build(BuildContext context) {
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

      body: _allEvents.where((e) => !e.isDeleted).isEmpty
          ? const Center(child: Text('No events added yet.'))
          : ListView.builder(
              itemCount: _allEvents.where((e) => !e.isDeleted).length,
              itemBuilder: (context, visibleIndex) {
                // Map visibleIndex to the correct index in _allEvents
                final visibleEvents = _allEvents
                    .asMap()
                    .entries
                    .where((entry) => !entry.value.isDeleted)
                    .toList();
                final index = visibleEvents[visibleIndex].key;
                final event = _allEvents[index];
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
                    final noti = NotiService();
                    await noti.checkTomorrowEventsAndNotify();
                  },
                  child: const Icon(Icons.notifications_active),
                ),
              ],
            )
          : null,
    );
  }
}
