import 'criterion_model.dart';

class Rubric {
  final String? id;
  final String? name;
  final List<Criterion> items;
  final bool isGlobal;
  final String? creatorId;

  Rubric({
    this.id,
    this.name,
    required this.items,
    this.isGlobal = false,
    this.creatorId,
  });

  factory Rubric.fromJson(Map<String, dynamic> json) => Rubric(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        name: json['name'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => Criterion.fromJson(item as Map<String, dynamic>))
            .toList(),
        isGlobal: json['isGlobal'] as bool? ?? false,
        creatorId: json['creatorId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
        'isGlobal': isGlobal,
        'creatorId': creatorId,
      };
}
