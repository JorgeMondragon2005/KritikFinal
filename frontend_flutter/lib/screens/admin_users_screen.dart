import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _apiService = ApiService();
  List<User>? _users;
  List<User>? _filteredUsers;
  bool _isLoading = true;
  String _searchQuery = '';
  final List<String> _roles = ['Student', 'Teacher', 'Evaluator', 'Admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _apiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    _searchQuery = query;
    if (_users == null) return;

    setState(() {
      _filteredUsers = _users!.where((user) {
        final name = (user.fullName ?? '').toLowerCase();
        final email = (user.email ?? '').toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  Future<void> _changeRole(User user, String newRole) async {
    if (user.role == newRole) return;
    if (user.id == null) return;

    // Optimistic UI update
    final oldRole = user.role;
    setState(() {
      user.role = newRole;
    });

    final success = await _apiService.updateUserRole(user.id!, newRole);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol actualizado exitosamente')),
      );
    } else {
      // Revert if failed
      setState(() {
        user.role = oldRole;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al actualizar rol')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.backgroundWhite,
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers == null || _filteredUsers!.isEmpty
                ? const Center(child: Text('No se encontraron usuarios'))
                : ListView.builder(
                    itemCount: _filteredUsers!.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryYellow
                                .withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primaryYellow,
                            ),
                          ),
                          title: Text(
                            user.fullName ?? 'Sin Nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user.email ?? 'Sin correo'),
                          trailing: DropdownButton<String>(
                            value: _roles.contains(user.role)
                                ? user.role
                                : 'Student',
                            underline: const SizedBox(),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primaryYellow,
                            ),
                            items: _roles.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _changeRole(user, newValue);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
