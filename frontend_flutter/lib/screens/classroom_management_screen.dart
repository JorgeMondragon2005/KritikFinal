import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
import '../models/enrollment_model.dart';
import '../models/assignment_model.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'assignment_creation_screen.dart';
import 'student_upload_screen.dart';
import 'submission_list_screen.dart';

class ClassroomManagementScreen extends StatefulWidget {
  final String userId;
  final String role;
  const ClassroomManagementScreen({super.key, required this.userId, required this.role});

  @override
  State<ClassroomManagementScreen> createState() => _ClassroomManagementScreenState();
}

class _ClassroomManagementScreenState extends State<ClassroomManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Classroom> _classrooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoading = true);
    debugPrint('Loading classrooms for user: ${widget.userId} with role: ${widget.role}');
    try {
      final classrooms = (widget.role.toLowerCase() == 'evaluator')
          ? await _apiService.getClassrooms(teacherId: widget.userId)
          : await _apiService.getClassrooms(studentId: widget.userId);
      
      setState(() {
        _classrooms = classrooms;
        _isLoading = false;
      });
      debugPrint('Loaded ${_classrooms.length} classrooms. IDs: ${_classrooms.map((c) => c.id).join(', ')}');
    } catch (e) {
      debugPrint('Error loading classrooms: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clases: $e')),
        );
      }
    }
  }

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Clase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre de la Clase')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newClass = Classroom(
                  name: nameController.text,
                  description: descController.text,
                  teacherId: widget.userId,
                  accessCode: (DateTime.now().millisecondsSinceEpoch % 1000000).toString(),
                );
                
                setState(() => _isLoading = true);
                final result = await _apiService.createClassroom(newClass);
                debugPrint('DEBUG: Create classroom result: $result');
                
                if (mounted) {
                  if (result is Classroom) {
                    Navigator.pop(context);
                    _loadClassrooms();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clase creada correctamente')),
                    );
                  } else {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result?.toString() ?? 'Error al crear la clase. Intenta de nuevo.'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Crear')
          ),
        ],
      )
    );
  }

  void _showEditClassDialog(Classroom classroom) {
    final nameController = TextEditingController(text: classroom.name);
    final descController = TextEditingController(text: classroom.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Clase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre de la Clase')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final updatedClass = Classroom(
                id: classroom.id,
                name: nameController.text,
                description: descController.text,
                teacherId: classroom.teacherId,
                accessCode: classroom.accessCode,
              );
                final result = await _apiService.updateClassroom(updatedClass);
                if (mounted) {
                  if (result == true) {
                    Navigator.pop(context);
                    _loadClassrooms();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clase actualizada')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result?.toString() ?? 'Error al actualizar la clase'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
            },
            child: const Text('Guardar')
          ),
        ],
      )
    );
  }

  void _deleteClassroom(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Clase?'),
        content: const Text('Esta acción no se puede deshacer y eliminará todas las convocatorias asociadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _apiService.deleteClassroom(id);
      if (mounted) {
        if (result == true) {
          _loadClassrooms();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clase eliminada')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?.toString() ?? 'Error al eliminar la clase'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _leaveClassroom(String classroomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la Clase?'),
        content: const Text('Ya no podrás ver las tareas ni subir proyectos a esta clase a menos que vuelvas a unirte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.userId == null || widget.userId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acceso de invitado: No puedes salir de clases en modo invitado.'), backgroundColor: Colors.orange)
          );
        }
        return;
      }

      final success = await _apiService.leaveClassroom(widget.userId!, classroomId);
      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close details sheet
          _loadClassrooms();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Has salido de la clase')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al salir de la clase'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _deleteAssignment(String id, VoidCallback onDeleted) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Convocatoria?'),
        content: const Text('Esta acción eliminará la convocatoria y todos los proyectos subidos a ella.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteAssignment(id);
      if (success) {
        onDeleted();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convocatoria eliminada')));
      }
    }
  }

  void _showJoinClassDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a Clase'),
        content: TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Código de Clase')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (widget.userId == null || widget.userId!.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Acceso de Invitado: Debes iniciar sesión para unirte a una clase.'))
                  );
                }
                return;
              }
              final classroom = await _apiService.getClassroomByCode(codeController.text);
              if (classroom != null) {
                final enrollment = ClassEnrollment(
                  classroomId: classroom.id!,
                  studentId: widget.userId,
                  status: 'Pending',
                );
                final result = await _apiService.enrollInClass(enrollment);
                if (mounted) {
                  if (result is bool && result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud enviada correctamente')));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $result'), 
                      backgroundColor: Colors.red
                    ));
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código no válido')));
                }
              }
            },
            child: const Text('Unirse')
          ),
        ],
      )
    );
  }

  void _showClassDetail(Classroom classroom) async {
    List<ClassEnrollment> members = [];
    List<Assignment> assignments = [];
    List<Project> studentProjects = [];
    bool loadingDetails = true;
    String filter = 'Todos';

    void loadData(Function setState) {
      debugPrint('DEBUG: Calling loadData for classroom: ${classroom.id}');
      setState(() => loadingDetails = true);
      Future.wait([
        _apiService.getClassMembers(classroom.id ?? ''),
        _apiService.getAssignmentsByClassroom(classroom.id ?? ''),
        if (widget.role.toLowerCase() == 'student') _apiService.getProjects(studentId: widget.userId ?? '') else Future.value(<Project>[]),
      ]).then((results) {
        if (mounted) {
          final fetchedMembers = List<ClassEnrollment>.from(results[0]);
          debugPrint('DEBUG: Loaded ${fetchedMembers.length} members/requests for this classroom');
          for (var m in fetchedMembers) {
            debugPrint('DEBUG: Request from StudentID: ${m.studentId}, Name: ${m.studentName}, Status: ${m.status}');
          }
          setState(() {
            members = fetchedMembers;
            assignments = List<Assignment>.from(results[1]);
            studentProjects = List<Project>.from(results[2]);
            loadingDetails = false;
          });
          debugPrint('DEBUG: Loaded ${assignments.length} assignments for this classroom');
        }
      }).catchError((e) {
        debugPrint('DEBUG: Error in loadData: $e');
        if (mounted) {
          setState(() => loadingDetails = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (loadingDetails) {
            loadData(setModalState);
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                AppBar(
                  title: Text(classroom.name),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => loadData(setModalState),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Descripción:', style: Theme.of(context).textTheme.titleSmall),
                      Text(classroom.description, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      if (widget.role.toLowerCase() == 'evaluator') ...[
                        Text('Código de Clase (para alumnos):', style: Theme.of(context).textTheme.titleSmall),
                        SelectableText(
                          classroom.accessCode, 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primaryYellow)
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentCreationScreen(
                                teacherId: widget.userId ?? '',
                                initialClassroomId: classroom.id,
                              ),
                            ),
                          ).then((_) => loadData(setModalState)),
                          icon: const Icon(Icons.add_task),
                          label: const Text('Nueva Tarea'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                      const Divider(height: 32),
                      
                      if (widget.role.toLowerCase() == 'evaluator') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tareas en esta Clase:', style: Theme.of(context).textTheme.titleSmall),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () => loadData(setModalState),
                              tooltip: 'Refrescar tareas',
                            ),
                          ],
                        ),
                        if (assignments.isEmpty) const Text('No hay tareas.'),
                        if (assignments.isEmpty) const Text('No hay tareas.'),
                        ...assignments.map((a) => ListTile(
                          title: Text(a.title),
                          subtitle: Text(a.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 20),
                                tooltip: 'Ver Entregas',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubmissionListScreen(
                                        assignmentId: a.id!,
                                        assignmentTitle: a.title,
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AssignmentCreationScreen(teacherId: widget.userId ?? '', assignment: a))
                                  ).then((_) => setModalState(() => loadingDetails = true));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _deleteAssignment(a.id!, () => setModalState(() => loadingDetails = true)),
                              ),
                            ],
                          ),
                        )),
                        const Divider(height: 32),
                        const Text('Miembros / Solicitudes:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (members.isEmpty) const Text('No hay solicitudes de alumnos.'),
                        ...members.map((m) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text(m.studentName ?? m.studentId),
                          subtitle: Text('Estado: ${m.status}'),
                          trailing: m.status == 'Pending' 
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () async {
                                      final success = await _apiService.updateEnrollmentStatus(m.id!, 'Accepted');
                                      if (success) loadData(setModalState);
                                    },
                                    tooltip: 'Aceptar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () async {
                                      final success = await _apiService.updateEnrollmentStatus(m.id!, 'Rejected');
                                      if (success) loadData(setModalState);
                                    },
                                    tooltip: 'Rechazar',
                                  ),
                                ],
                              )
                            : Icon(
                                m.status == 'Accepted' ? Icons.check_circle : Icons.cancel,
                                color: m.status == 'Accepted' ? Colors.green : Colors.red,
                              ),
                        )),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tareas de la Clase:', style: Theme.of(context).textTheme.titleSmall),
                            DropdownButton<String>(
                              value: filter,
                              items: ['Todos', 'Entregados', 'Vencidos', 'Pendientes'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                              onChanged: (val) => setModalState(() => filter = val!),
                            ),
                          ],
                        ),
                        if (assignments.isEmpty) const Text('No hay tareas publicadas.'),
                        ...assignments.where((a) {
                          final isSubmitted = studentProjects.any((p) => p.assignmentId == a.id);
                          final isExpired = a.dueDate != null && a.dueDate!.isBefore(DateTime.now());
                          if (filter == 'Entregados') return isSubmitted;
                          if (filter == 'Vencidos') return !isSubmitted && isExpired;
                          if (filter == 'Pendientes') return !isSubmitted && !isExpired;
                          return true;
                        }).map((a) {
                          final isSubmitted = studentProjects.any((p) => p.assignmentId == a.id);
                          final isExpired = a.dueDate != null && a.dueDate!.isBefore(DateTime.now());
                          return ListTile(
                            title: Text(a.title, style: TextStyle(fontWeight: isSubmitted ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(a.dueDate != null ? 'Vence: ${a.dueDate!.day}/${a.dueDate!.month} ${a.dueDate!.hour.toString().padLeft(2, '0')}:${a.dueDate!.minute.toString().padLeft(2, '0')}' : 'Sin fecha'),
                            trailing: isSubmitted 
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : isExpired 
                                ? const Icon(Icons.error_outline, color: Colors.red)
                                : const Icon(Icons.upload_file),
                            onTap: (isSubmitted || isExpired) ? null : () {
                               Navigator.pop(context);
                               Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(
                                 studentId: widget.userId ?? '',
                                 initialAssignmentId: a.id,
                               )));
                            },
                          );
                        }),
                        const Divider(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _leaveClassroom(classroom.id!),
                          icon: const Icon(Icons.exit_to_app, color: Colors.white),
                          label: const Text('Salir de la Clase', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Clases')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _classrooms.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay clases registradas', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadClassrooms,
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _classrooms.length,
              itemBuilder: (context, index) {
                final c = _classrooms[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.class_)),
                  title: Text(c.name),
                  subtitle: Text(c.description),
                  trailing: widget.role.toLowerCase() == 'evaluator' 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditClassDialog(c)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteClassroom(c.id!)),
                          const Icon(Icons.chevron_right),
                        ],
                      )
                    : const Icon(Icons.chevron_right),
                  onTap: () => _showClassDetail(c),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.role.toLowerCase() == 'evaluator' ? _showCreateClassDialog : _showJoinClassDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
