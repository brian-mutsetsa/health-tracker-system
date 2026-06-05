import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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
            }),

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

  static Future<void> generateWeeklyAnalyticsReport(
    Map<String, dynamic> stats,
    Map<String, int> conditionCounts,
    Map<String, int> riskCounts,
    String providerNotes,
  ) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final primaryTeal = PdfColor.fromHex('#1B9C85');
    final darkText = PdfColor.fromHex('#212529');
    
    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HEALTH TRACKER SYSTEM',
                        style: pw.TextStyle(font: fontBold, fontSize: 24, color: primaryTeal),
                      ),
                      pw.Text(
                        'Weekly Analytics Report',
                        style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text('Date: $dateStr', style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // KPI Section
              pw.Text('Key Performance Indicators', style: pw.TextStyle(font: fontBold, fontSize: 18, color: darkText)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBox('Total Patients', '${stats['total_patients'] ?? 0}', font, fontBold, primaryTeal),
                  _buildStatBox('High Risk', '${stats['high_risk'] ?? 0}', font, fontBold, PdfColors.red),
                  _buildStatBox('Total Check-ins', '${stats['total_checkins'] ?? 0}', font, fontBold, primaryTeal),
                ],
              ),
              pw.SizedBox(height: 30),

              // Breakdown Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Risk
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Risk Distribution', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                        pw.SizedBox(height: 8),
                        ...riskCounts.entries.map((e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(e.key, style: pw.TextStyle(font: font, fontSize: 12)),
                              pw.Text('${e.value}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                            ]
                          )
                        )).toList(),
                      ]
                    )
                  ),
                  pw.SizedBox(width: 40),
                  // Conditions
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Condition Breakdown', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                        pw.SizedBox(height: 8),
                        ...conditionCounts.entries.take(6).map((e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(e.key, style: pw.TextStyle(font: font, fontSize: 12)),
                              pw.Text('${e.value}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                            ]
                          )
                        )).toList(),
                      ]
                    )
                  ),
                ]
              ),
              
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Provider Notes
              pw.Text('Provider Clinical Notes & Observations', style: pw.TextStyle(font: fontBold, fontSize: 16, color: darkText)),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  providerNotes.isEmpty ? 'No notes provided for this week.' : providerNotes,
                  style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 2),
                ),
              ),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text('-- End of Weekly Report --', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Analytics_Weekly_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildStatBox(String title, String value, pw.Font font, pw.Font fontBold, PdfColor color) {
    return pw.Container(
      width: 130,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 24, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
    );
  }
}
