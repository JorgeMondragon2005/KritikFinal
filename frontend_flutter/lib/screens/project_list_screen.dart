import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'evaluation_screen.dart';
import 'admin_dashboard_screen.dart';
import 'results_screen.dart';
import 'student_upload_screen.dart';
import 'assignment_creation_screen.dart';
import 'rubric_management_screen.dart';
import 'login_screen.dart';
import '../models/assignment_model.dart';
import 'profile_screen.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../models/enrollment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'classroom_management_screen.dart';

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
  List<Classroom> _studentClasses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  String _studentStatusFilter = 'Pendientes'; // For student dashboard

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final role = widget.role.toLowerCase();
      final userId = widget.userId;

      if (userId == null || userId.isEmpty) {
        setState(() {
          _allProjects = [];
          _pendingAssignments = [];
          _studentClasses = [];
          _isLoading = false;
        });
        return;
      }

      if (role == 'student') {
        final results = await Future.wait([
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

        setState(() {
          _allProjects = projects;
          _allAssignmentsForStudent = assignments;
          _pendingAssignments = pending;
          _studentClasses = classrooms;
          _isLoading = false;
        });
      } else {
        final teacherId = role == 'evaluator' ? userId : null;
        final projects = await _apiService.getProjects(teacherId: teacherId);
        setState(() {
          _allProjects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<Project> get _filteredProjects {
    return _allProjects.where((p) {
      final title = p.title ?? p.teamName ?? '';
      final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      final isEvaluated = p.status?.toLowerCase() == 'evaluado';
      
      if (_selectedFilter == 'Pendientes') matchesFilter = !isEvaluated;
      if (_selectedFilter == 'Evaluados') matchesFilter = isEvaluated;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget build(BuildContext context) {
    bool isEvaluator = widget.role.toLowerCase() == 'evaluator';

    return DefaultTabController(
      length: isEvaluator ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Proyectos', style: Theme.of(context).textTheme.headlineMedium),
          backgroundColor: AppColors.backgroundOffWhite,
          elevation: 0,
          bottom: isEvaluator 
            ? const TabBar(
                tabs: [
                  Tab(text: 'Proyectos Recibidos'),
                  Tab(text: 'Mis Convocatorias'),
                ],
                labelColor: AppColors.textPrimary,
                indicatorColor: AppColors.primaryYellow,
              )
            : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchProjects,
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
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : isEvaluator
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
            ? const Center(child: CircularProgressIndicator())
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
                        onTap: (isExpired && !isSubmitted) ? null : () {
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
    return GestureDetector(
      onTap: () => setState(() => _studentStatusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
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
    return FutureBuilder<List<Assignment>>(
      future: _apiService.getAssignments(teacherId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return Center(
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
                  ).then((_) => setState(() {})),
                  child: const Text('Crear Primera Convocatoria'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Código: ${a.accessCode ?? "---"}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAssignmentDetails(a),
              ),
            );
          },
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
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(a.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryYellow),
              ),
              child: Column(
                children: [
                  const Text('Comparte este código con tus alumnos:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(a.accessCode ?? 'N/A', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Alumnos que han entregado:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Project>>(
                future: _apiService.getProjects(assignmentId: a.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const Center(child: Text('Nadie ha entregado todavía', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)));
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(list[index].teamName ?? 'Alumno sin nombre'),
                      subtitle: Text(list[index].category ?? 'Proyecto'),
                      onTap: () {
                         Navigator.pop(context);
                         Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationScreen(projectId: list[index].id, projectName: list[index].title ?? 'Proyecto')));
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Buscar proyectos...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.backgroundWhite,
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    final projects = _filteredProjects;
    if (projects.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];
        return _buildProjectItem(context, p);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('No se encontraron proyectos'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchProjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
          if (widget.role == 'Student') ...[
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
    final isEvaluated = p.status?.toLowerCase() == 'evaluado';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () async {
          if (widget.role == 'Admin' || widget.role == 'Student') {
             // Maybe show details instead of evaluation?
             return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluationScreen(
                projectId: p.id ?? '',
                projectName: title,
              ),
            ),
          );

          if (result == true) {
            _fetchProjects();
          }
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
              final updatedUser = await Navigator.push<User>(
                context, 
                MaterialPageRoute(builder: (_) => ProfileScreen(user: User(
                  id: widget.userId,
                  fullName: widget.userFullName,
                  role: widget.role,
                  // We might want to fetch full user data here if needed
                )))
              );
              if (updatedUser != null) {
                // Refresh local state/UI if needed
                setState(() {});
              }
            },
          ),
          if (widget.role.toLowerCase() == 'student')
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Subir Mi Proyecto'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(studentId: widget.userId ?? ''))),
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
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Resultados Live'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())),
          ),
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
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppColors.primaryYellow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.primaryYellow, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            (widget.userFullName?.split(' ').first ?? 'Usuario'), 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          Text('Rol: ${widget.role}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }
}
