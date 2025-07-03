class Event {
  final String name;
  final String dateTime;
  final String attendees;
  final String amount;
  final bool isDeleted;

  Event({
    required this.name,
    required this.dateTime,
    required this.attendees,
    required this.amount,
    this.isDeleted = false,
  });

  List<String> toList() {
    return [name, dateTime, attendees, amount, isDeleted.toString()];
  }

  factory Event.fromList(List<dynamic> list) {
    return Event(
      name: list[0].toString(),
      dateTime: list[1].toString(),
      attendees: list[2].toString(),
      amount: list[3].toString(),
      isDeleted: list.length > 4 ? (list[4].toString().toLowerCase() == 'true') : false,
    );
  }
}

