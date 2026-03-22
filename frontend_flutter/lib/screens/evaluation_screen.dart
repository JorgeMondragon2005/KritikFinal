import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'native_media_viewer.dart';

import '../services/api_service.dart';
import '../models/evaluation_model.dart';
import '../models/rubric_model.dart';
import '../models/notification_model.dart';

class EvaluationScreen extends StatefulWidget {
  final String? projectId;
  final String projectName;
  final String? evaluatorId;

  const EvaluationScreen({
    super.key,
    this.projectId,
    required this.projectName,
    this.evaluatorId,
  });

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
  Evaluation? _existingEvaluation;

  String? _evidencePath;
  bool _isSubmitting = false;

  final List<String> _availableBadges = [
    'Ninguno',
    'Mejor Innovación',
    'Diseño Impecable',
    'Mejor Pitch',
    'Excelente Viabilidad',
  ];
  String? _selectedBadge = 'Ninguno';

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
      final evaluation = await _apiService.getEvaluationByProjectId(
        widget.projectId!,
      );
      if (mounted) {
        setState(() {
          _project = projects.firstWhere((p) => p.id == widget.projectId);
          if (evaluation != null &&
              evaluation.evaluatorId == widget.evaluatorId) {
            _existingEvaluation = evaluation;
            _commentController.text = evaluation.feedback ?? '';
            _selectedBadge = evaluation.badgeEarned ?? 'Ninguno';
            if (_rubrics.isNotEmpty &&
                _selectedRubric == null &&
                evaluation.rubricId != null) {
              _selectedRubric = _rubrics.firstWhere(
                (r) => r.id == evaluation.rubricId,
                orElse: () => _rubrics.first,
              );
            }
            if (evaluation.detailedScores != null) {
              _detailedScores = Map<String, int>.from(
                evaluation.detailedScores!,
              );
            }
          }
          _isLoadingProject = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading project details: $e');
      if (mounted) setState(() => _isLoadingProject = false);
    }
  }

  bool _isImageExtension(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t == 'jpg' || t == 'jpeg' || t == 'png' || t == 'gif' || t == 'webp';
  }

  Future<void> _openFileExternally(
    String url,
    String fileName, {
    bool isVideo = false,
    bool isImage = false,
  }) async {
    // Fix relative URLs from backend
    String finalUrl = url;
    if (finalUrl.startsWith('/')) {
      finalUrl = 'https://kritikfinal.onrender.com$finalUrl';
    }

    if (isVideo || isImage) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NativeMediaViewer(url: finalUrl, isVideo: isVideo),
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Descargando $fileName...'),
          duration: const Duration(seconds: 1),
        ),
      );
      await _apiService.downloadAndOpenFile(finalUrl, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir $fileName: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
    }
  }

  Future<void> _loadRubrics() async {
    final rubrics = await _apiService.getRubrics(creatorId: widget.evaluatorId);
    if (mounted) {
      setState(() {
        _rubrics = rubrics;
        if (_rubrics.isNotEmpty) {
          if (_existingEvaluation?.rubricId != null) {
            _selectedRubric = _rubrics.firstWhere(
              (r) => r.id == _existingEvaluation!.rubricId,
              orElse: () => _rubrics.first,
            );
          } else {
            _selectedRubric = _rubrics.first;
          }
          if (_detailedScores.isEmpty) {
            _initializeScores();
          }
        }
      });
    }
  }

  void _initializeScores() {
    if (_selectedRubric != null) {
      if (_existingEvaluation != null &&
          _existingEvaluation!.detailedScores != null &&
          _existingEvaluation!.rubricId == _selectedRubric!.id) {
        _detailedScores = Map<String, int>.from(
          _existingEvaluation!.detailedScores!,
        );
      } else {
        final items = _selectedRubric!.items;
        _detailedScores = {
          for (var item in items) item.criteria: item.maxPoints,
        };
      }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir la cámara: $e')));
    }
  }

  Future<void> _submit() async {
    if (widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el ID del proyecto'),
        ),
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

      double totalMax =
          _selectedRubric?.items.fold(
            0.0,
            (sum, item) => sum! + item.maxPoints,
          ) ??
          100.0;
      double earned = _detailedScores.values.fold(0.0, (a, b) => a + b);
      double normalizedScoreDouble = totalMax > 0
          ? (earned / totalMax) * 100
          : earned;

      final evaluation = Evaluation(
        id: _existingEvaluation?.id, // Keep the old ID for updating
        projectId: widget.projectId,
        evaluatorId: widget.evaluatorId ?? "evaluator_unknown",
        rubricId: _selectedRubric?.id,
        scores: {"General": normalizedScoreDouble},
        detailedScores: _detailedScores,
        feedback: _commentController.text,
        evidencePhotoBase64:
            base64Photo ??
            _existingEvaluation
                ?.evidencePhotoBase64, // keep old if not taking a new one
        badgeEarned: _selectedBadge == 'Ninguno' ? null : _selectedBadge,
      );

      final success = _existingEvaluation != null
          ? await _apiService.updateEvaluation(evaluation)
          : await _apiService.submitEvaluation(evaluation);

      if (!mounted) return;

      if (success) {
        if (_project != null) {
          try {
            await _apiService.createNotification(
              AppNotification(
                userId: _project!.studentId ?? '',
                title: 'Proyecto Evaluado',
                message:
                    'El jurado ha evaluado tu proyecto "${_project!.title}". Revisa tu retroalimentación.',
                createdAt: DateTime.now(),
                actionUrl: '/student_upload/${_project!.assignmentId}',
              ),
            );
          } catch (_) {}
        }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _autofillWithAI() async {
    if (_project == null || _selectedRubric == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Asegúrate de que el proyecto y la rúbrica estén cargados.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "La IA está leyendo el proyecto y evaluando con la rúbrica...",
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final resultMap = await _apiService.suggestEvaluationResultsWithAI(
        _project!,
        _selectedRubric!,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (resultMap != null && resultMap['feedback'] != null) {
          setState(() {
            _commentController.text = resultMap['feedback'].toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '¡Retroalimentación generada con IA! Revisa y califica manualmente.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La IA no devolvió un formato válido.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error AI: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluar Proyecto'), elevation: 0),
      body: SafeArea(
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.projectName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingProject) const LinearProgressIndicator(),

                    // AI Autocomplete Button
                    if (!_isLoadingProject &&
                        _project != null &&
                        _selectedRubric != null) ...[
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _autofillWithAI,
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primaryYellow,
                        ),
                        label: const Text(
                          'Autocompletar con IA',
                          style: TextStyle(color: AppColors.primaryYellow),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryYellow,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],

                    // Rubric Selection
                    const Text(
                      'Lista de Cotejo / Rúbrica',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Rubric>(
                      value: _selectedRubric,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _rubrics
                          .map<DropdownMenuItem<Rubric>>(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.name ?? 'Sin nombre'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRubric = val;
                          _initializeScores();
                        });
                      },
                    ),

                    const SizedBox(height: 32),
                    if (_selectedRubric != null) ...[
                      const Text(
                        'Criterios de Evaluación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
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
                                Expanded(
                                  child: Text(
                                    criteria,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_detailedScores[criteria] ?? 0} / $maxPoints',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: (_detailedScores[criteria] ?? 0)
                                  .toDouble(),
                              min: 0,
                              max: maxPoints.toDouble(),
                              divisions: maxPoints,
                              onChanged: (val) => setState(
                                () => _detailedScores[criteria] = val.toInt(),
                              ),
                            ),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }),
                    ] else ...[
                      const Center(child: Text('Cargando rúbricas...')),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      'Evidencia y Comentarios',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPhotoSection(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      textAlign: TextAlign.justify,
                      decoration: InputDecoration(
                        hintText: 'Retroalimentación para el alumno...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.auto_fix_high,
                            color: AppColors.primaryYellow,
                          ),
                          tooltip: 'Mejorar redacción con IA',
                          onPressed: () async {
                            if (_commentController.text.trim().isEmpty) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Kiosko IA corrigiendo ortografía...',
                                ),
                              ),
                            );
                            final fixedText = await _apiService
                                .fixTextGrammarWithAI(_commentController.text);
                            if (fixedText != null && mounted) {
                              setState(
                                () => _commentController.text = fixedText,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Texto mejorado por IA!'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Award Selection
                    const Text(
                      '🏆 Reconocimiento Especial (Opcional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBadge,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.star_border,
                          color: Colors.amber,
                        ),
                      ),
                      items: _availableBadges
                          .map(
                            (badge) => DropdownMenuItem(
                              value: badge,
                              child: Text(badge),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBadge = val;
                        });
                      },
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _existingEvaluation != null
                            ? 'Actualizar Calificación'
                            : 'Confirmar Calificación',
                        style: const TextStyle(fontSize: 16),
                      ),
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
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
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

  Widget _buildFileCard(
    String title,
    String url,
    IconData icon,
    Color color, {
    bool isVideo = false,
    bool isImage = false,
  }) {
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
            onPressed: () => _openFileExternally(
              url,
              title,
              isVideo: isVideo,
              isImage: isImage,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(isVideo || isImage ? 'Ver Archivo' : 'Abrir Documento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
