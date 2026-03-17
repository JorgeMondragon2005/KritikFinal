import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final baseUrl = 'https://kritikfinal.onrender.com/api/auth';
  
  // Try registering
  print('Trying to register...');
  final regRes = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'testbot@example.com',
      'passwordHash': 'Test1234!',
      'fullName': 'Test Bot',
      'role': 'Student'
    })
  );
  print('Register status: ${regRes.statusCode}');
  print('Register body: ${regRes.body}');
  
  // Try login
  print('\nTrying to login...');
  final logRes = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'testbot@example.com',
      'password': 'Test1234!'
    })
  );
  print('Login status: ${logRes.statusCode}');
  print('Login body: ${logRes.body}');
}
