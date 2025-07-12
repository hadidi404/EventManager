import 'event.dart';
import 'csv_service.dart';

class EventCrudService {
  static List<Event> _allEvents = [];
  static List<MapEntry<int, Event>> _visibleEvents = [];

  static List<Event> get allEvents => _allEvents;
  static List<MapEntry<int, Event>> get visibleEvents => _visibleEvents;

  static Future<void> loadEvents() async {
    final loadedEvents = await CSVService.loadAllEvents();
    _allEvents = loadedEvents;
    _visibleEvents = _allEvents
        .asMap()
        .entries
        .where((entry) => !entry.value.isDeleted)
        .toList();
  }

  static Future<void> saveEvents() async {
    await CSVService.saveEvents(_allEvents);
  }

  static void addEvent(Event event) {
    _allEvents.add(event);
    _updateVisibleEvents();
    saveEvents();
  }

  static void deleteEventsByVisibleIndexes(Set<int> visibleIndexes) {
    final realIndexesToDelete = visibleIndexes
        .map((visibleIndex) => _visibleEvents[visibleIndex].key)
        .toList();

    for (var realIndex in realIndexesToDelete) {
      final event = _allEvents[realIndex];
      _allEvents[realIndex] = Event(
        name: event.name,
        dateTime: event.dateTime,
        attendees: event.attendees,
        amount: event.amount,
        isDeleted: true,
      );
    }

    _updateVisibleEvents();
    saveEvents();
  }

  static void _updateVisibleEvents() {
    _visibleEvents = _allEvents
        .asMap()
        .entries
        .where((entry) => !entry.value.isDeleted)
        .toList();
  }
}
