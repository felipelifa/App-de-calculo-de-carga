import '../enums/relationship_type.dart';

/// Relação direcionada entre dois exercícios.
class V2Relationship {
  final String targetId;
  final V2RelationshipType type;
  final String? note;

  const V2Relationship({
    required this.targetId,
    required this.type,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'targetId': targetId,
    'type': type.name,
    'note': note,
  };

  factory V2Relationship.fromMap(Map<String, dynamic> m) => V2Relationship(
    targetId: m['targetId'] as String? ?? '',
    type: V2RelationshipType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => V2RelationshipType.substitute,
    ),
    note: m['note'] as String?,
  );
}
