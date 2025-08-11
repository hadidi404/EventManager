import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'csv_service.dart';
import 'event.dart';

class ExcelExportService {
  static Future<File> _createExcel(List<Event> events) async {
    var excel = Excel.createExcel();

    void debugPrintSheetNames(Excel excel) {
      for (var sheetName in excel.sheets.keys) {
        debugPrint('✅ Sheet name: $sheetName');
      }
    }

    final fullyPaid = events
        .where((e) => e.paidAmount >= (int.tryParse(e.amount) ?? 0))
        .toList();
    final notFullyPaid = events
        .where((e) => e.paidAmount < (int.tryParse(e.amount) ?? 0))
        .toList();

    fullyPaid.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    notFullyPaid.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    List<String> headers = [
      'Event Name',
      'Date & Time',
      'Attendees',
      'Amount',
      'Paid Amount',
      'Location',
      'Contact Person',
      'Contact Details',
      'Catering',
      'Pax',
      'Service Scope',
      'Catering Details',
    ];

    // Use default 'Sheet1' as Fully Paid sheet
    Sheet sheetPaid = excel['Sheet1'];

    // Clear existing rows from Sheet1
    for (int i = sheetPaid.maxRows - 1; i >= 0; i--) {
      sheetPaid.removeRow(i);
    }

    // Add headers and fully paid events
    sheetPaid.appendRow(headers);
    for (var e in fullyPaid) {
      sheetPaid.appendRow(e.toList());
    }

    // Create and fill Not Fully Paid sheet
    Sheet sheetNotPaid = excel['Not Fully Paid'];
    sheetNotPaid.appendRow(headers);
    for (var e in notFullyPaid) {
      sheetNotPaid.appendRow(e.toList());
    }

    debugPrintSheetNames(excel);

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/events_export.xlsx';

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  static Future<void> shareExcel() async {
    final events = await CSVService.loadEvents();
    final file = await _createExcel(events);
    await Share.shareXFiles([XFile(file.path)], text: 'Events Excel Report');
  }
}
