import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PdfGenerator {
  static Future<void> generateAndDownloadReport(
    Patient patient,
    List<dynamic> checkinsRaw,
  ) async {
    final pdf = pw.Document();

    // Fallback simple font instead of requiring asset preloads for reliable web generation
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final primaryTeal = PdfColor.fromHex('#1B9C85');
    final darkText = PdfColor.fromHex('#212529');

    String dateRange = checkinsRaw.isNotEmpty
        ? '${DateFormat('MMM d, yyyy').format(DateTime.parse(checkinsRaw.last['date']))} - ${DateFormat('MMM d, yyyy').format(DateTime.parse(checkinsRaw.first['date']))}'
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
                      'Provider Medical Extract',
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
                    'Generated via Dashboard',
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
                        'Patient ID: ${patient.patientId}',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Primary Condition: ${patient.condition}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Records: ${checkinsRaw.length}',
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
              'Recorded Check-ins',
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
            ...checkinsRaw.map((checkin) {
              Map<String, dynamic> answers = checkin['answers'] ?? {};
              int severeCount = answers.values
                  .where((v) => v == 'Severe')
                  .length;
              int mildCount = answers.values.where((v) => v == 'Mild').length;
              String meds = answers['q7'] ?? 'N/A';
              String riskLvl = checkin['risk_level'] ?? 'GREEN';
              DateTime date = DateTime.parse(checkin['date']);

              PdfColor riskColor = riskLvl == 'RED'
                  ? PdfColors.red
                  : riskLvl == 'ORANGE'
                  ? PdfColors.orange
                  : riskLvl == 'YELLOW'
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
                        DateFormat('MMM d').format(date),
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        riskLvl,
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

    // This command generates the raw PDF bytes, and triggers a browser file transfer download
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'HealthReport_${patient.patientId}.pdf',
    );
  }
}
