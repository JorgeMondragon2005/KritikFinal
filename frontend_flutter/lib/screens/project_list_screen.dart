import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../theme/app_theme.dart';
import '../models/project_model.dart';
import 'evaluation_screen.dart';
import 'admin_dashboard_screen.dart';
import 'student_upload_screen.dart';
import 'assignment_creation_screen.dart';
import 'rubric_management_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'login_screen.dart';
import '../models/assignment_model.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../services/pdf_service.dart';
import '../models/notification_model.dart';
import '../models/enrollment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'classroom_management_screen.dart';
import '../widgets/project_card_widget.dart';
import 'teacher_dashboard_screen.dart';
import 'project_detail_screen.dart';
import '../models/evaluation_model.dart';

class ProjectListScreen extends StatefulWidget {
  final String role;
  final String? userId;
  final String? userFullName;

  const ProjectListScreen({
    super.key, 
    this.role = 'Student',
    this.userId,
    this.userFullName,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ApiService _apiService = ApiService();
  List<Project> _allProjects = [];
  List<Assignment> _allAssignmentsForStudent = [];
  List<Assignment> _pendingAssignments = [];
  List<Assignment> _managedAssignments = []; // For teachers/evaluators
  List<Classroom> _studentClasses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  String _studentStatusFilter = 'Pendientes'; // For student dashboard
  int _unreadNotifications = 0;
  String? _fotoPerfil;
  String? _portadaUrl;

  Set<String> _evaluatedProjectIds = {}; // Track which projects the current evaluator has already graded
  
  // AI Matchmaking
  List<String> _recommendedProjectIds = [];
  bool _isMatchmaking = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchProjects();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_session');
    if (userStr != null) {
      final userJson = jsonDecode(userStr);
      if (mounted) {
        setState(() {
          _fotoPerfil = userJson['fotoPerfil'] ?? userJson['FotoPerfil'];
          _portadaUrl = userJson['portadaUrl'] ?? userJson['PortadaUrl'];
        });
      }
    }
  }

  Future<void> _fetchProjects({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    try {
      final role = widget.role.toLowerCase();
      final userId = widget.userId;

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _allProjects = [];
            _pendingAssignments = [];
            _studentClasses = [];
            if (showLoader) _isLoading = false;
          });
        }
        return;
      }

