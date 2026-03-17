class Assignment {
  final String? id;
  final String title;
  final String description;
  final String teacherId;
  final String? rubricId;
  final DateTime? dueDate;
  final String? accessCode;
  final String? classroomId;
  final List<String>? assignedEvaluators;
  final List<JurorAssignment>? jurors;

  Assignment({
    this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    this.rubricId,
    this.dueDate,
    this.accessCode,
    this.classroomId,
    this.assignedEvaluators,
    this.jurors,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? json['Id']?.toString(),
    title: json['title']?.toString() ?? json['Title']?.toString() ?? 'Sin Título',
    description: json['description']?.toString() ?? json['Description']?.toString() ?? '',
    teacherId: json['teacherId']?.toString() ?? json['TeacherId']?.toString() ?? '',
    rubricId: json['rubricId']?.toString() ?? json['RubricId']?.toString(),
    dueDate: json['dueDate'] != null ? _parseDateSafe(json['dueDate'].toString()) : 
             (json['DueDate'] != null ? _parseDateSafe(json['DueDate'].toString()) : null),
    accessCode: json['accessCode']?.toString() ?? json['AccessCode']?.toString(),
    classroomId: json['classroomId']?.toString() ?? json['ClassroomId']?.toString(),
    assignedEvaluators: (json['assignedEvaluators'] as List?)?.map((e) => e.toString()).toList() ?? 
                        (json['AssignedEvaluators'] as List?)?.map((e) => e.toString()).toList(),
    jurors: (json['jurors'] as List?)?.map((e) => JurorAssignment.fromJson(e)).toList() ??
            (json['Jurors'] as List?)?.map((e) => JurorAssignment.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'teacherId': teacherId,
    'rubricId': rubricId,
    'dueDate': dueDate?.toUtc().toIso8601String(),
    'accessCode': accessCode,
    'classroomId': classroomId,
    'assignedEvaluators': assignedEvaluators,
    'jurors': jurors?.map((x) => x.toJson()).toList(),
  };

  static DateTime? _parseDateSafe(String dateStr) {
    if (dateStr.isEmpty) return null;
    if (!dateStr.endsWith('Z')) dateStr += 'Z';
    return DateTime.parse(dateStr).toLocal();
  }
}

class JurorAssignment {
  String email;
  int weightPercentage;
  String status;
  String? userId;

  JurorAssignment({
    required this.email,
    required this.weightPercentage,
    this.status = 'Pending',
    this.userId,
  });

  factory JurorAssignment.fromJson(Map<String, dynamic> json) => JurorAssignment(
    email: json['email']?.toString() ?? json['Email']?.toString() ?? '',
    weightPercentage: json['weightPercentage'] as int? ?? json['WeightPercentage'] as int? ?? 0,
    status: json['status']?.toString() ?? json['Status']?.toString() ?? 'Pending',
    userId: json['userId']?.toString() ?? json['UserId']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'Email': email,
    'WeightPercentage': weightPercentage,
    'Status': status,
    'UserId': userId,
  };
}
