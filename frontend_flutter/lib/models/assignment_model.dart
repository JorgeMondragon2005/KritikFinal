class Assignment {
  final String? id;
  final String title;
  final String description;
  final String teacherId;
  final String? rubricId;
  final DateTime? dueDate;
  final String? accessCode;
  final String? classroomId;

  Assignment({
    this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    this.rubricId,
    this.dueDate,
    this.accessCode,
    this.classroomId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? json['Id']?.toString(),
    title: json['title']?.toString() ?? json['Title']?.toString() ?? 'Sin Título',
    description: json['description']?.toString() ?? json['Description']?.toString() ?? '',
    teacherId: json['teacherId']?.toString() ?? json['TeacherId']?.toString() ?? '',
    rubricId: json['rubricId']?.toString() ?? json['RubricId']?.toString(),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'].toString()) : 
             (json['DueDate'] != null ? DateTime.parse(json['DueDate'].toString()) : null),
    accessCode: json['accessCode']?.toString() ?? json['AccessCode']?.toString(),
    classroomId: json['classroomId']?.toString() ?? json['ClassroomId']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'teacherId': teacherId,
    'rubricId': rubricId,
    'dueDate': dueDate?.toIso8601String(),
    'accessCode': accessCode,
    'classroomId': classroomId,
  };
}
