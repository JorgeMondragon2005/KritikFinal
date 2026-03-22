import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import '../models/evaluation_model.dart';
import '../theme/app_theme.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String userId;
  final String role; // 'Teacher' o 'Evaluator'

  const AnalyticsDashboardScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  List<Project> _projects = [];
  List<Evaluation> _evaluations = [];

  // KPIs
  double _averageScore = 0.0;
  int _totalEvaluated = 0;
  int _totalPending = 0;
  List<Project> _topProjects = [];

  bool _isGeneratingInsights = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _generateInsights() async {
    if (_projects.isEmpty) return;
    setState(() => _isGeneratingInsights = true);

    try {
      final summaryBuilder = StringBuffer();
      summaryBuilder.writeln("Resultados de la clase:");
      summaryBuilder.writeln(
        "Total de proyectos asignados: ${_projects.length}",
      );
      summaryBuilder.writeln(
        "Proyectos evaluados hasta ahora: $_totalEvaluated",
      );
      summaryBuilder.writeln(
        "Calificacion promedio del grupo: ${_averageScore.toStringAsFixed(1)}/100",
      );

      summaryBuilder.writeln("\nDesglose por proyecto evaluado:");
      for (var p in _projects) {
        final evals = _evaluations.where((e) => e.projectId == p.id).toList();
        if (evals.isNotEmpty) {
          final eval = evals.first;
          summaryBuilder.writeln(
            "- Proyecto: ${p.title} (${p.category}) -> Calificacion: ${eval.generalScore?.toStringAsFixed(1)}/100",
          );
          if (eval.detailedScores != null && eval.detailedScores!.isNotEmpty) {
            summaryBuilder.writeln("  Rubros:");
            eval.detailedScores!.forEach((criterio, puntos) {
              summaryBuilder.writeln("    * $criterio: $puntos pts");
            });
          }
        }
      }

      final insightsMarkdown = await _apiService.generateAnalyticsInsights(
        summaryBuilder.toString(),
      );

      if (!mounted) return;
      if (insightsMarkdown != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                SizedBox(width: 8),
                Text('Insights del Grupo (IA)'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                insightsMarkdown,
                style: const TextStyle(height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar insights')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingInsights = false);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch raw data
      final projects = await _apiService.getProjects();
      final List<Evaluation> evaluations =
          []; // We need a way to fetch all evaluations or fetch by project iteratively.

      // Let's grab evaluations for all projects (could be heavy in a real prod app without a direct endpoint, but ok for now)
      for (var p in projects) {
        if (p.id != null) {
          final eval = await _apiService.getEvaluationByProjectId(p.id!);
          if (eval != null) {
            evaluations.add(eval);
          }
        }
      }

      // 2. Filter data depending on Role
      if ((widget.role.toLowerCase() == 'teacher' ||
          widget.role.toLowerCase() == 'profesor')) {
        _projects = projects
            .where((p) => p.assignedTeacherId == widget.userId)
            .toList();
      } else if ((widget.role.toLowerCase() == 'evaluator' ||
          widget.role.toLowerCase() == 'profesor')) {
        // Evaluators ideally see all, or only ones assigned to them. Assuming they see all published ones for the event.
        _projects = projects
            .where((p) => p.status?.toLowerCase() != 'pending')
            .toList();
      }

      // 3. Compute Metrics
      _totalEvaluated = 0;
      double sumScores = 0;

      // Relate projects to evaluations
      final evaluatedProjectIds = evaluations.map((e) => e.projectId).toSet();

      for (var proj in _projects) {
        if (evaluatedProjectIds.contains(proj.id)) {
          _totalEvaluated++;
          final projEval = evaluations.firstWhere(
            (e) => e.projectId == proj.id,
          );
          sumScores += projEval.generalScore ?? 0.0;
        } else {
          _totalPending++;
        }
      }

      if (_totalEvaluated > 0) {
        _averageScore = sumScores / _totalEvaluated;
      }

      // Top Projects (Sort by score DESC)
      final allEvalsScored = evaluations
          .where((e) => _projects.any((p) => p.id == e.projectId))
          .toList();
      allEvalsScored.sort(
        (a, b) => (b.generalScore ?? 0).compareTo(a.generalScore ?? 0),
      );

      _topProjects = allEvalsScored
          .take(3)
          .map((e) => _projects.firstWhere((p) => p.id == e.projectId))
          .toList();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }

    if (mounted) {
      setState(() {
        _evaluations = evaluations;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    if (_projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/Reporte_Evaluaciones.csv');

      // Create CSV content
      final buffer = StringBuffer();
      // Write BOM for Excel UTF-8 compatibility
      buffer.write('\uFEFF');

      // Headers
      buffer.writeln('Proyecto,Equipo,Categoria,Puntaje_Promedio,Estado');

      for (var project in _projects) {
        final eval = _evaluations
            .where((e) => e.projectId == project.id)
            .toList();
        double _score = 0;
        if (eval.isNotEmpty) {
          _score = eval.first.generalScore ?? 0.0; // Simplification, get first
        }

        // Escape CSV fields
        final title =
            '"${(project.title ?? 'Sin Título').replaceAll('"', '""')}"';
        final team = '"${(project.teamName ?? 'SN').replaceAll('"', '""')}"';
        final category =
            '"${(project.category ?? 'N/A').replaceAll('"', '""')}"';
        final state = eval.isNotEmpty ? '"Evaluado"' : '"Pendiente"';

        buffer.writeln('$title,$team,$category,$_score,$state');
      }

      await file.writeAsString(buffer.toString(), encoding: utf8);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Abriendo reporte...')));

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No hay app instalada para abrir CSV. ${result.message}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar Excel/CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primaryYellow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Resumen General',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (widget.role.toLowerCase() == 'teacher' ||
                        widget.role.toLowerCase() == 'profesor') ...[
                      OutlinedButton.icon(
                        onPressed: _isGeneratingInsights
                            ? null
                            : _generateInsights,
                        icon: _isGeneratingInsights
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                color: Colors.purple,
                              ),
                        label: Text(
                          _isGeneratingInsights
                              ? 'Analizando rúbricas...'
                              : 'Generar Insights del Grupo con IA',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildKPIsRow(),
                    const SizedBox(height: 32),
                    Text(
                      'Progreso de Evaluaciones',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildChart(),
                    const SizedBox(height: 32),
                    Text(
                      'Top 3 Proyectos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProjects(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPIsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Promedio Global',
            '${_averageScore.toStringAsFixed(1)} / 100',
            Icons.analytics,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Proyectos Evaluados',
            '$_totalEvaluated / ${_projects.length}',
            Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryYellow, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_projects.isEmpty) {
      return const Center(child: Text('No hay proyectos para analizar'));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              color: Colors.green,
              value: _totalEvaluated.toDouble(),
              title:
                  '${((_totalEvaluated / _projects.length) * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: AppColors.primaryYellow,
              value: _totalPending.toDouble(),
              title:
                  '${((_totalPending / _projects.length) * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProjects() {
    if (_topProjects.isEmpty) {
      return const Text('Aún no hay proyectos evaluados');
    }

    return Column(
      children: _topProjects.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Color medalColor;
        switch (index) {
          case 0:
            medalColor = const Color(0xFFFFD700);
            break; // Oro
          case 1:
            medalColor = const Color(0xFFC0C0C0);
            break; // Plata
          case 2:
            medalColor = const Color(0xFFCD7F32);
            break; // Bronce
          default:
            medalColor = Colors.grey;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: medalColor.withOpacity(0.2),
              child: Icon(Icons.emoji_events, color: medalColor),
            ),
            title: Text(
              project.title ?? 'Sin título',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(project.teamName ?? 'Equipo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              // Navigator.push to details if desired. Keep simple for now.
            },
          ),
        );
      }).toList(),
    );
  }
}
