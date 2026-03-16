import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/checkin_model.dart';

class PdfGenerator {
  static Future<File> generateReport(
    String patientId,
    List<CheckinModel> checkins,
  ) async {
    final pdf = pw.Document();

    // Fallback simple font instead of requiring asset preloads to ensure offline generation is flawless
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final primaryTeal = PdfColor.fromHex('#1B9C85');
    final darkText = PdfColor.fromHex('#212529');

    String condition = checkins.isNotEmpty
        ? checkins.first.condition
        : 'Unknown';
    String dateRange = checkins.isNotEmpty
        ? '${DateFormat('MMM d, yyyy').format(checkins.last.date)} - ${DateFormat('MMM d, yyyy').format(checkins.first.date)}'
        : DateFormat('MMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HEALTH TRACKER SYSTEM',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 24,
                        color: primaryTeal,
                      ),
                    ),
                    pw.Text(
                      'Patient Medical Report',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Offline Generation',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Patient Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryTeal, width: 2),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient ID: $patientId',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Primary Condition: $condition',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Records: ${checkins.length}',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Period: $dateRange',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            pw.Text(
              'Check-in History Ledger',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
                color: darkText,
              ),
            ),
            pw.SizedBox(height: 10),

            // Data Table header
            pw.Container(
              color: primaryTeal,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Date',
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Risk Level',
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Symptoms Noted',
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Medication',
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Rows
            ...checkins.map((checkin) {
              int severeCount = checkin.answers.values
                  .where((v) => v == 'Severe')
                  .length;
              int mildCount = checkin.answers.values
                  .where((v) => v == 'Mild')
                  .length;
              String meds = checkin.answers['q7'] ?? 'N/A';

              PdfColor riskColor = checkin.riskLevel == 'RED'
                  ? PdfColors.red
                  : checkin.riskLevel == 'ORANGE'
                  ? PdfColors.orange
                  : checkin.riskLevel == 'YELLOW'
                  ? PdfColors.amber700
                  : PdfColors.green;

              return pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 1),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('MMM d').format(checkin.date),
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        checkin.riskLevel,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: riskColor,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        '$severeCount Severe, $mildCount Mild',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        meds,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: meds == 'Yes'
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            pw.SizedBox(height: 30),
            pw.Text(
              '-- End of Report --',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    final fileName =
        'HealthReport_${patientId}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

    final bytes = await pdf.save();

    File file;
    if (Platform.isAndroid) {
      // Direct save to user-visible internal storage (Downloads directory)
      Directory dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir =
            (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      }
      file = File('${dir.path}/$fileName');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      file = File('${appDir.path}/$fileName');
    }

    // Write file directly to internal storage
    await file.writeAsBytes(bytes);

    // Also trigger native share/save dialog for the user, just in case
    await Printing.sharePdf(bytes: bytes, filename: fileName);

    return file;
  }
}
