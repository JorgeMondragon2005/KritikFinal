// lib/screens/admin_dashboard_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Project>? _projects;
  bool _isLoading = true;
  bool _isImporting = false;

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

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        setState(() => _isImporting = true);
        
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(content);
        
        List<Project> newProjects = jsonList.map((j) => Project.fromJson(j)).toList();
        
        bool success = await _apiService.createProjectsBatch(newProjects);
        
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Importación exitosa!')),
          );
          _loadData(); // Reload list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir los proyectos al servidor')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isImporting = false);
    }
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
                _buildImportCard(),
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

  Widget _buildImportCard() {
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
          const Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Carga Masiva de Proyectos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Sube un archivo JSON con los datos del evento.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isImporting ? null : _handleImport,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: _isImporting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Seleccionar Archivo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isImporting ? null : _loadDemoData,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Cargar Proyectos Demo'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDemoData() async {
    setState(() => _isImporting = true);
    final demoProjects = [
      Project(title: 'App de Salud AI', category: 'Mobile / AI', technologies: ['Flutter', 'Python']),
      Project(title: 'Internet de las Cosas (IoT)', category: 'Hardware', technologies: ['Arduino', 'C++']),
      Project(title: 'Plataforma E-learning', category: 'Web', technologies: ['React', 'Node.js']),
    ];
    
    bool success = await _apiService.createProjectsBatch(demoProjects);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Datos demo cargados!')));
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar datos demo')));
    }
    setState(() => _isImporting = false);
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
