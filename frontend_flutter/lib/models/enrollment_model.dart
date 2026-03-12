class ClassEnrollment {
  final String? id;
  final String classroomId;
  final String studentId;
  final String? studentName;
  final String status;
  final DateTime? requestedAt;

  ClassEnrollment({
    this.id,
    required this.classroomId,
    required this.studentId,
    this.studentName,
    required this.status,
    this.requestedAt,
  });

  factory ClassEnrollment.fromJson(Map<String, dynamic> json) => ClassEnrollment(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? json['Id']?.toString(),
        classroomId: json['classroomId']?.toString() ?? json['ClassroomId']?.toString() ?? '',
        studentId: json['studentId']?.toString() ?? json['StudentId']?.toString() ?? '',
        studentName: json['studentName']?.toString() ?? json['StudentName']?.toString(),
        status: json['status']?.toString() ?? json['Status']?.toString() ?? 'Pending',
        requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'].toString()) : 
                     (json['RequestedAt'] != null ? DateTime.tryParse(json['RequestedAt'].toString()) : null),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'classroomId': classroomId,
      'studentId': studentId,
      'status': status,
    };
    if (id != null) map['id'] = id;
    if (studentName != null) map['studentName'] = studentName;
    if (requestedAt != null) map['requestedAt'] = requestedAt!.toIso8601String();
    return map;
  }
}
