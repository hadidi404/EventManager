import 'package:intl/intl.dart';

class Event {
  final String name;
  final String dateTime;
  final String attendees;
  final String amount;
  int paidAmount;
  final bool isDeleted;

  Event({
    required this.name,
    required this.dateTime,
    required this.attendees,
    required this.amount,
    this.paidAmount = 0, // Default to 0
    this.isDeleted = false,
  });

  List<String> toList() {
    return [
      name,
      dateTime,
      attendees,
      amount,
      paidAmount.toString(),
      isDeleted.toString(),
    ];
  }

  factory Event.fromList(List<dynamic> list) {
    return Event(
      name: list[0].toString(),
      dateTime: list[1].toString(),
      attendees: list[2].toString(),
      amount: list[3].toString(),
      paidAmount: list.length > 4 ? int.tryParse(list[4].toString()) ?? 0 : 0,
      isDeleted: list.length > 5 && list[5].toString().toLowerCase() == 'true',
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
