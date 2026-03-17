import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../models/assignment_model.dart';
import '../models/rubric_model.dart';
import '../models/evaluation_model.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'native_media_viewer.dart';
import '../services/pdf_service.dart';

class StudentUploadScreen extends StatefulWidget {
  final String studentId;
  final String? initialAssignmentId;
  const StudentUploadScreen({super.key, required this.studentId, this.initialAssignmentId});

  @override
  State<StudentUploadScreen> createState() => _StudentUploadScreenState();
}

class _StudentUploadScreenState extends State<StudentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _repoLinkController = TextEditingController();
  final _technologiesController = TextEditingController(); // New
  final _promoVideoController = TextEditingController(); // For Demo Video Link (YouTube/Drive/etc)
  PlatformFile? _demoVideoFile;
  final _accessCodeController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isSubmitting = false;
  List<PlatformFile> _selectedFiles = [];
  List<Assignment> _assignments = [];
  String? _selectedAssignmentId;
  bool _isLoadingAssignments = true;
  Assignment? _joinedAssignment;
  bool _isSearchingCode = false;

  Rubric? _assignmentRubric;
  Evaluation? _existingEvaluation;
  Project? _existingProject;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignments().then((_) {
      if (widget.initialAssignmentId != null) {
        _onAssignmentChanged(widget.initialAssignmentId);
      }
    });
  }

  Future<void> _onAssignmentChanged(String? id) async {
    if (id == null) return;
    
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      Assignment? assignment;
      try {
        assignment = _assignments.firstWhere((a) => a.id == id);
      } catch (_) {
        // If not in list, fetch specifically
        assignment = await _apiService.getAssignmentById(id);
        if (assignment != null && mounted) {
          setState(() {
            // Check again before adding to avoid duplicates
            if (!_assignments.any((a) => a.id == assignment!.id)) {
              _assignments = [assignment!, ..._assignments];
            }
          });
        }
      }

      if (assignment == null) throw Exception('Tarea no encontrada');
      
      if (mounted) {
        setState(() {
          _selectedAssignmentId = id;
        });
      }
      
      // 1. Fetch Rubric if exists
      if (assignment.rubricId != null) {
        _assignmentRubric = await _apiService.getRubricById(assignment.rubricId!);
      } else {
        _assignmentRubric = null;
      }

      // 2. Check if student already has a project for this assignment
      final projects = await _apiService.getProjects(
        studentId: widget.studentId,
        assignmentId: id,
      );

      if (projects.isNotEmpty) {
        _existingProject = projects.first;
        _titleController.text = _existingProject?.title ?? '';
        _teamNameController.text = _existingProject?.teamName ?? '';
        _descriptionController.text = _existingProject?.description ?? '';
        _categoryController.text = _existingProject?.category ?? '';
        
        // Populate new fields
        _technologiesController.text = _existingProject!.technologies.isNotEmpty ? _existingProject!.technologies.join(', ') : '';
        // We don't populate _demoVideoFile from URL here, just clear it for new selection if needed
        _demoVideoFile = null; 
        
        // 3. Fetch evaluation if exists
        _existingEvaluation = await _apiService.getEvaluationByProjectId(_existingProject!.id!);
      } else {
        _existingProject = null;
        _existingEvaluation = null;
        _titleController.clear();
        _teamNameController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        _technologiesController.clear();
        _demoVideoFile = null;
      }

    } catch (e) {
      debugPrint('Error fetching assignment details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar detalles: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchAssignments() async {
    try {
      final fetchedAssignments = await _apiService.getAssignments(studentId: widget.studentId);
      setState(() {
        // Deduplicate by ID
        final Map<String, Assignment> assignmentMap = {};
        for (var a in fetchedAssignments) {
          if (a.id != null) {
            assignmentMap[a.id!] = a;
          }
        }
        _assignments = assignmentMap.values.toList();
        _isLoadingAssignments = false;
      });
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tareas: $e')),
        );
      }
      setState(() => _isLoadingAssignments = false);
    }
  }

  Future<void> _replaceSubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar entrega?'),
        content: const Text('Esto eliminará tu entrega actual para que puedas subir una nueva. Tus textos se mantendrán para que no tengas que escribirlos de nuevo. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Sí, reemplazar', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await _apiService.deleteProject(_existingProject!.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrega actual eliminada. Ahora puedes subir tus nuevos archivos.')));
          setState(() {
            _existingProject = null;
            _existingEvaluation = null;
            _selectedFiles.clear();
            _demoVideoFile = null;
          });
        }
      } else {
        throw Exception('No se pudo eliminar el proyecto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _searchByCode() async {
    if (_accessCodeController.text.length < 6) return;
    
    setState(() => _isSearchingCode = true);
    try {
      final assignment = await _apiService.getAssignmentByCode(_accessCodeController.text.toUpperCase());
      if (mounted) {
        if (assignment != null) {
          setState(() {
            _joinedAssignment = assignment;
            _assignments = [assignment, ..._assignments.where((a) => a.id != assignment.id)];
          });
          await _onAssignmentChanged(assignment.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Convocatoria encontrada: ${assignment.title}!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró ninguna convocatoria con ese código')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar código: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingCode = false);
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  Future<void> _pickDemoVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() => _demoVideoFile = result.files.first);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    try {
      List<String> uploadedFileUrls = [];
      
      // 1. Upload files first
      for (var platformFile in _selectedFiles) {
        if (platformFile.path != null) {
          final url = await _apiService.uploadFile(File(platformFile.path!));
          if (url != null) {
            uploadedFileUrls.add(url);
          }
        }
      }

      // 1.1 Upload Demo Video if selected
      String? promoVideoUrl = _existingProject?.promoVideoUrl;
      if (_demoVideoFile != null && _demoVideoFile!.path != null) {
        final url = await _apiService.uploadFile(File(_demoVideoFile!.path!));
        if (url != null) promoVideoUrl = url;
      } else if (_promoVideoController.text.isNotEmpty) {
        promoVideoUrl = _promoVideoController.text; // Use manual URL if no file picked
      }


      // 2. Create project with file URLs and teacher link
      List<Video> videos = [];
      List<Document> documents = [];
      
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final url = i < uploadedFileUrls.length ? uploadedFileUrls[i] : null;
        if (url == null) continue;

        final ext = file.extension?.toLowerCase() ?? '';
        if (ext == 'mp4' || ext == 'mov' || ext == 'avi') {
          videos.add(Video(title: file.name, url: url, description: 'Video subido'));
        } else {
          documents.add(Document(title: file.name, url: url, type: ext.toUpperCase()));
        }
      }

      final selectedAssignment = _assignments.firstWhere((a) => a.id == _selectedAssignmentId);

      final newProject = Project(
        title: _titleController.text,
        teamName: _teamNameController.text.isNotEmpty ? _teamNameController.text : "Equipo de ${_titleController.text}",
        category: _categoryController.text,
        description: _descriptionController.text,
        technologies: _technologiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        studentId: widget.studentId,
        assignmentId: _selectedAssignmentId,
        assignedTeacherId: selectedAssignment.teacherId,
        promoVideoUrl: promoVideoUrl, // Use uploaded file URL
        coverImageUrl: uploadedFileUrls.isNotEmpty ? uploadedFileUrls.first : null,
        videos: videos,
        documents: documents,
      );

      final response = await _apiService.createProjectsBatch([newProject]);

      if (mounted) {
        if (response) {
          try {
            final evaluatorsToNotify = selectedAssignment.assignedEvaluators?.isNotEmpty == true 
                ? selectedAssignment.assignedEvaluators! 
                : [selectedAssignment.teacherId];
            for (var evalId in evaluatorsToNotify) {
              await _apiService.createNotification(AppNotification(
                userId: evalId,
                title: 'Nueva Entrega',
                message: 'El equipo ${_teamNameController.text} subió su proyecto "${_titleController.text}" para la tarea "${selectedAssignment.title}".',
                createdAt: DateTime.now(),
              ));
            }
          } catch (_) {}

          messenger.showSnackBar(
            const SnackBar(content: Text('¡Proyecto y archivos subidos con éxito!')),
          );
          navigator.pop();
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Error al guardar el proyecto en la base de datos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAssignmentDetails() {
    final assignment = _assignments.cast<Assignment?>().firstWhere(
      (a) => a?.id == _selectedAssignmentId,
      orElse: () => null,
    );
    
    if (assignment == null) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.description, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (assignment.rubricId != null)
                TextButton.icon(
                  onPressed: () => _showRubricDialog(),
                  icon: const Icon(Icons.rule, size: 18),
                  label: const Text('Ver Rúbrica'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              const Spacer(),
              if (assignment.dueDate != null)
                Text(
                  'Entrega: ${assignment.dueDate!.day}/${assignment.dueDate!.month}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (_existingEvaluation != null) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Evaluación Oficial:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                if (_existingEvaluation!.scores != null && _existingEvaluation!.scores!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_existingEvaluation!.scores!.values.fold(0, (a, b) => a + b)} pts',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.greenAccent : Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Detailed Scores Breakdown
            if (_existingEvaluation!.detailedScores != null && _existingEvaluation!.detailedScores!.isNotEmpty) ...[
              const Text('Desglose de Rúbrica:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ..._existingEvaluation!.detailedScores!.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                    Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13))),
                    Text('${entry.value} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            const Text('Comentarios del Docente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _existingEvaluation!.feedback ?? 'Sin comentarios adicionales.',
                style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            
            // Evidence Photo
            if (_existingEvaluation!.evidencePhotoBase64 != null && _existingEvaluation!.evidencePhotoBase64!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Foto de Evidencia:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_existingEvaluation!.evidencePhotoBase64!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Text('La imagen no se pudo cargar')),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showRubricDialog() {
    if (_assignmentRubric == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rúbrica: ${_assignmentRubric!.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _assignmentRubric!.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final crit = _assignmentRubric!.items[index];
              return ListTile(
                title: Text(crit.criteria, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(crit.description),
                trailing: Text('${crit.maxPoints} pts', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                contentPadding: EdgeInsets.zero,
              );
            },
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
  }

  Widget _buildTechnologiesField() {
    return TextFormField(
      controller: _technologiesController,
      readOnly: _existingProject != null,
      decoration: const InputDecoration(
        labelText: 'Tecnologías (separadas por comas)',
        prefixIcon: Icon(Icons.code),
        hintText: 'Ej: Flutter, Firebase, Python',
      ),
      validator: (v) => v!.isEmpty ? 'Por favor indica las tecnologías' : null,
    );
  }

  Widget _buildDemoVideoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.video_library, size: 20, color: isDark ? AppColors.primaryYellow : Colors.black54),
            const SizedBox(width: 8),
            Text(
              'Video Demo Principal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              if (_demoVideoFile != null)
                ListTile(
                  leading: const Icon(Icons.movie, color: Colors.blue),
                  title: Text(_demoVideoFile!.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${(_demoVideoFile!.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => setState(() => _demoVideoFile = null),
                  ),
                )
              else if (_existingProject?.promoVideoUrl != null)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Video cargado actualmente', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_existingEvaluation != null ? 'Proyecto ya evaluado' : 'Toca para cambiar'),
                  onTap: _existingEvaluation != null ? null : _pickDemoVideo,
                )
              else
                ListTile(
                  onTap: _pickDemoVideo,
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Seleccionar Video Demo', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Formatos: MP4, MOV, AVI (Ideal < 50MB)'),
                ),
              if (_demoVideoFile == null && _existingProject == null) ...[
                const Divider(),
                TextFormField(
                  controller: _promoVideoController,
                  decoration: const InputDecoration(
                    labelText: 'O pega un link de YouTube/Drive',
                    prefixIcon: Icon(Icons.link),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Identity guard
    if (widget.studentId.isEmpty || widget.studentId == "null") {
       return Scaffold(
         appBar: AppBar(title: const Text('Error de Identidad')),
         body: const Center(child: Text('Error: No se ha detectado el ID del alumno. Por favor inicia sesión de nuevo.')),
       );
    }

    final selectedAssignment = _assignments.cast<Assignment?>().firstWhere(
      (a) => a?.id == _selectedAssignmentId,
      orElse: () => null,
    );
    final bool isExpired = selectedAssignment?.dueDate != null && 
                           selectedAssignment!.dueDate!.isBefore(DateTime.now());

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoadingAssignments = true;
                    });
                    _fetchAssignments();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Mi Proyecto'),
        elevation: 0,
      ),
      body: (_isLoadingAssignments || _isLoadingDetails)
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null && _assignments.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ocurrió un error', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoadingAssignments = true;
                              _errorMessage = null;
                            });
                            _fetchAssignments();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    // Status / Info section if project exists
                    if (_existingProject != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('¡Tarea Entregada!', 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  Text('Has enviado este proyecto correctamente.', 
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      if (widget.initialAssignmentId == null) ...[
                        Text(
                          'Selecciona una convocatoria o únete con un código.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _accessCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Código de Clase/Tarea',
                                  hintText: 'Ej: AB1234',
                                  prefixIcon: Icon(Icons.vpn_key),
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(minimumSize: const Size(100, 56)),
                                onPressed: _isSearchingCode ? null : _searchByCode,
                                child: _isSearchingCode 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Buscar'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Assignment Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _assignments.any((a) => a.id == _selectedAssignmentId) ? _selectedAssignmentId : null,
                        decoration: InputDecoration(
                          labelText: 'Tarea / Convocatoria',
                          prefixIcon: const Icon(Icons.assignment),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() => _isLoadingAssignments = true);
                              _fetchAssignments();
                            },
                          ),
                          hintText: _assignments.isEmpty ? 'Sin tareas disponibles' : 'Listado de tareas',
                        ),
                        items: _assignments.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.title, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _assignments.isEmpty ? null : (val) => _onAssignmentChanged(val),
                        validator: (val) {
                          if (val == null) return 'Por favor selecciona una tarea';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Details and Form Fields
                    if (_selectedAssignmentId != null) ...[
                      _buildAssignmentDetails(),
                      const SizedBox(height: 24),
                      
                      if (!isExpired || _existingProject != null) ...[
                        TextFormField(
                          controller: _titleController,
                          readOnly: _existingProject != null,
                          decoration: const InputDecoration(
                            labelText: 'Título del Proyecto',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _teamNameController,
                          readOnly: _existingProject != null,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Equipo',
                            prefixIcon: Icon(Icons.group),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _categoryController,
                          readOnly: _existingProject != null,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category),
                          ),
                          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          readOnly: _existingProject != null,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Descripción detallada',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTechnologiesField(),
                        const SizedBox(height: 20),
                        _buildDemoVideoSection(),
                        const SizedBox(height: 32),
                      ],

                      // Files section
                      if (_existingProject != null) ...[
                        const Text('Archivos Entregados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ..._existingProject!.videos.map((v) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.video_file, color: Colors.blue),
                          title: Text(v.title, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(v.url, v.title, isVideo: true),
                        )),
                        ..._existingProject!.documents.map((d) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.description, color: Colors.green),
                          title: Text(d.title, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(d.url, d.title, isImage: _isImageExtension(d.type)),
                        )),
                      ],

                      const SizedBox(height: 32),
                      const Text('Documentación (Videos, Código, PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // Files list (shrinkwrap true is safe in ListView)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(_getFileIcon(file.extension)),
                            title: Text(file.name, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _removeFile(index),
                            ),
                          );
                        },
                      ),
                      
                      if (_existingProject == null && !isExpired) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Agregar archivos'),
                        ),
                      ],

                      // Final Buttons
                      const SizedBox(height: 48),
                      if (isExpired && _existingProject == null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'La fecha límite para esta tarea ha expirado. Ya no puedes enviar proyectos.',
                                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_existingProject == null)
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitProject,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primaryYellow,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSubmitting 
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2)
                              )
                            : const Text('Enviar Proyecto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        )
                      else if (_existingEvaluation == null)
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'La fecha límite ha expirado. Ya no puedes reescribir ni modificar tu entrega.',
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _replaceSubmission,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reemplazar Entrega'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      if (_existingEvaluation != null) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => PdfService.generateAndShowCertificate(
                              project: _existingProject!, 
                              evaluation: _existingEvaluation!
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Descargar Certificado PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ] else ...[
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Selecciona una tarea arriba para comenzar tu entrega',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  bool _isImageExtension(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t == 'jpg' || t == 'jpeg' || t == 'png' || t == 'gif' || t == 'webp';
  }

  Future<void> _openUrl(String? url, String fileName, {bool isVideo = false, bool isImage = false}) async {
    if (url == null || url.isEmpty) return;
    
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Descargando $fileName...'), duration: const Duration(seconds: 1)),
      );
      await _apiService.downloadAndOpenFile(finalUrl, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $fileName: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    }
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'mp4':
      case 'mov':
      case 'avi': return Icons.video_file;
      case 'doc':
      case 'docx': return Icons.description;
      case 'dart':
      case 'py':
      case 'js':
      case 'html':
      case 'css': return Icons.code;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image;
      case 'sql': return Icons.storage;
      case 'ppt':
      case 'pptx': return Icons.slideshow;
      default: return Icons.insert_drive_file;
    }
  }
}
