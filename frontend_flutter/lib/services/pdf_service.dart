import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';

import '../models/project_model.dart';
import '../models/evaluation_model.dart';

class PdfService {
  static Future<void> generateAndShowCertificate({
    required Project project,
    required Evaluation evaluation,
  }) async {
    final pdf = pw.Document();

    // Try loading a font if necessary, but default Helvetica works
    // final font = await PdfGoogleFonts.poppinsRegular();
    
    // Fallbacks just in case
    final teamName = project.teamName ?? 'Equipo Sin Nombre';
    final projTitle = project.title ?? 'Proyecto';
    final score = evaluation.generalScore ?? 0.0;
    final badge = evaluation.badgeEarned;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber800, width: 4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  'CERTIFICADO DE EVALUACIÓN',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                ),
                pw.SizedBox(height: 40),
                pw.Text('Se otorga el presente documento a:', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text(
                  teamName,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Por la presentación y desarrollo del proyecto:', style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text(
                  '"$projTitle"',
                  style: pw.TextStyle(fontSize: 22, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center
                ),
                pw.SizedBox(height: 40),
                
                // Score Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                    border: pw.Border.all(color: PdfColors.grey300)
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('Calificación Final', style: const pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '${score.toStringAsFixed(1)} / 100',
                        style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: score >= 70 ? PdfColors.green700 : PdfColors.red700),
                      ),
                    ]
                  )
                ),
                
                pw.SizedBox(height: 40),
                if (badge != null && badge.isNotEmpty) ...[
                  pw.Text('⭐️ RECONOCIMIENTO ESPECIAL ⭐️', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                  pw.SizedBox(height: 5),
                  pw.Text(badge, style: pw.TextStyle(fontSize: 20, color: PdfColors.orange800)),
                  pw.SizedBox(height: 40),
                ],
                
                pw.Spacer(),
                
                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 150, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 5),
                        pw.Text('Comité Evaluador', style: const pw.TextStyle(fontSize: 14)),
                      ]
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Kiosko IA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.Text(DateTime.now().toString().split(' ')[0], style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                      ]
                    )
                  ]
                )
              ],
            ),
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/certificado_${project.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Open the file natively
      await OpenFilex.open(file.path);
    } catch (e) {
      // In case OpenFilex fails or directory issue
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }
}
