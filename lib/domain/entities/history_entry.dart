class HistoryEntry {
  final int? id;
  final String expression;
  final String result;
  final DateTime createdAt;
  final String? name;
  final bool isFavorite;

  const HistoryEntry({
    this.id,
    required this.expression,
    required this.result,
    required this.createdAt,
    this.name,
    this.isFavorite = false,
  });

  HistoryEntry copyWith({
    int? id,
    String? expression,
    String? result,
    DateTime? createdAt,
    String? name,
    bool? isFavorite,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          expression == other.expression &&
          result == other.result &&
          createdAt == other.createdAt &&
          name == other.name &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode =>
      Object.hash(id, expression, result, createdAt, name, isFavorite);
}
