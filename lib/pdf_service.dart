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

    // Remove the isDeleted column (last column) from header and data rows, but keep all rows (including deleted)
    final filteredTable = [
      csvTable.first.sublist(0, 4), // header without isDeleted
      ...csvTable.skip(1).map((row) => row.sublist(0, 4)),
    ];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            data: filteredTable,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
