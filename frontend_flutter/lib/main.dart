import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/project_list_screen.dart';
import 'dart:convert';
import 'models/user_model.dart';

import 'package:provider/provider.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_session');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: KritikApp(savedUser: userData != null ? User.fromJson(jsonDecode(userData)) : null),
    ),
  );
}

class KritikApp extends StatelessWidget {
  final User? savedUser;
  const KritikApp({super.key, this.savedUser});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    
    return MaterialApp(
      title: 'Kritik App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: savedUser != null 
        ? ProjectListScreen(
            role: savedUser!.role ?? 'student',
            userId: savedUser!.id ?? '',
            userFullName: savedUser!.fullName ?? '',
          )
        : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
