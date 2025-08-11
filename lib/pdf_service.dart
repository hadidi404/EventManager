import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'csv_service.dart';
import 'package:csv/csv.dart';

class PDFService {
  static Future<void> generateAndPrintPDF() async {
    final pdf = pw.Document();
    final file = await CSVService.getCsvFile();

    if (!(await file.exists())) return;

    final csvString = await file.readAsString();
    final csvTable = const CsvToListConverter().convert(csvString);

    const excludedIndexes = [11];

    final filteredTable = [
      [
        for (int i = 0; i < csvTable.first.length; i++)
          if (!excludedIndexes.contains(i)) csvTable.first[i].toString(),
      ],
      ...csvTable.skip(1).map((row) {
        return [
          for (int i = 0; i < row.length; i++)
            if (!excludedIndexes.contains(i)) row[i].toString(),
        ];
      }),
    ];

    // Define column widths
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.5), // Event Name
      1: const pw.FlexColumnWidth(2.3), // Date & Time
      2: const pw.FlexColumnWidth(2.5), // Attendees
      3: const pw.FlexColumnWidth(1.8), // Amount
      4: const pw.FlexColumnWidth(1.8), // Paid Amount
      5: const pw.FlexColumnWidth(2.5), // Location
      6: const pw.FlexColumnWidth(2), // Contact Person
      7: const pw.FlexColumnWidth(2.3), // Contact Details
      8: const pw.FlexColumnWidth(1), // Catering Service
      9: const pw.FlexColumnWidth(1), // Pax
      10: const pw.FlexColumnWidth(2), // Scope of Service
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          final headers = filteredTable.first;
          final dataRows = filteredTable.skip(1).toList();

          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: columnWidths,
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: headers.map((text) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
                // Data rows
                ...dataRows.map((row) {
                  return pw.TableRow(
                    children: row.map((cell) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(cell, softWrap: true),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
