import 'package:event_manager_2/utils/date_time_helper.dart';
import 'package:flutter/material.dart';
import 'event.dart';
import 'csv_service.dart';

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

  bool _isEditing = false;
  late int _paidAmount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _attendeesController = TextEditingController(text: widget.event.attendees);
    _dateTimeController = TextEditingController(text: widget.event.dateTime);
    _amountController = TextEditingController(text: widget.event.amount);
    _paymentController = TextEditingController();
    _paidAmount = widget.event.paidAmount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attendeesController.dispose();
    _dateTimeController.dispose();
    _amountController.dispose();
    _paymentController.dispose();
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
    );

    allEvents[widget.index] = updated;
    await CSVService.saveEvents(allEvents);
    widget.onUpdate();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final total = int.tryParse(_amountController.text) ?? 0;
    final remaining = total - _paidAmount;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('Event Name', _nameController),
            const SizedBox(height: 15),
            _isEditing
                ? GestureDetector(
                    onTap: () async {
                      final picked = await DateTimePickerHelper.pickDateTime(
                        context,
                      );
                      if (picked != null) {
                        setState(() {
                          _dateTimeController.text = picked.toIso8601String();
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: _buildField('Date & Time', _dateTimeController),
                    ),
                  )
                : _buildField('Date & Time', _dateTimeController),
            const SizedBox(height: 15),
            _buildField('Attendees / Organization', _attendeesController),
            const SizedBox(height: 15),
            _buildField(
              'Amount (₱)',
              _amountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            Text('Paid Amount: ₱$_paidAmount'),
            Text('Remaining: ₱$remaining'),
            const SizedBox(height: 15),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Payment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _recordPayment,
              child: const Text('Record Payment'),
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
  }) {
    return AbsorbPointer(
      absorbing: !_isEditing,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
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
