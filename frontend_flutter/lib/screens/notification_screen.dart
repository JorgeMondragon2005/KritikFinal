import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/student_upload_screen.dart';
import '../screens/project_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await _apiService.getUserNotifications(widget.userId);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead || notification.id == null) return;
    
    // Optimistic update
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          message: notification.message,
          isRead: true,
          createdAt: notification.createdAt,
          actionUrl: notification.actionUrl,
        );
      }
    });

    await _apiService.markNotificationAsRead(notification.id!);

    if (notification.actionUrl != null && mounted) {
      if (notification.actionUrl!.startsWith('/project/')) {
        final projectId = notification.actionUrl!.split('/').last;
        final project = await _apiService.getProjectById(projectId);
        if (project != null && mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project, userId: widget.userId, userRole: "evaluator")));
        }
      } else if (notification.actionUrl!.startsWith('/assignment/')) {
        final assignmentId = notification.actionUrl!.split('/').last;
        Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(studentId: widget.userId, initialAssignmentId: assignmentId)));
      } else if (notification.actionUrl!.startsWith('/student_upload/')) {
        final assignmentId = notification.actionUrl!.split('/').last;
        Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(studentId: widget.userId, initialAssignmentId: assignmentId)));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    // Optimistic update
    setState(() {
      _notifications = _notifications.map((n) => AppNotification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
          actionUrl: n.actionUrl,
        )).toList();
    });

    await _apiService.markAllNotificationsAsRead(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Marcar todo leído', style: TextStyle(color: AppColors.primaryYellow)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No tienes notificaciones', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (ctx, idx) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      tileColor: n.isRead ? Colors.transparent : (isDark ? AppColors.primaryYellow.withOpacity(0.05) : AppColors.primaryYellow.withOpacity(0.1)),
                      leading: CircleAvatar(
                        backgroundColor: n.isRead ? (isDark ? Colors.white10 : Colors.black12) : AppColors.primaryYellow,
                        child: Icon(
                          n.title.toLowerCase().contains('evaluad') ? Icons.assignment_turned_in : Icons.notifications,
                          color: n.isRead ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.message, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                          const SizedBox(height: 6),
                          Text('${n.createdAt.day.toString().padLeft(2, '0')}/${n.createdAt.month.toString().padLeft(2, '0')}/${n.createdAt.year} ${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                      onTap: () => _markAsRead(n),
                    );
                  },
                ),
    );
  }
}
