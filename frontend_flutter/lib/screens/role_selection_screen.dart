// lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'project_list_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Selecciona tu Rol',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const AnimatedRoleCard(
                      title: 'Alumno',
                      role: 'Student',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 16),
                    const AnimatedRoleCard(
                      title: 'Profesor o Sinodal',
                      role: 'Evaluator',
                      icon: Icons.assignment_ind_outlined,
                    ),
                    const SizedBox(height: 16),
                    const AnimatedRoleCard(
                      title: 'Administrador',
                      role: 'Admin',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedRoleCard extends StatefulWidget {
  final String title;
  final String role;
  final IconData icon;

  const AnimatedRoleCard({super.key, required this.title, required this.role, required this.icon});

  @override
  State<AnimatedRoleCard> createState() => _AnimatedRoleCardState();
}

class _AnimatedRoleCardState extends State<AnimatedRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ProjectListScreen(role: widget.role)));
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  splashColor: AppColors.primaryYellow.withOpacity(0.1),
                  highlightColor: AppColors.primaryYellow.withOpacity(0.05),
                  onTap: () {
                    // Handled by GestureDetector for the scale effect
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 64,
                        color: AppColors.primaryYellow,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
