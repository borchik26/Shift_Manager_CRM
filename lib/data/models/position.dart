/// Position model representing a job title with hourly rate
class Position {
  final String id;
  final String name;
  final double hourlyRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Position({
    required this.id,
    required this.name,
    required this.hourlyRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String,
      name: json['name'] as String,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hourly_rate': hourlyRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Position copyWith({
    String? id,
    String? name,
    double? hourlyRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Position(
      id: id ?? this.id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
