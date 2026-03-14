class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? deepLink; // Redirect to a specific project or evaluation

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.deepLink,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    isRead: json['isRead'] ?? false,
    deepLink: json['deepLink']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'deepLink': deepLink,
  };
}
