import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

import '../services/api_service.dart';
import '../models/evaluation_model.dart';
import '../models/rubric_model.dart';

class EvaluationScreen extends StatefulWidget {
  final String? projectId;
  final String projectName;
  final String? evaluatorId;

  const EvaluationScreen({super.key, this.projectId, required this.projectName, this.evaluatorId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  
  List<Rubric> _rubrics = [];
  Rubric? _selectedRubric;
  Map<String, int> _detailedScores = {};
  Project? _project;
  bool _isLoadingProject = false;
  
  String? _evidencePath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRubrics();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    if (widget.projectId == null) return;
    setState(() => _isLoadingProject = true);
    try {
      final projects = await _apiService.getProjects();
      if (mounted) {
        setState(() {
          _project = projects.firstWhere((p) => p.id == widget.projectId);
          _isLoadingProject = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading project details: $e');
      if (mounted) setState(() => _isLoadingProject = false);
    }
  }

  Future<void> _openFileExternally(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el archivo. Intenta copiar el enlace.')),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _loadRubrics() async {
    final rubrics = await _apiService.getRubrics();
    if (mounted) {
      setState(() {
        _rubrics = rubrics;
        if (_rubrics.isNotEmpty) {
          _selectedRubric = _rubrics.first;
          _initializeScores();
        }
      });
    }
  }

  void _initializeScores() {
    if (_selectedRubric != null) {
      final items = _selectedRubric!.items;
      _detailedScores = { for (var item in items) item.criteria : item.maxPoints };
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Optimize size
      );
      
      if (photo != null) {
        setState(() {
          _evidencePath = photo.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la cámara: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró el ID del proyecto')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? base64Photo;
      if (_evidencePath != null) {
        final bytes = await File(_evidencePath!).readAsBytes();
        base64Photo = base64Encode(bytes);
      }

      if (!mounted) return;
      final evaluation = Evaluation(
        projectId: widget.projectId,
        evaluatorId: widget.evaluatorId ?? "evaluator_unknown",
        rubricId: _selectedRubric?.id,
        scores: {"General": _detailedScores.values.fold(0, (a, b) => a + b)}, 
        detailedScores: _detailedScores,
        feedback: _commentController.text,
        evidencePhotoBase64: base64Photo,
      );

      final success = await _apiService.submitEvaluation(evaluation);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Evaluación enviada con éxito!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la evaluación')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluar Proyecto'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isSubmitting 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.projectName, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingProject)
                    const LinearProgressIndicator()
                  else if (_project != null) ...[
                    const Text('Archivos Entregados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    
                    // Show Videos
                    if (_project!.videos.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('Videos:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                      ),
                      ..._project!.videos.map((v) => _buildFileCard(v.title, v.url, Icons.video_file, Colors.blue)),
                    ],
                    
                    // Show Documents
                    if (_project!.documents.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('Documentos:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                      ),
                      ..._project!.documents.map((d) => _buildFileCard(d.title, d.url, Icons.description, Colors.green)),
                    ],
                    
                    // Show Legacy/Other (CoverImageUrl)
                    if (_project!.coverImageUrl != null && 
                        _project!.coverImageUrl!.isNotEmpty &&
                        !_project!.videos.any((v) => v.url == _project!.coverImageUrl) &&
                        !_project!.documents.any((d) => d.url == _project!.coverImageUrl)) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('Otros Archivos:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                      ),
                      _buildFileCard('Archivo Principal', _project!.coverImageUrl!, Icons.insert_drive_file, Colors.orange),
                    ],

                    if (_project!.videos.isEmpty && _project!.documents.isEmpty && (_project!.coverImageUrl == null || _project!.coverImageUrl!.isEmpty))
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No hay archivos adjuntos en esta entrega.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Rubric Selection
                  const Text('Lista de Cotejo / Rúbrica', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Rubric>(
                    value: _selectedRubric,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _rubrics.map<DropdownMenuItem<Rubric>>((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name ?? 'Sin nombre'),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRubric = val;
                        _initializeScores();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  if (_selectedRubric != null) ...[
                    const Text('Criterios de Evaluación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    ..._selectedRubric!.items.map((item) {
                      final criteria = item.criteria;
                      final maxPoints = item.maxPoints;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(criteria, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text('${_detailedScores[criteria] ?? 0} / $maxPoints', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Slider(
                            value: (_detailedScores[criteria] ?? 0).toDouble(),
                            min: 0,
                            max: maxPoints.toDouble(),
                            divisions: maxPoints,
                            onChanged: (val) => setState(() => _detailedScores[criteria] = val.toInt()),
                          ),
                          Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                  ] else ...[
                    const Center(child: Text('Cargando rúbricas...')),
                  ],

                  const SizedBox(height: 16),
                  const Text('Evidencia y Comentarios', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPhotoSection(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Retroalimentación para el alumno...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Confirmar Calificación', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_evidencePath != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                image: DecorationImage(
                  image: FileImage(File(_evidencePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: GestureDetector(
                onTap: () => setState(() => _evidencePath = null),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _takePhoto,
      icon: const Icon(Icons.camera_alt_outlined),
      label: const Text('Tomar Foto de Evidencia'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFileCard(String title, String url, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _openFileExternally(url),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir con App Local'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? url) {
    if (url == null) return Icons.insert_drive_file;
    final ext = url.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'mp4':
      case 'mov':
      case 'avi': return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }
}
