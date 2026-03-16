import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

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

  String? _fotoPerfilUrl;
  String? _portadaUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.telefono);
    _bioController = TextEditingController(text: widget.user.bio);
    
    _fotoPerfilUrl = widget.user.fotoPerfil;
    if (_fotoPerfilUrl != null && _fotoPerfilUrl!.startsWith('/')) {
      _fotoPerfilUrl = 'https://kritikfinal.onrender.com$_fotoPerfilUrl';
    }
    
    _portadaUrl = widget.user.portadaUrl;
    if (_portadaUrl != null && _portadaUrl!.startsWith('/')) {
      _portadaUrl = 'https://kritikfinal.onrender.com$_portadaUrl';
    }
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
      fotoPerfil: _fotoPerfilUrl,
      portadaUrl: _portadaUrl,
    );

    try {
      final success = await _apiService.updateUserProfile(updatedUser);
      
      if (success) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_session', jsonEncode(updatedUser.toJson()));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el perfil')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage(bool isCover) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(isCover, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(isCover, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(bool isCover, ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      final url = await _apiService.uploadFile(File(pickedFile.path));
      if (url != null) {
        // Fix relative URLs immediately from backend uploads 
        String finalUrl = url;
        if (finalUrl.startsWith('/')) {
            finalUrl = 'https://kritikfinal.onrender.com$finalUrl';
        }
        setState(() {
          if (isCover) _portadaUrl = finalUrl;
          else _fotoPerfilUrl = finalUrl;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la imagen')),
        );
      }
      setState(() => _isLoading = false);
    }
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
        child: Column(
          children: [
            // Cover and Avatar Section
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Cover Photo
                GestureDetector(
                  onTap: _isLoading ? null : () => _pickImage(true),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.blue.withOpacity(0.1),
                    child: _portadaUrl != null && _portadaUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _portadaUrl!,
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.blue.shade300, size: 40),
                              const SizedBox(height: 8),
                              Text('Añadir Portada', style: TextStyle(color: Colors.blue.shade400)),
                            ],
                          ),
                  ),
                ),
                
                // Profile Avatar Overlay
                Positioned(
                  bottom: -50,
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _pickImage(false),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (_fotoPerfilUrl != null && _fotoPerfilUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(_fotoPerfilUrl!)
                                : null,
                            child: (_fotoPerfilUrl == null || _fotoPerfilUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 70), // Spacing for avatar overlap
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
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
                  _buildThemeSelector(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar Cambios'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apariencia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              _buildThemeOption(
                title: 'Tema del Sistema',
                icon: Icons.brightness_auto,
                value: ThemeMode.system,
                current: themeNotifier.themeMode,
                onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
              ),
              const Divider(height: 1),
              _buildThemeOption(
                title: 'Modo Claro',
                icon: Icons.light_mode,
                value: ThemeMode.light,
                current: themeNotifier.themeMode,
                onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
              ),
              const Divider(height: 1),
              _buildThemeOption(
                title: 'Modo Oscuro',
                icon: Icons.dark_mode,
                value: ThemeMode.dark,
                current: themeNotifier.themeMode,
                onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode current,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == current;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSelected ? AppColors.primaryYellow : (isDark ? Colors.white70 : Colors.black54)),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryYellow : (isDark ? Colors.white : Colors.black),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryYellow) : null,
    );
  }
}