      if (role == 'student') {
        final results = await Future.wait<dynamic>([
          _apiService.getProjects(studentId: userId),
          _apiService.getAssignments(studentId: userId),
          _apiService.getClassrooms(studentId: userId),
        ]);
        
        final projects = List<Project>.from(results[0]);
        // Deduplicate assignments by ID
        final fetchedAssignments = List<Assignment>.from(results[1]);
        final Map<String, Assignment> assignmentMap = {};
        for (var a in fetchedAssignments) {
          if (a.id != null) {
            assignmentMap[a.id!] = a;
          }
        }
        final assignments = assignmentMap.values.toList();
        final classrooms = List<Classroom>.from(results[2]);
        
        final submittedAssignmentIds = projects.map((p) => p.assignmentId).toSet();
        final pending = assignments.where((a) {
          final isPending = !submittedAssignmentIds.contains(a.id);
          final isNotExpired = a.dueDate == null || a.dueDate!.isAfter(DateTime.now());
          return isPending && isNotExpired;
        }).toList();

        if (mounted) {
          setState(() {
            _allProjects = projects;
            _allAssignmentsForStudent = assignments;
            _pendingAssignments = pending;
            _studentClasses = classrooms;
            if (showLoader) _isLoading = false;
          });
        }
      } else {
        final teacherId = role == 'evaluator' ? userId : null;
        final results = await Future.wait<dynamic>([
          _apiService.getProjects(teacherId: teacherId),
          _apiService.getAssignments(
             teacherId: (role == 'teacher' || role == 'evaluator') ? userId : null,
             evaluatorId: role == 'evaluator' ? userId : null,
          ), // El backend filtra y devuelve la lista exacta.
          if (role == 'evaluator') _apiService.getEvaluationsByEvaluator(userId!) else Future.value(<Evaluation>[]),
          _apiService.getClassrooms(), // Fetch all classrooms for grouping names
        ]);

        final projects = List<Project>.from(results[0]);
        var allAssignments = List<Assignment>.from(results[1]);
        List<Assignment> managed = allAssignments;
        
        final evals = List<Evaluation>.from(results[2]);
        final classrooms = List<Classroom>.from(results[3]);
        
        if (role == 'evaluator') {
          _evaluatedProjectIds = evals.map((e) => e.projectId ?? '').toSet();
        }
        
        if (mounted) {
          setState(() {
            _allProjects = projects;
            _managedAssignments = managed;
            _studentClasses = classrooms;
            if (showLoader) _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        if (showLoader) setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted && widget.userId != null && widget.userId!.isNotEmpty) {
        try {
          final List<AppNotification> notifs = await _apiService.getUserNotifications(widget.userId!);
          setState(() {
            _unreadNotifications = notifs.where((n) => !n.isRead).length;
          });
        } catch (_) {}
      }
    }
  }

  List<Project> get _filteredProjects {
    final isEvalRole = widget.role.toLowerCase() == 'evaluator';
    
    return _allProjects.where((p) {
      final title = p.title ?? p.teamName ?? '';
      final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      final isEvaluated = isEvalRole 
          ? _evaluatedProjectIds.contains(p.id) 
          : p.status?.toLowerCase() == 'evaluado';
      
      if (_selectedFilter == 'Pendientes') matchesFilter = !isEvaluated;
      if (_selectedFilter == 'Evaluados') matchesFilter = isEvaluated;
      if (_selectedFilter == 'Recomendados') matchesFilter = _recommendedProjectIds.contains(p.id);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget build(BuildContext context) {
    bool hasDualTabs = widget.role.toLowerCase() != 'student';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: hasDualTabs ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Proyectos', style: Theme.of(context).textTheme.headlineMedium),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundOffWhite,
          elevation: 0,
          bottom: hasDualTabs 
            ? TabBar(
                tabs: const [
                  Tab(text: 'Proyectos Recibidos'),
                  Tab(text: 'Mis Convocatorias'),
                ],
                labelColor: AppColors.primaryYellow,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                indicatorColor: AppColors.primaryYellow,
              )
            : null,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationScreen(userId: widget.userId ?? '')),
                    ).then((_) {
                      if (mounted) _fetchProjects();
                    });
                  },
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$_unreadNotifications',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.role.toLowerCase() == 'teacher' || widget.role.toLowerCase() == 'evaluator')
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                tooltip: 'Estadísticas',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherDashboardScreen(teacherId: widget.userId ?? ''))),
              ),
          ],
        ),
        drawer: _buildDrawer(context),
        floatingActionButton: (widget.role.toLowerCase() == 'admin' || widget.role.toLowerCase() == 'student' || widget.role.toLowerCase() == 'evaluator')
          ? FloatingActionButton.extended(
              onPressed: () {
                if (widget.role.toLowerCase() == 'admin') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                } else if (widget.role.toLowerCase() == 'evaluator') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomManagementScreen(userId: widget.userId ?? '', role: widget.role))).then((_) => _fetchProjects());
                } else {
                  // Student: Join Class
                  _showJoinClassDialog();
                }
              },
              label: Text(_getFabLabel()),
              icon: Icon(_getFabIcon()),
              backgroundColor: AppColors.primaryYellow,
            )
          : null,
        body: RefreshIndicator(
          onRefresh: () => _fetchProjects(showLoader: false),
          color: AppColors.primaryYellow,
          child: _isLoading 
            ? _buildProjectSkeleton()
            : hasDualTabs
              ? TabBarView(
                  children: [
                     _buildProjectTab(),
                     _buildAssignmentTab(),
                  ],
                )
              : widget.role.toLowerCase() == 'student'
                ? _buildStudentDashboard()
                : _buildProjectTab(),
        ),
      ),
    );
  }

  Widget _buildStudentDashboard() {
    if (_studentClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text('¡Bienvenido o bienvenida!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Aún no te has unido a ninguna clase. Para empezar, únete a una clase usando el código que te dio tu profesor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showJoinClassDialog,
              icon: const Icon(Icons.add),
              label: const Text('Unirme a una clase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    final assignmentsToShow = _allAssignmentsForStudent.where((a) {
      final isSubmitted = _allProjects.any((p) => p.assignmentId == a.id);
      final isExpired = a.dueDate != null && a.dueDate!.isBefore(DateTime.now());
      
      if (_studentStatusFilter == 'Entregados') return isSubmitted;
      if (_studentStatusFilter == 'Vencidos') return isExpired && !isSubmitted;
      if (_studentStatusFilter == 'Pendientes') return !isSubmitted && !isExpired;
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vista General', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => ClassroomManagementScreen(userId: widget.userId ?? '', role: widget.role))
                ).then((_) => _fetchProjects()),
                icon: const Icon(Icons.class_outlined, size: 18),
                label: const Text('Mis Clases'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryYellow),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildStudentFilterChip('Pendientes'),
              const SizedBox(width: 8),
              _buildStudentFilterChip('Entregados'),
              const SizedBox(width: 8),
              _buildStudentFilterChip('Vencidos'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading && _pendingAssignments.isEmpty
            ? _buildProjectSkeleton()
            : assignmentsToShow.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _studentStatusFilter == 'Entregados' ? Icons.check_circle_outline : Icons.task_alt,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text('No hay tareas ${_studentStatusFilter.toLowerCase()}'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignmentsToShow.length,
                  itemBuilder: (context, index) {
                    final a = assignmentsToShow[index];
                    // Filtering is now handled in _fetchProjects for consistency
                    final isSubmitted = _allProjects.any((p) => p.assignmentId == a.id);
                    final isExpired = a.dueDate != null && a.dueDate!.isBefore(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isSubmitted ? Colors.green.withOpacity(0.2) : (isExpired ? Colors.red.withOpacity(0.2) : AppColors.primaryYellow.withOpacity(0.2)),
                          child: Icon(
                            isSubmitted ? Icons.check : (isExpired ? Icons.priority_high : Icons.assignment),
                            color: isSubmitted ? Colors.green : (isExpired ? Colors.red : AppColors.primaryYellow),
                          ),
                        ),
                        title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: isExpired && !isSubmitted ? Colors.red : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Vence: ${a.dueDate != null ? "${a.dueDate!.day}/${a.dueDate!.month} ${a.dueDate!.hour.toString().padLeft(2, '0')}:${a.dueDate!.minute.toString().padLeft(2, '0')}" : "Sin fecha"}',
                                  style: TextStyle(
                                    color: isExpired && !isSubmitted ? Colors.red : Colors.grey,
                                    fontWeight: isExpired && !isSubmitted ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.primaryYellow),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(
                            studentId: widget.userId ?? '',
                            initialAssignmentId: a.id,
                          ))).then((_) => _fetchProjects());
                        },
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildStudentFilterChip(String label) {
    final isSelected = _studentStatusFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _studentStatusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white : AppColors.textPrimary) 
              : (isDark ? AppColors.surfaceDark : AppColors.backgroundWhite),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (isDark ? Colors.white : AppColors.textPrimary) 
                : (isDark ? AppColors.borderColorDark : AppColors.borderColor)
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? (isDark ? Colors.black : Colors.white) 
                : (isDark ? Colors.white70 : Colors.black), 
            fontWeight: FontWeight.bold, 
            fontSize: 12
          ),
        ),
      ),
    );
  }

  void _showJoinClassDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a Clase'),
        content: TextField(
          controller: codeController, 
          decoration: const InputDecoration(
            labelText: 'Código de Clase',
            hintText: 'Ej: 123456',
            border: OutlineInputBorder(),
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) return;
              
              if (widget.userId == null || widget.userId!.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debes iniciar sesión para unirte a una clase.'))
                  );
                }
                return;
              }

              final classroom = await _apiService.getClassroomByCode(codeController.text);
              if (classroom != null) {
                final enrollment = ClassEnrollment(
                  classroomId: classroom.id!,
                  studentId: widget.userId!,
                  status: 'Pending',
                );
                final result = await _apiService.enrollInClass(enrollment);
                if (mounted) {
                  if (result is bool && result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud enviada al profesor')));
                    Navigator.pop(context);
                    _fetchProjects(); 
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow),
            child: const Text('Unirse')
          ),
        ],
      )
    );
  }

  Widget _buildProjectTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        _buildProjectListCount(),
        Expanded(child: _buildProjectList()),
      ],
    );
  }

  Widget _buildAssignmentTab() {
    final assignments = _managedAssignments;
    
    if (assignments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No has creado ninguna convocatoria aún'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => AssignmentCreationScreen(teacherId: widget.userId!))
                ).then((_) => _fetchProjects()),
                child: const Text('Crear Primera Convocatoria'),
              ),
            ],
          ),
        ),
      );
    }

    // Group assignments by classroom
    final Map<String, List<Assignment>> groupedAssignments = {};
    for (var a in assignments) {
      final className = a.classroomId != null 
          ? _studentClasses.cast<Classroom?>().firstWhere((c) => c?.id == a.classroomId, orElse: () => null)?.name ?? 'Clase Desconocida'
          : 'Sin Clase Asignada';
      if (!groupedAssignments.containsKey(className)) {
        groupedAssignments[className] = [];
      }
      groupedAssignments[className]!.add(a);
    }

    final sortedKeys = groupedAssignments.keys.toList()..sort();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final className = sortedKeys[index];
        final classAssignments = groupedAssignments[className]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
              child: Text(
                className,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryYellow),
              ),
            ),
            ...classAssignments.map((a) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: a.dueDate != null 
                    ? Text('Vence: ${a.dueDate!.day}/${a.dueDate!.month} ${a.dueDate!.hour.toString().padLeft(2, '0')}:${a.dueDate!.minute.toString().padLeft(2, '0')}') 
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAssignmentDetails(a),
              ),
            )).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showAssignmentDetails(Assignment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(a.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alumnos que han entregado:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (widget.role.toLowerCase() == 'teacher')
                  TextButton.icon(
                    onPressed: () => _exportToCsv(a),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Exportar CSV'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primaryYellow),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _apiService.getProjects(assignmentId: a.id),
                  if (a.classroomId != null) _apiService.getClassMembers(a.classroomId!) else Future.value(<ClassEnrollment>[]),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final projects = (snapshot.data?[0] as List<Project>?) ?? [];
                  final enrollments = (snapshot.data?[1] as List<ClassEnrollment>?) ?? [];
                  
                  if (projects.isEmpty && enrollments.isEmpty) return const Center(child: Text('Nadie ha entregado todavía', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)));
                  
                  // Setup tracking lists
                  final submittedStudentIds = projects.map((p) => p.studentId).toSet();
                  
                  // Enrolled students who haven't submitted
                  final pendingStudents = enrollments.where((e) => !submittedStudentIds.contains(e.studentId)).toList();

                  return ListView(
                    children: [
                      if (projects.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('✅ Entregados', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                        ...projects.map((p) {
                          String status = p.status ?? 'Pendiente';
                          Color statusColor = status.toLowerCase() == 'evaluado' ? Colors.blue : Colors.orange;

                          return ListTile(
                            leading: CircleAvatar(
                               backgroundColor: statusColor.withOpacity(0.2),
                               child: Icon(Icons.check, color: statusColor, size: 18)
                            ),
                            title: Text(p.teamName ?? 'Alumno sin nombre'),
                            subtitle: Text('Estado: $status - Categoría: ${p.category ?? "Proyecto"}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                               Navigator.pop(context);
                               Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationScreen(projectId: p.id, projectName: p.title ?? 'Proyecto', evaluatorId: widget.userId)));
                            },
                          );
                        }),
                      ],
                      if (pendingStudents.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: Text('⏳ Sin Entregar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                        ...pendingStudents.map((e) => ListTile(
                          leading: CircleAvatar(
                             backgroundColor: Colors.red.withOpacity(0.1),
                             child: const Icon(Icons.person_off, color: Colors.red, size: 18)
                          ),
                          title: Text(e.studentName ?? e.studentId),
                          subtitle: const Text('Aún no ha subido su proyecto', style: TextStyle(color: Colors.red, fontSize: 12)),
                        )),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar Ventana'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCsv(Assignment a) async {
    try {
      AppTheme.showCustomSnackBar(context, 'Generando reporte CSV, por favor espera...');
      
      final projects = await _apiService.getProjects(assignmentId: a.id);
      if (projects.isEmpty) {
        if (mounted) AppTheme.showCustomSnackBar(context, 'No hay entregas para exportar.', isError: true);
        return;
      }

      final buffer = StringBuffer();
      // Use UTF-8 BOM to ensure proper encoding in Excel
      buffer.write('\uFEFF');
      buffer.writeln('ID Proyecto,Equipo/Alumno,Categoria,Status,Puntaje General,Retroalimentacion');

      for (var p in projects) {
        String scoreStr = 'N/A';
        String feedbackStr = 'N/A';
        
        if (p.status?.toLowerCase() == 'evaluado') {
          final eval = await _apiService.getEvaluationByProjectId(p.id!);
          if (eval != null) {
            final score = eval.scores?['General'] ?? eval.detailedScores?.values.fold(0, (sum, val) => (sum ?? 0) + val);
            scoreStr = score?.toString() ?? 'N/A';
            feedbackStr = eval.feedback?.replaceAll(',', ';').replaceAll('\n', ' ') ?? 'N/A';
          }
        }
        
        final safeTeam = p.teamName?.replaceAll(',', ';') ?? 'S/N';
        final safeCat = p.category?.replaceAll(',', ';') ?? 'N/A';
        final idStr = p.id ?? 'Unknown';
        
        buffer.writeln('$idStr,$safeTeam,$safeCat,${p.status ?? "Pendiente"},$scoreStr,$feedbackStr');
      }

      final tempDir = await getTemporaryDirectory();
      final cleanName = a.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final path = '${tempDir.path}/Resultados_$cleanName.csv';
      
      final file = File(path);
      await file.writeAsString(buffer.toString());
      
      if (mounted) AppTheme.showCustomSnackBar(context, 'Reporte generado. Abriendo archivo...');
      await OpenFilex.open(path);
      
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) AppTheme.showCustomSnackBar(context, 'Error al exportar: $e', isError: true);
    }
  }

  IconData _getFabIcon() {
    if (widget.role.toLowerCase() == 'admin') return Icons.dashboard_customize;
    if (widget.role.toLowerCase() == 'evaluator') return Icons.class_outlined;
    return Icons.group_add_outlined;
  }

  String _getFabLabel() {
    if (widget.role.toLowerCase() == 'admin') return 'Admin Panel';
    if (widget.role.toLowerCase() == 'evaluator') return 'Mis Clases';
    return 'Unirme a Clase';
  }

  Widget _buildProjectListCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_filteredProjects.length} resultados encontrados', 
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Buscar proyectos...',
          prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildFilterChip('Todos'),
          const SizedBox(width: 8),
          _buildFilterChip('Pendientes'),
          const SizedBox(width: 8),
          _buildFilterChip('Evaluados'),
          const SizedBox(width: 8),
          _buildFilterChip('Recomendados', isAi: true),
        ],
      ),
    );
  }

  Future<void> _runMatchmaking() async {
    if (_allProjects.isEmpty || widget.userId == null) return;
    
    setState(() => _isMatchmaking = true);
    
    try {
      final ids = await _apiService.getMatchmakingRecommendations(
        widget.userId!,
        widget.role,
        _allProjects,
      );
      
      if (mounted) {
        setState(() {
          _recommendedProjectIds = ids;
          if (_recommendedProjectIds.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('La IA no encontró recomendaciones compatibles para ti.'))
             );
             _selectedFilter = 'Todos'; // Revert
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('La IA encontró ${ids.length} proyectos recomendados.'))
             );
          }
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error obteniendo recomendaciones de IA.'))
         );
         setState(() => _selectedFilter = 'Todos');
      }
    } finally {
      if (mounted) setState(() => _isMatchmaking = false);
    }
  }

  Widget _buildFilterChip(String label, {bool isAi = false}) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (isAi && label == 'Recomendados' && !isSelected && _recommendedProjectIds.isEmpty) {
           setState(() => _selectedFilter = label);
           _runMatchmaking();
        } else {
           setState(() => _selectedFilter = label);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isAi ? Colors.purple : (isDark ? Colors.white : AppColors.textPrimary)) 
              : (isDark ? AppColors.surfaceDark : AppColors.backgroundWhite),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (isAi ? Colors.purpleAccent : (isDark ? Colors.white : AppColors.textPrimary)) 
                : (isDark ? AppColors.borderColorDark : AppColors.borderColor)
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAi) ...[
               Icon(Icons.auto_awesome, size: 14, color: isSelected ? Colors.white : Colors.purple),
               const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? (isDark ? Colors.black : Colors.white) 
                    : (isAi ? Colors.purple : (isDark ? Colors.white70 : Colors.black)), 
                fontWeight: FontWeight.bold
              ),
            ),
            if (isAi && _selectedFilter == label && _isMatchmaking) ...[
               const SizedBox(width: 8),
               const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    final projects = _filteredProjects;

    if (projects.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];
        final isEvaluated = widget.role.toLowerCase() == 'evaluator' 
            ? _evaluatedProjectIds.contains(p.id) 
            : p.status?.toLowerCase() == 'evaluado';

        return ProjectCard(
          project: p,
          isEvaluated: isEvaluated,
          userRole: widget.role,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectDetailScreen(
                project: p, 
                userRole: widget.role,
                userId: widget.userId,
              )),
            ).then((_) => _fetchProjects());
          },
        );
      },
    );
  }

  Widget _buildProjectSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: SkeletonLoader(height: 120, borderRadius: 16),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_outlined, size: 64, color: AppColors.primaryYellow),
          ),
          const SizedBox(height: 24),
          const Text('Aún no hay proyectos aquí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Cuando se suban proyectos aparecerán en esta lista', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchProjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
          if (widget.role.toLowerCase() == 'student') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(studentId: widget.userId ?? 'student_1'))),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Subir Mi Proyecto'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryYellow, side: const BorderSide(color: AppColors.primaryYellow)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(BuildContext context, Project p) {
    final title = p.title ?? p.teamName ?? 'Sin Título';
    final category = p.category ?? 'General';
    final isEvaluated = widget.role.toLowerCase() == 'evaluator' 
        ? _evaluatedProjectIds.contains(p.id) 
        : p.status?.toLowerCase() == 'evaluado';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailScreen(
              project: p,
              userRole: widget.role,
              userId: widget.userId,
            )),
          ).then((_) => _fetchProjects());
        },
        child: GlassmorphismCard(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildIcon(category),
              const SizedBox(width: 16),
              Expanded(child: _buildDetails(context, title, category, isEvaluated, p.technologies)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String category) {
    IconData icon = Icons.computer;
    if (category.contains('Mobile')) icon = Icons.phone_android;
    if (category.contains('Hardware') || category.contains('IoT')) icon = Icons.settings_input_component;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(icon, color: AppColors.primaryYellow),
    );
  }

  Widget _buildDetails(BuildContext context, String title, String category, bool isEvaluated, List<String>? tech) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, 
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            ),
            _buildStatusBadge(isEvaluated),
          ],
        ),
        const SizedBox(height: 8),
        if (tech != null && tech.isNotEmpty)
          Wrap(
            spacing: 8,
            children: tech.map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 10)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          )
        else
          Text(category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isEvaluated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEvaluated ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEvaluated ? 'Evaluado' : 'Pendiente',
        style: TextStyle(fontSize: 10, color: isEvaluated ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            onTap: () async {
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              final userProfile = await _apiService.getUserProfile(widget.userId ?? '');
              Navigator.pop(context); // Close dialog

              if (userProfile != null) {
                final updatedUser = await Navigator.push<User>(
                  context, 
                  MaterialPageRoute(builder: (_) => ProfileScreen(user: userProfile))
                );
                if (updatedUser != null) {
                  // Refresh local state/UI if needed
                  _loadUserProfile();
                  setState(() {});
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar datos del perfil')));
              }
            },
          ),
          if (widget.role.toLowerCase() == 'evaluator')
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Mis Rúbricas'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RubricManagementScreen(teacherId: widget.userId ?? 'teacher_1'))),
            ),
          ListTile(
            leading: const Icon(Icons.class_outlined),
            title: const Text('Mis Clases'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomManagementScreen(userId: widget.userId ?? '', role: widget.role))),
          ),
          if (widget.role.toLowerCase() == 'teacher' || widget.role.toLowerCase() == 'evaluator') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
              title: const Text('Descargar Reporte General (PDF)'),
              onTap: () async {
                 Navigator.pop(context); // Close drawer
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando reporte PDF global...')));
                 await PdfService.generateGlobalClassReport(widget.userId ?? '');
              },
            ),
          ],
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_session');
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        image: _portadaUrl != null && _portadaUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(_portadaUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
              )
            : null,
      ),
      accountName: Text(
        widget.userFullName ?? 'Usuario',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
      ),
      accountEmail: Text(
        'Rol: ${widget.role}',
        style: const TextStyle(color: Colors.white70, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: _fotoPerfil != null && _fotoPerfil!.isNotEmpty
            ? NetworkImage(_fotoPerfil!)
            : null,
        child: _fotoPerfil == null || _fotoPerfil!.isEmpty
            ? const Icon(Icons.person, color: AppColors.primaryYellow, size: 40)
            : null,
      ),
    );
  }
}
