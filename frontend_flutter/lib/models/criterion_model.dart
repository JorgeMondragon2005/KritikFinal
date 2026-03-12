class Criterion {
  final String criteria;
  final String description;
  final int maxPoints;

  Criterion({
    required this.criteria,
    required this.description,
    this.maxPoints = 10,
  });

  factory Criterion.fromJson(Map<String, dynamic> json) => Criterion(
        criteria: json['criteria'] as String? ?? '',
        description: json['description'] as String? ?? '',
        maxPoints: json['maxPoints'] as int? ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'criteria': criteria,
        'description': description,
        'maxPoints': maxPoints,
      };
}
