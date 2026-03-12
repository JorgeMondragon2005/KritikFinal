import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.telefono);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    final updatedUser = User(
      id: widget.user.id,
      email: widget.user.email,
      fullName: _nameController.text,
      role: widget.user.role,
      telefono: _phoneController.text,
      bio: _bioController.text,
      fotoPerfil: widget.user.fotoPerfil,
    );

    final success = await _apiService.updateUserProfile(updatedUser);
    
    if (success) {
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(updatedUser.toJson()));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, updatedUser);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveProfile,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.person, size: 50, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Biografía',
                prefixIcon: Icon(Icons.info),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
