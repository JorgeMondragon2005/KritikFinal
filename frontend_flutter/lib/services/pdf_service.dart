import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';

import '../services/api_service.dart';
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
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColor.fromHex('#F59E0B'), width: 8),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#D97706'), width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'CERTIFICADO DE EXCELENCIA',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#92400E')),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Se otorga el presente reconocimiento a:', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    teamName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 25),
                  pw.Text('Por su destacada presentación y desarrollo del proyecto:', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    '"$projTitle"',
                    style: pw.TextStyle(fontSize: 20, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('#1E3A8A')),
                    textAlign: pw.TextAlign.center
                  ),
                  pw.SizedBox(height: 40),
                  
                  // Score Box
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB'))
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Calificación Final Obtenida', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          '${score.toStringAsFixed(1)} / 100',
                          style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: score >= 70 ? PdfColors.green800 : PdfColors.red800),
                        ),
                      ]
                    )
                  ),
                  
                  pw.SizedBox(height: 30),
                  if (badge != null && badge.isNotEmpty) ...[
                    pw.Text('✦ RECONOCIMIENTO ESPECIAL ✦', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D97706'))),
                    pw.SizedBox(height: 5),
                    pw.Text(badge.toUpperCase(), style: pw.TextStyle(fontSize: 18, color: PdfColor.fromHex('#B45309'), fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                  ],
                  
                  pw.Spacer(),
                  
                  // Signatures
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 8),
                          pw.Text('Comité Evaluador', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Kiosko IA', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ]
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Emitido a través de la plataforma web', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.SizedBox(height: 4),
                          pw.Text('Fecha: ${DateTime.now().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ]
                      )
                    ]
                  )
                ],
              ),
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

  static Future<void> generateGlobalClassReport(String teacherId) async {
    final apiService = ApiService();
    try {
      final assignments = await apiService.getAssignments(teacherId: teacherId);
      
      final Map<String, List<Project>> assignmentProjects = {};
      final Map<String, Evaluation?> projectEvals = {};
      
      for (var a in assignments) {
        if (a.id == null) continue;
        final projects = await apiService.getProjects(assignmentId: a.id);
        assignmentProjects[a.id!] = projects;
        
        for (var p in projects) {
          if (p.id != null && p.status?.toLowerCase() == 'evaluado') {
             projectEvals[p.id!] = await apiService.getEvaluationByProjectId(p.id!);
          }
        }
      }
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final List<pw.Widget> content = [
              pw.Text('Reporte Global Académico', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 10),
              pw.Text('Generado el: ${DateTime.now().toString().split(' ')[0]}'),
              pw.SizedBox(height: 20),
            ];
            
            if (assignments.isEmpty) {
               content.add(pw.Text('No hay convocatorias creadas o proyectos recibidos.'));
               return content;
            }

            for (var a in assignments) {
               content.add(
                 pw.Container(
                   margin: const pw.EdgeInsets.only(top: 15, bottom: 5),
                   padding: const pw.EdgeInsets.all(8),
                   color: PdfColors.grey200,
                   child: pw.Text(a.title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))
                 )
               );
               
               final projs = assignmentProjects[a.id];
               if (projs == null || projs.isEmpty) {
                 content.add(pw.Text('  Sin entregas registradas.', style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)));
                 continue;
               }
               
               for (var p in projs) {
                  final eval = projectEvals[p.id];
                  double? score;
                  if (eval != null) {
                     score = eval.generalScore ?? (eval.detailedScores?.values.fold(0.0, (sum, v) => (sum as double) + v));
                  }
                  final scoreText = score != null ? score.toStringAsFixed(1) : 'Pendiente';
                  
                  content.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 20, bottom: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text('• ${p.teamName ?? "Alumno desconocido"} - ${p.category ?? ""}')),
                          pw.Text(scoreText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ]
                      )
                    )
                  );
               }
            }
            return content;
          }
        )
      );
      
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_global_$teacherId.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
      
    } catch (e) {
       // In case of any silent failure it won't crash the app
    }
  }
}
