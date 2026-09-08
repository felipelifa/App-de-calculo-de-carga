import '../enums/adaptation_type.dart';

/// Uma adaptação que pode ser aplicada a um exercício.
class V2Adaptation {
  final V2AdaptationType type;
  final String description;
  final Map<String, dynamic> parameters;

  const V2Adaptation({
    required this.type,
    required this.description,
    this.parameters = const {},
  });

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'description': description,
    'parameters': parameters,
  };

  factory V2Adaptation.fromMap(Map<String, dynamic> m) => V2Adaptation(
    type: _parseType(m['type']),
    description: m['description'] as String? ?? '',
    parameters: Map<String, dynamic>.from(m['parameters'] ?? {}),
  );

  static V2AdaptationType _parseType(dynamic value) {
    if (value == null) return V2AdaptationType.reduceAmplitude;
    return V2AdaptationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => V2AdaptationType.reduceAmplitude,
    );
  }
}
