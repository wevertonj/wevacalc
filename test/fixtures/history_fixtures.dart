import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/data/models/history_model.dart';

class HistoryFixtures {
  HistoryFixtures._();

  static final DateTime timestamp1 = DateTime(2026, 1, 15, 10, 30);
  static final DateTime timestamp2 = DateTime(2026, 1, 15, 11, 45);
  static final DateTime timestamp3 = DateTime(2026, 1, 16, 9, 0);

  static HistoryEntry get entry1 => HistoryEntry(
    id: 1,
    expression: '12.50 + 3.00',
    result: '15.50',
    createdAt: timestamp1,
  );

  static HistoryEntry get entry2 => HistoryEntry(
    id: 2,
    expression: '100.00 × 2.00',
    result: '200.00',
    createdAt: timestamp2,
  );

  static HistoryEntry get entry3 => HistoryEntry(
    id: 3,
    expression: '50.00 − 25.00',
    result: '25.00',
    createdAt: timestamp3,
  );

  static HistoryEntry get entryWithName => HistoryEntry(
    id: 4,
    expression: '500.00 ÷ 2.00',
    result: '250.00',
    createdAt: timestamp1,
    name: 'Conta do mercado',
  );

  static HistoryEntry get entryFavorite => HistoryEntry(
    id: 5,
    expression: '1000.00 + 500.00',
    result: '1500.00',
    createdAt: timestamp2,
    isFavorite: true,
  );

  static HistoryEntry get entryWithNameAndFavorite => HistoryEntry(
    id: 6,
    expression: '200.00 × 3.00',
    result: '600.00',
    createdAt: timestamp3,
    name: 'Orçamento mensal',
    isFavorite: true,
  );

  static List<HistoryEntry> get entries => [entry1, entry2, entry3];

  static HistoryModel get model1 => HistoryModel(
    id: 1,
    expression: '12.50 + 3.00',
    result: '15.50',
    createdAt: timestamp1.millisecondsSinceEpoch,
  );

  static HistoryModel get model2 => HistoryModel(
    id: 2,
    expression: '100.00 × 2.00',
    result: '200.00',
    createdAt: timestamp2.millisecondsSinceEpoch,
  );

  static HistoryModel get modelWithName => HistoryModel(
    id: 4,
    expression: '500.00 ÷ 2.00',
    result: '250.00',
    createdAt: timestamp1.millisecondsSinceEpoch,
    name: 'Conta do mercado',
  );

  static HistoryModel get modelFavorite => HistoryModel(
    id: 5,
    expression: '1000.00 + 500.00',
    result: '1500.00',
    createdAt: timestamp2.millisecondsSinceEpoch,
    isFavorite: true,
  );

  static Map<String, dynamic> get map1 => {
    'id': 1,
    'expression': '12.50 + 3.00',
    'result': '15.50',
    'created_at': timestamp1.millisecondsSinceEpoch,
    'name': null,
    'is_favorite': 0,
  };

  static Map<String, dynamic> get mapWithoutId => {
    'expression': '12.50 + 3.00',
    'result': '15.50',
    'created_at': timestamp1.millisecondsSinceEpoch,
    'name': null,
    'is_favorite': 0,
  };

  static Map<String, dynamic> get mapWithName => {
    'id': 4,
    'expression': '500.00 ÷ 2.00',
    'result': '250.00',
    'created_at': timestamp1.millisecondsSinceEpoch,
    'name': 'Conta do mercado',
    'is_favorite': 0,
  };

  static Map<String, dynamic> get mapFavorite => {
    'id': 5,
    'expression': '1000.00 + 500.00',
    'result': '1500.00',
    'created_at': timestamp2.millisecondsSinceEpoch,
    'name': null,
    'is_favorite': 1,
  };
}
