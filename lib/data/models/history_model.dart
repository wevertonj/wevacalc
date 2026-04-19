import 'package:wevacalc/domain/entities/history_entry.dart';

class HistoryModel {
  final int? id;
  final String expression;
  final String result;
  final int createdAt;
  final String? name;
  final bool isFavorite;

  const HistoryModel({
    this.id,
    required this.expression,
    required this.result,
    required this.createdAt,
    this.name,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'expression': expression,
      'result': result,
      'created_at': createdAt,
      'name': name,
      'is_favorite': isFavorite ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] as int?,
      expression: map['expression'] as String,
      result: map['result'] as String,
      createdAt: map['created_at'] as int,
      name: map['name'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }

  HistoryEntry toEntity() {
    return HistoryEntry(
      id: id,
      expression: expression,
      result: result,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      name: name,
      isFavorite: isFavorite,
    );
  }

  factory HistoryModel.fromEntity(HistoryEntry entity) {
    return HistoryModel(
      id: entity.id,
      expression: entity.expression,
      result: entity.result,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      name: entity.name,
      isFavorite: entity.isFavorite,
    );
  }
}
