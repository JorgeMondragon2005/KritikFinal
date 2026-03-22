class AppNotification {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.actionUrl,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
  ) => AppNotification(
    id:
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['Id']?.toString(),
    userId: json['userId']?.toString() ?? json['UserId']?.toString() ?? '',
    title: json['title']?.toString() ?? json['Title']?.toString() ?? '',
    message: json['message']?.toString() ?? json['Message']?.toString() ?? '',
    isRead: json['isRead'] ?? json['IsRead'] ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'].toString())
        : (json['CreatedAt'] != null
              ? DateTime.parse(json['CreatedAt'].toString())
              : DateTime.now()),
    actionUrl: json['actionUrl']?.toString() ?? json['ActionUrl']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'actionUrl': actionUrl,
  };
}
