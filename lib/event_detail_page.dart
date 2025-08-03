import 'package:event_manager_2/utils/date_time_helper.dart';
import 'package:flutter/material.dart';
import 'event.dart';
import 'csv_service.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;
  final int index;
  final VoidCallback onUpdate;

  const EventDetailPage({
    super.key,
    required this.event,
    required this.index,
    required this.onUpdate,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _attendeesController;
  late TextEditingController _dateTimeController;
  late TextEditingController _amountController;
  late TextEditingController _paymentController;
  late TextEditingController _locationController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactDetailsController;

  // Catering-related controllers/state
  late TextEditingController _paxController;
  late TextEditingController _cateringDetailsController;
  String? _selectedScope;
  bool _isCatering = false;

  bool _isEditing = false;
  late int _paidAmount;

  final List<String> _scopeOptions = [
    'Breakfast',
    'Lunch',
    'Snacks',
    'Dinner',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _attendeesController = TextEditingController(text: widget.event.attendees);
    _dateTimeController = TextEditingController(text: widget.event.dateTime);
    _amountController = TextEditingController(text: widget.event.amount);
    _paymentController = TextEditingController();
    _paidAmount = widget.event.paidAmount;
    _locationController = TextEditingController(text: widget.event.location);
    _contactPersonController = TextEditingController(
      text: widget.event.contactPerson,
    );
    _contactDetailsController = TextEditingController(
      text: widget.event.contactDetails,
    );

    _isCatering = widget.event.CateringService;
    _paxController = TextEditingController(text: widget.event.pax ?? '');
    _cateringDetailsController = TextEditingController(
      text: widget.event.cateringDetails ?? '',
    );
    _selectedScope = widget.event.scopeOfService;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attendeesController.dispose();
    _dateTimeController.dispose();
    _amountController.dispose();
    _paymentController.dispose();
    _locationController.dispose();
    _contactPersonController.dispose();
    _contactDetailsController.dispose();
    _paxController.dispose();
    _cateringDetailsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updated = Event(
      name: _nameController.text.trim(),
      attendees: _attendeesController.text.trim(),
      dateTime: _dateTimeController.text.trim(),
      amount: _amountController.text.trim(),
      paidAmount: _paidAmount,
      isDeleted: false,
      location: _locationController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      contactDetails: _contactDetailsController.text.trim(),
      CateringService: _isCatering,
      pax: _isCatering
          ? (_paxController.text.trim().isEmpty
                ? null
                : _paxController.text.trim())
          : null,
      scopeOfService: _isCatering ? _selectedScope : null,
      cateringDetails: _isCatering
          ? (_cateringDetailsController.text.trim().isEmpty
                ? null
                : _cateringDetailsController.text.trim())
          : null,
    );

    final allEvents = await CSVService.loadAllEvents();
    allEvents[widget.index] = updated;
    await CSVService.saveEvents(allEvents);
    widget.onUpdate();
    setState(() => _isEditing = false);
  }

  Future<void> _recordPayment() async {
    final newPayment = int.tryParse(_paymentController.text);
    if (newPayment == null || newPayment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount')),
      );
      return;
    }

    setState(() {
      _paidAmount += newPayment;
      _paymentController.clear();
    });

    await _saveChanges();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment recorded successfully!')),
    );
  }

  Future<void> _deleteEvent() async {
    final allEvents = await CSVService.loadAllEvents();
    final updated = Event(
      name: widget.event.name,
      attendees: widget.event.attendees,
      dateTime: widget.event.dateTime,
      amount: widget.event.amount,
      paidAmount: widget.event.paidAmount,
      isDeleted: true,
      location: widget.event.location,
      contactPerson: widget.event.contactPerson,
      contactDetails: widget.event.contactDetails,
      CateringService: widget.event.CateringService,
      pax: widget.event.pax,
      scopeOfService: widget.event.scopeOfService,
      cateringDetails: widget.event.cateringDetails,
    );

    allEvents[widget.index] = updated;
    await CSVService.saveEvents(allEvents);
    widget.onUpdate();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildField('Event Name', _nameController),
                    const SizedBox(height: 15),
                    _isEditing
                        ? GestureDetector(
                            onTap: () async {
                              final picked =
                                  await DateTimePickerHelper.pickDateTime(
                                    context,
                                  );
                              if (picked != null) {
                                final formatted = DateFormat(
                                  'yyyy-MM-dd hh:mm a',
                                ).format(picked);
                                setState(() {
                                  _dateTimeController.text = formatted;
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: _buildField(
                                'Date & Time',
                                _dateTimeController,
                              ),
                            ),
                          )
                        : _buildField('Date & Time', _dateTimeController),
                    const SizedBox(height: 15),
                    _buildField(
                      'Attendees / Organization',
                      _attendeesController,
                    ),
                    const SizedBox(height: 15),
                    _buildField('Location', _locationController),
                    const SizedBox(height: 15),
                    _buildField('Contact Person', _contactPersonController),
                    const SizedBox(height: 15),
                    _buildField('Contact Details', _contactDetailsController),
                    const SizedBox(height: 15),

                    // Catering toggle and details
                    Row(
                      children: [
                        const Text('Catering Service:'),
                        const SizedBox(width: 10),
                        Switch(
                          value: _isCatering,
                          onChanged: _isEditing
                              ? (val) => setState(() {
                                  _isCatering = val;
                                  if (!val) {
                                    _paxController.clear();
                                    _cateringDetailsController.clear();
                                    _selectedScope = null;
                                  }
                                })
                              : null,
                        ),

                        Text(_isCatering ? 'Yes' : 'No'),
                      ],
                    ),
                    if (_isCatering) ...[
                      const SizedBox(height: 15),
                      _buildField(
                        'Pax',
                        _paxController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scope of Service',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: _scopeOptions.map((option) {
                                return ChoiceChip(
                                  label: Text(option),
                                  selected: _selectedScope == option,
                                  onSelected: _isEditing
                                      ? (selected) {
                                          setState(() {
                                            _selectedScope = selected
                                                ? option
                                                : null;
                                          });
                                        }
                                      : null,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildField(
                        'Catering Details (optional)',
                        _cateringDetailsController,
                        hint: 'e.g., buffet, plated meal, halal, vegetarian',
                        maxLines: 3,
                      ),
                    ],

                    const SizedBox(height: 15),
                    _buildField(
                      'Amount (₱)',
                      _amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(
                      height: 80,
                    ), // give some bottom padding so content isn't hidden under payment bar
                  ],
                ),
              ),
            ),

            // Sticky payment section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Paid Amount: ₱$_paidAmount',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Remaining: ₱${(int.tryParse(_amountController.text) ?? 0) - _paidAmount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _paymentController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'New Payment',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _recordPayment,
                        child: const Text('Record'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    int maxLines = 1,
  }) {
    return AbsorbPointer(
      absorbing: !_isEditing,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: _isEditing ? hint : null,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[200],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
