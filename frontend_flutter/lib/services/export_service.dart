// lib/services/export_service.dart

import 'package:flutter/foundation.dart';
// Note: These would normally require adding packages to pubspec.yaml
// We will assume standard dart:convert and simple string building for now
// to avoid blocking on pub get if network is restricted.

class ExportService {
  Future<String> generateCsv(List<Map<String, dynamic>> results) async {
    final StringBuffer csv = StringBuffer();
    
    // Header
    csv.writeln('Posicion,Equipo,Categoria,Puntaje Promedio,Votos');
    
    int index = 1;
    for (var r in results) {
      csv.writeln('$index,${r['teamName']},${r['category']},${r['averageScore']},${r['totalVotes']}');
      index++;
    }
    
    return csv.toString();
  }

  // Helper to "download" or share on mobile
  // In a real app we'd use path_provider and share_plus
  Future<void> exportToConsole(String content) async {
    debugPrint('--- RESULTADOS EXPORTADOS ---');
    debugPrint(content);
    debugPrint('--- FIN ---');
  }
}
