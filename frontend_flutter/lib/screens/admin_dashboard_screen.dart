// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'admin_users_screen.dart' as admin_users;


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Project>? _projects;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final projects = await _apiService.getProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdminOptionsCard(),
                const SizedBox(height: 30),
                Text('Proyectos Cargados (${_projects?.length ?? 0})', 
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 15),
                if (_projects == null || _projects!.isEmpty)
                  _buildEmptyState()
                else
                  ..._projects!.map((p) => _buildProjectTile(p)),
              ],
            ),
          ),
    );
  }

  Widget _buildAdminOptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow.shade100, Colors.yellow.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Acciones de Administrador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Configura los roles de los usuarios registrados del evento.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const admin_users.AdminUsersScreen()));
            },
            icon: const Icon(Icons.people_outline),
            label: const Text('Gestión de Usuarios (Roles)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectTile(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.yellow.shade700,
          child: const Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(project.title ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(project.category ?? 'Sin Categoría'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay proyectos registrados', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
