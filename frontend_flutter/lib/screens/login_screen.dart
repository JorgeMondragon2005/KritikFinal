// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';
import 'project_list_screen.dart';
import 'register_screen.dart';
import 'verification_screen.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'Student';
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _navigateToRoleSelection(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RoleSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kritik',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    hintText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(hintText: 'Selecciona tu Rol'),
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Alumno / Proyectista')),
                    DropdownMenuItem(value: 'Evaluator', child: Text('Evaluador / Juez')),
                    DropdownMenuItem(value: 'Admin', child: Text('Administrador')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_idController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa tu ID')),
                      );
                      return;
                    }

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    setState(() => _isLoading = true);

                    try {
                      User? user;
                      if (_passwordController.text.isNotEmpty) {
                        user = await _apiService.login(
                          _idController.text,
                          _passwordController.text,
                        );
                      }

                      if (mounted) {
                        // Save session
                        if (user != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('user_session', jsonEncode(user.toJson()));
                        }

                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ProjectListScreen(
                              role: user?.role ?? _selectedRole.toLowerCase(),
                              userId: user?.id ?? _idController.text,
                              userFullName: user?.fullName ?? _idController.text,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        String errorMessage = 'Error al iniciar sesión';
                        if (e is DioException) {
                          errorMessage = e.response?.data.toString() ?? errorMessage;
                          
                          if (errorMessage.contains('no verificado')) {
                             // Option to go verify
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text(errorMessage),
                                 action: SnackBarAction(
                                   label: 'Verificar',
                                   onPressed: () => Navigator.of(context).push(
                                     MaterialPageRoute(builder: (_) => VerificationScreen(email: _idController.text))
                                   ),
                                 ),
                               ),
                             );
                             return;
                          }
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Entrar'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.borderColor, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Text(
                          'o',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.borderColor, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Regístrate aquí'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToRoleSelection(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundWhite,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(
                        color: AppColors.textPrimary,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const Text('Acceso como Invitado'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
