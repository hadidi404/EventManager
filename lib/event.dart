import 'package:intl/intl.dart';

class Event {
  final String name;
  final String dateTime;
  final String attendees;
  final String amount;
  int paidAmount;
  final String location;
  final String contactPerson;
  final String contactDetails;
  final bool CateringService;
  final String? pax;
  final String? scopeOfService;
  final String? cateringDetails;
  Event({
    required this.name,
    required this.dateTime,
    required this.attendees,
    required this.amount,
    this.paidAmount = 0, // Default to 0
    required this.location,
    required this.contactPerson,
    required this.contactDetails,
    this.CateringService = false,
    this.pax,
    this.scopeOfService,
    this.cateringDetails,
  });

  List<String> toList() {
    return [
      name,
      dateTime,
      attendees,
      amount,
      paidAmount.toString(),
      location,
      contactPerson,
      contactDetails,
      CateringService ? 'Yes' : 'No',
      pax ?? '',
      scopeOfService ?? '',
      cateringDetails ?? '',
    ];
  }

  factory Event.fromList(List<dynamic> list) {
    return Event(
      name: list[0].toString(),
      dateTime: list[1].toString(),
      attendees: list[2].toString(),
      amount: list[3].toString(),
      paidAmount: list.length > 4 ? int.tryParse(list[4].toString()) ?? 0 : 0,
      location: list.length > 5 ? list[5].toString() : '',
      contactPerson: list.length > 6 ? list[6].toString() : '',
      contactDetails: list.length > 7 ? list[7].toString() : '',
      CateringService: list.length > 8
          ? (() {
              final v = list[8].toString().toLowerCase();
              return v == 'true' || v == 'yes';
            })()
          : false,
      pax: list.length > 9 ? list[9].toString() : '',
      scopeOfService: list.length > 10 ? list[10].toString() : '',
      cateringDetails: list.length > 11 ? list[11].toString() : '',
    );
  }

  bool get isCompleted {
    try {
      final eventDate = DateFormat('yyyy-MM-dd hh:mm a').parse(dateTime);
      final now = DateTime.now();
      final totalAmount = int.tryParse(amount) ?? 0;
      return paidAmount >= totalAmount && eventDate.isBefore(now);
    } catch (e) {
      return false; // If parsing fails, consider it not completed
    }
  }
}
