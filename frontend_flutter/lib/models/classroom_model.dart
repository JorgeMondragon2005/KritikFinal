class Classroom {
  final String? id;
  final String name;
  final String description;
  final String teacherId;
  final String accessCode;
  final DateTime? createdAt;

  Classroom({
    this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    required this.accessCode,
    this.createdAt,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? json['Id']?.toString(),
        name: json['name'] ?? json['Name'] ?? '',
        description: json['description'] ?? json['Description'] ?? '',
        teacherId: json['teacherId']?.toString() ?? json['TeacherId']?.toString() ?? '',
        accessCode: json['accessCode'] ?? json['AccessCode'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : 
                  (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt'].toString()) : null),
      );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'accessCode': accessCode,
    };
    if (id != null) data['id'] = id;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    return data;
  }
}
