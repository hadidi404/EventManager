import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'event.dart';

class CSVService {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getCsvFile() async {
    return _csvFile;
  }

  static Future<File> get _csvFile async {
    final path = await _localPath;
    return File('$path/events.csv');
  }

  static Future<List<Event>> loadEvents() async {
    try {
      final file = await _csvFile;
      if (!await file.exists()) return [];

      final csvString = await file.readAsString();
      final csvTable = const CsvToListConverter().convert(csvString);

      // Only return events that are not deleted (isDeleted == false)
      return csvTable
          .skip(1)
          .map((e) => Event.fromList(e))
          .where((event) => !event.isDeleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Event>> loadAllEvents() async {
    try {
      final file = await _csvFile;
      if (!await file.exists()) return [];
      final csvString = await file.readAsString();
      final csvTable = const CsvToListConverter().convert(csvString);
      return csvTable.skip(1).map((e) => Event.fromList(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveEvents(List<Event> events) async {
    List<List<String>> csvData = [
      ['Event Name', 'Date & Time', 'Attendees/Organization', 'Amount', 'isDeleted'],
      ...events.map((e) => e.toList()),
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final file = await _csvFile;
    await file.writeAsString(csvString);
  }
}
