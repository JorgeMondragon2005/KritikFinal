import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import '../models/assignment_model.dart';
import '../theme/app_theme.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String teacherId;
  const TeacherDashboardScreen({super.key, required this.teacherId});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _totalProjects = 0;
  int _evaluatedCount = 0;
  double _averageScore = 0.0;
  Map<String, int> _techCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _apiService.getProjects(teacherId: widget.teacherId);
      
      int evaluated = 0;
      double sumAverage = 0;
      Map<String, int> techs = {};
      Map<String, Assignment> assignmentCache = {};

      for (var p in projects) {
        // Count techs
        for (var t in p.technologies) {
          techs[t] = (techs[t] ?? 0) + 1;
        }

        final evals = await _apiService.getProjectEvaluations(p.id ?? '');
        if (evals.isNotEmpty) {
          evaluated++;
          double projectFinalScore = 0;

          if (p.assignmentId != null) {
            if (!assignmentCache.containsKey(p.assignmentId!)) {
              final a = await _apiService.getAssignmentById(p.assignmentId!);
              if (a != null) assignmentCache[p.assignmentId!] = a;
            }
            final assignment = assignmentCache[p.assignmentId!];

            if (assignment != null && assignment.jurors != null && assignment.jurors!.isNotEmpty) {
              double weightedScore = 0;
              double totalWeightUsed = 0;
              for (var e in evals) {
                var jurorWeight = 0;
                try {
                  final juror = assignment.jurors!.firstWhere((j) => j.userId == e.evaluatorId);
                  jurorWeight = juror.weightPercentage;
                } catch (_) {}

                if (jurorWeight > 0 && e.scores != null) {
                  double eScore = e.scores!.values.fold<double>(0.0, (prev, el) => prev + ((el ?? 0) as num).toDouble());
                  weightedScore += eScore * (jurorWeight / 100.0);
                  totalWeightUsed += jurorWeight;
                }
              }
              // Normalizar en caso de que falten evaluadores (ej. solo evaluó el 50%)
              if (totalWeightUsed > 0) {
                projectFinalScore = weightedScore / (totalWeightUsed / 100.0);
              } else {
                double fallback = evals.fold<double>(0.0, (prev, e) => prev + (e.scores?.values.fold<double>(0.0, (p, el) => p + ((el ?? 0) as num).toDouble()) ?? 0.0));
                projectFinalScore = fallback / evals.length;
              }
            } else {
              double fallback = evals.fold<double>(0.0, (prev, e) => prev + (e.scores?.values.fold<double>(0.0, (p, el) => p + ((el ?? 0) as num).toDouble()) ?? 0.0));
              projectFinalScore = fallback / evals.length;
            }
          } else {
            double fallback = evals.fold<double>(0.0, (prev, e) => prev + (e.scores?.values.fold<double>(0.0, (p, el) => p + ((el ?? 0) as num).toDouble()) ?? 0.0));
            projectFinalScore = fallback / evals.length;
          }

          sumAverage += projectFinalScore;
        }
      }

      setState(() {
        _totalProjects = projects.length;
        _evaluatedCount = evaluated;
        _averageScore = evaluated > 0 ? sumAverage / evaluated : 0;
        _techCounts = techs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Estadísticas'),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStats,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 32),
                _buildTechUsageSection(),
                const SizedBox(height: 32),
                _buildExportButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Proyectos', _totalProjects.toString(), Icons.folder_special, Colors.blue),
            const SizedBox(width: 16),
            _buildStatCard('Evaluados', '$_evaluatedCount/$_totalProjects', Icons.check_circle, Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard('Promedio General', _averageScore.toStringAsFixed(1), Icons.star, AppColors.primaryYellow, isWide: true),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isWide = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: isWide ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTechUsageSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedTechs = _techCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tecnologías más usadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...sortedTechs.take(5).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text('${e.value} proyectos', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _totalProjects > 0 ? e.value / _totalProjects : 0,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                color: AppColors.primaryYellow,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando reporte PDF...')),
        );
      },
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Exportar Reporte de Calificaciones'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
