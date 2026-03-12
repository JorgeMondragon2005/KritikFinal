import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  
  String _selectedRole = 'Student';
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = User(
      email: _emailController.text,
      fullName: _fullNameController.text,
      role: _selectedRole,
    );

    final result = await _apiService.register(user, _passwordController.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null && result.contains('registrado')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(email: _emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? 'Error al registrarse')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crea tu cuenta',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Institucional',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Usuario',
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: 'Student', child: Text('Alumno')),
                  DropdownMenuItem(value: 'Evaluator', child: Text('Docente / Evaluador')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
