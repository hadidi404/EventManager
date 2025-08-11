import 'package:flutter/material.dart';
import 'csv_service.dart';
import 'utils/date_time_helper.dart';
import 'event.dart';
import 'excel_export_service.dart';
import 'event_crud_service.dart';
import 'pdf_service.dart';
import 'event_detail_page.dart';
import 'package:intl/intl.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  Set<int> _selectedIndexes = {};
  bool _selectionMode = false;
  bool _isCateringService = false;
  String? _selectedService;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _attendeesController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cateringDetailsController =
      TextEditingController();
  final TextEditingController _paxController = TextEditingController();

  final List<String> _serviceOptions = [
    'Breakfast',
    'Lunch',
    'Snacks',
    'Dinner',
    'Others',
  ];
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactDetailsController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
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
    // Loads the list of attendees for autofill
    Future<List<String>> _getAttendeeSuggestions() async {
      final events = await CSVService.loadEvents();
      final attendees = events.map((e) => e.attendees.trim()).toSet().toList();
      return attendees;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 360, maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Event Name'),
                  ),
                  FutureBuilder<List<String>>(
                    future: _getAttendeeSuggestions(),
                    builder: (context, snapshot) {
                      final suggestions = snapshot.data ?? [];
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty)
                            return const Iterable<String>.empty();
                          return suggestions.where(
                            (option) => option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        fieldViewBuilder:
                            (
                              context,
                              controller,
                              focusNode,
                              onEditingComplete,
                            ) {
                              _attendeesController.text = controller.text;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Attendees/Organization',
                                ),
                                onEditingComplete: onEditingComplete,
                              );
                            },
                        onSelected: (String selection) {
                          _attendeesController.text = selection;
                        },
                      );
                    },
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Person',
                    ),
                  ),
                  TextField(
                    controller: _contactDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Details',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _isCateringService,
                    onChanged: (value) {
                      setState(() {
                        _isCateringService = value ?? false;
                      });
                    },
                    title: const Text('Is this a catering service?'),
                  ),
                  if (_isCateringService) ...[
                    TextField(
                      controller: _paxController,
                      decoration: const InputDecoration(
                        labelText: 'Pax (No. of People)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Scope of Service:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _serviceOptions.map((option) {
                        return ChoiceChip(
                          label: Text(option),
                          selected: _selectedService == option,
                          onSelected: (selected) {
                            setState(() {
                              _selectedService = selected ? option : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cateringDetailsController,
                      decoration: InputDecoration(
                        labelText: 'Catering Details (optional)',
                        hintText:
                            'e.g., buffet, plated meal, halal, vegetarian',
                        border: const OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
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
                  location: _locationController.text,
                  contactPerson: _contactPersonController.text,
                  contactDetails: _contactDetailsController.text,
                  CateringService: _isCateringService,
                  pax: _isCateringService ? _paxController.text : null,
                  scopeOfService: _isCateringService ? _selectedService : null,
                  cateringDetails: _isCateringService
                      ? _cateringDetailsController.text
                      : null,
                );

                EventCrudService.addEvent(newEvent);

                // Clear fields
                _nameController.clear();
                _attendeesController.clear();
                _dateTimeController.clear();
                _amountController.clear();
                _locationController.clear();
                _contactPersonController.clear();
                _contactDetailsController.clear();
                _paxController.clear();
                _cateringDetailsController.clear();
                _selectedService = null;
                _isCateringService = false;

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

  void _generateCSV() {
    ExcelExportService.shareExcel();
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
            : const Text('Active Events'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _generatePdf),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _generateCSV, // now using the imported function
            tooltip: 'Export CSV',
          ),
        ],
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
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Card(
                      color: isSelected ? Colors.deepPurple[50] : Colors.white,
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Left: Event Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.dateTime,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.group,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.attendees,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.monetization_on,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '₱${event.amount}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right: Payment Status Circle
                            _buildPaymentStatusIndicator(
                              event.paidAmount.toDouble(),
                              double.tryParse(event.amount) ??
                                  1.0, // Avoid divide-by-zero
                            ),
                          ],
                        ),
                      ),
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
              ],
            )
          : null,
    );
  }

  Widget _buildPaymentStatusIndicator(double paid, double total) {
    final percentage = (paid / total).clamp(0, 1);
    final percentText = "${(percentage * 100).round()}%";
    Color color;

    if (percentage == 1) {
      color = Colors.green;
    } else if (percentage >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 15), // adjust as needed
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  value: (paid / total).toDouble(),
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              Text(
                percentText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            percentage == 1 ? "Paid" : "Unpaid",
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
