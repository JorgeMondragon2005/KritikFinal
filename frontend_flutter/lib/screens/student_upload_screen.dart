import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../models/assignment_model.dart';
import '../models/rubric_model.dart';
import '../models/evaluation_model.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _demoLinkController = TextEditingController();
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
        
        // Populate links if stored in technologies list (common pattern)
        if (_existingProject!.technologies.isNotEmpty) {
          _repoLinkController.text = _existingProject!.technologies.first;
          if (_existingProject!.technologies.length > 1) {
            _demoLinkController.text = _existingProject!.technologies[1];
          }
        }
        
        // 3. Fetch evaluation if exists
        _existingEvaluation = await _apiService.getEvaluationByProjectId(_existingProject!.id!);
      } else {
        _existingProject = null;
        _existingEvaluation = null;
        _titleController.clear();
        _teamNameController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        _repoLinkController.clear();
        _demoLinkController.clear();
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

  Future<void> _deleteSubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar entrega?'),
        content: const Text('Esto eliminará tu entrega actual y volverá a marcar la tarea como pendiente. Los archivos subidos no se eliminarán del servidor pero ya no estarán asociados a esta tarea.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, mantener')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Sí, cancelar entrega', style: TextStyle(color: Colors.red))
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrega cancelada correctamente')));
          Navigator.pop(context);
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
        technologies: [
          if (_repoLinkController.text.isNotEmpty) _repoLinkController.text,
          if (_demoLinkController.text.isNotEmpty) _demoLinkController.text,
        ],
        studentId: widget.studentId,
        assignmentId: _selectedAssignmentId,
        assignedTeacherId: selectedAssignment.teacherId,
        coverImageUrl: uploadedFileUrls.isNotEmpty ? uploadedFileUrls.first : null,
        videos: videos,
        documents: documents,
      );

      final response = await _apiService.createProjectsBatch([newProject]);

      if (mounted) {
        if (response) {
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.description, style: const TextStyle(fontSize: 14)),
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
                const Text('Retroalimentación del Docente:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                if (_existingEvaluation!.scores != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_existingEvaluation!.scores!.values.fold(0, (a, b) => a + b)} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _existingEvaluation!.feedback ?? 'Sin comentarios por ahora.',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
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

  @override
  Widget build(BuildContext context) {
    // Identity guard
    if (widget.studentId.isEmpty || widget.studentId == "null") {
       return Scaffold(
         appBar: AppBar(title: const Text('Error de Identidad')),
         body: const Center(child: Text('Error: No se ha detectado el ID del alumno. Por favor inicia sesión de nuevo.')),
       );
    }

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
                      TextFormField(
                        controller: _repoLinkController,
                        readOnly: _existingProject != null,
                        decoration: const InputDecoration(
                          labelText: 'Link de Repositorio (GitHub, etc.)',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _demoLinkController,
                        readOnly: _existingProject != null,
                        decoration: const InputDecoration(
                          labelText: 'Link de Demo o Drive',
                          prefixIcon: Icon(Icons.ondemand_video),
                        ),
                      ),

                      // Files section
                      if (_existingProject != null) ...[
                        const SizedBox(height: 32),
                        const Text('Archivos Entregados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ..._existingProject!.videos.map((v) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.video_file, color: Colors.blue),
                          title: Text(v.title, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(v.url),
                        )),
                        ..._existingProject!.documents.map((d) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.description, color: Colors.green),
                          title: Text(d.title, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(d.url),
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
                      
                      if (_existingProject == null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Agregar archivos'),
                        ),
                      ],

                      // Final Buttons
                      const SizedBox(height: 48),
                      if (_existingProject == null)
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
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _deleteSubmission,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar Entrega'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace automáticamente.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
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
