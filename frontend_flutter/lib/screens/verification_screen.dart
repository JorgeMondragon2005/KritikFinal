import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    if (_codeController.text.length != 6) return;

    setState(() => _isLoading = true);
    
    final success = await _apiService.verifyEmail(widget.email, _codeController.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Correo verificado! Ya puedes iniciar sesión.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código incorrecto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Hemos enviado un código a:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              widget.email,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'Código de 6 dígitos',
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerify,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verificar'),
            ),
          ],
        ),
      ),
    );
  }
}
