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
}
