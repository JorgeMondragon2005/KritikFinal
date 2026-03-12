// lib/screens/results_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();
  final ExportService _exportService = ExportService();
  bool _isLoading = true;
  List<dynamic> _rankings = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final results = await _apiService.getRankings();
    setState(() {
      _rankings = results;
      _isLoading = false;
    });
  }

  Future<void> _handleExport() async {
    final csv = await _exportService.generateCsv(_rankings.cast<Map<String, dynamic>>());
    await _exportService.exportToConsole(csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ranking exportado correctamente (+ ver consola)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Live', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_rankings.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay resultados aún', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Las evaluaciones aparecerán aquí en tiempo real.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _loadResults, child: const Text('Actualizar')),
                ],
              ),
            )
          : Column(
              children: [
                _buildStatsHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _rankings.length,
                    itemBuilder: (context, index) => _buildRankingCard(_rankings[index], index),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Integridad: 98.2%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          Text('Votos: 45', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> rank, int index) {
    final color = index == 0 ? Colors.amber : index == 1 ? Colors.grey : index == 2 ? Colors.brown : Colors.blueGrey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(rank['teamName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(rank['category']),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${rank['averageScore']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.orange)),
            Text('pts', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: _handleExport,
        icon: const Icon(Icons.download),
        label: const Text('Exportar Reporte Comercial'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
