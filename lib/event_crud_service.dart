import 'event.dart';
import 'csv_service.dart';

class EventCrudService {
  static List<Event> _allEvents = [];
  static List<MapEntry<int, Event>> _visibleEvents = [];

  static List<Event> get allEvents => _allEvents;

  static List<MapEntry<int, Event>> get visibleEvents => _visibleEvents;

  static List<MapEntry<int, Event>> get completedEvents => _allEvents
      .asMap()
      .entries
      .where((entry) => entry.value.isCompleted)
      .toList();

  static Future<void> loadEvents() async {
    final loadedEvents = await CSVService.loadAllEvents();
    _allEvents = loadedEvents;
    _updateVisibleEvents();
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
    final realIndexesToDelete =
        visibleIndexes
            .map((visibleIndex) => _visibleEvents[visibleIndex].key)
            .toList()
          ..sort(
            (a, b) => b.compareTo(a),
          ); // remove from back to avoid reindexing issues

    for (var realIndex in realIndexesToDelete) {
      _allEvents.removeAt(realIndex);
    }

    _updateVisibleEvents();
    saveEvents();
  }

  static void _updateVisibleEvents() {
    _visibleEvents = _allEvents
        .asMap()
        .entries
        .where((entry) => !entry.value.isCompleted)
        .toList();
  }
}
