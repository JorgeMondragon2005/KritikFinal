import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/evaluation_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'evaluation_screen.dart';

class SubmissionListScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String userId;

  const SubmissionListScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.userId,
  });

  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  final ApiService _apiService = ApiService();
  List<Project> _projects = [];
  Map<String, Evaluation?> _evaluations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _apiService.getProjects(assignmentId: widget.assignmentId);
      
      // Load evaluations for each project to show status
      Map<String, Evaluation?> evaluations = {};
      for (var p in projects) {
        if (p.id != null) {
          evaluations[p.id!] = await _apiService.getEvaluationByProjectId(p.id!);
        }
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _evaluations = evaluations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar entregas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entregas: ${widget.assignmentTitle}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay entregas para esta convocatoria todavía',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final p = _projects[index];
                    final eval = _evaluations[p.id];
                    final isEvaluated = eval != null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEvaluated ? Colors.green.shade100 : AppColors.primaryYellow.withOpacity(0.2),
                          child: Icon(
                            isEvaluated ? Icons.check : Icons.pending_actions,
                            color: isEvaluated ? Colors.green : AppColors.primaryYellow,
                          ),
                        ),
                        title: Text(p.teamName ?? p.title ?? 'Sin nombre'),
                        subtitle: Text(isEvaluated 
                          ? 'Calificado: ${eval.scores?.values.fold(0, (a, b) => a + b) ?? 0} pts'
                          : 'Pendiente de calificar'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EvaluationScreen(
                                  projectId: p.id,
                                  projectName: p.teamName ?? p.title ?? 'Proyecto',
                                  // Pass teacher ID for evaluation
                                  evaluatorId: widget.userId, 
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadSubmissions();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEvaluated ? Colors.grey.shade200 : AppColors.primaryYellow,
                            foregroundColor: isEvaluated ? Colors.black54 : Colors.black,
                            elevation: isEvaluated ? 0 : 2,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(isEvaluated ? 'Revisar' : 'Calificar'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
