import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/ui/calculator/calculator_view_model.dart';

import '../../../mocks/mock_history_repository.dart';
import '../../../fixtures/history_fixtures.dart';

void main() {
  late CalculatorViewModel viewModel;
  late MockHistoryRepository mockHistoryRepository;

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(expression: '', result: '', createdAt: DateTime(2026)),
    );
  });

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();
    viewModel = CalculatorViewModel(historyRepository: mockHistoryRepository);
  });

  group('CalculatorViewModel', () {
    group('initial state', () {
      test('should have empty display value showing 0.00', () {
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should have empty expression', () {
        expect(viewModel.expression, '');
      });

      test('should have no preview result', () {
        expect(viewModel.previewResult, isNull);
      });

      test('should have empty timeline', () {
        expect(viewModel.timelineEntries, isEmpty);
      });

      test('should have no current operator', () {
        expect(viewModel.currentOperator, isNull);
      });
    });

    group('inputDigit', () {
      test('should update display when pressing digits', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');

        expect(viewModel.currentDisplayValue, '12.50');
      });

      test('should notify listeners when digit is pressed', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.inputDigit('1');

        expect(notified, true);
      });
    });

    group('inputDoubleZero', () {
      test('should insert double zero', () {
        viewModel.inputDigit('5');
        viewModel.inputDoubleZero();

        expect(viewModel.currentDisplayValue, '5.00');
      });
    });

    group('inputTripleZero', () {
      test('should insert triple zero', () {
        viewModel.inputDigit('1');
        viewModel.inputTripleZero();

        expect(viewModel.currentDisplayValue, '10.00');
      });
    });

    group('setOperator', () {
      test('should set current operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.currentOperator, '+');
      });

      test('should build expression with first number and operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.expression, '12.50 +');
      });

      test('should allow entering second number after operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.currentDisplayValue, '3.00');
        expect(viewModel.expression, '12.50 +');
      });

      test('should show preview result when second number is entered', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.previewResult, '15.50');
      });

      test('should allow chaining operations', () {
        // 12.50 + 3.00 = 15.50, then × ...
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');

        // Expression should contain the accumulated computation
        expect(viewModel.expression, contains('×'));
      });

      test(
        'should replace operator when pressing another operator without entering digits',
        () {
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.setOperator('−');

          expect(viewModel.currentOperator, '−');
          expect(viewModel.expression, '12.50 −');
        },
      );

      test('should notify listeners when operator is set', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.setOperator('+');

        expect(notified, true);
      });
    });

    group('percentage', () {
      test('should apply percentage after operator', () {
        // 100 + 10% = 110
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        expect(viewModel.previewResult, '110.00');
      });
    });

    group('equals', () {
      test('should evaluate expression and add to timeline', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries, isNotEmpty);
      });

      test('should reset for new calculation after equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.currentOperator, isNull);
      });

      test('should set result as current display after equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.currentDisplayValue, '15.50');
      });

      test('should persist result to history repository', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        verify(() => mockHistoryRepository.add(any())).called(1);
      });

      test('should do nothing when only first number is entered', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.equals();

        expect(viewModel.timelineEntries, isEmpty);
        verifyNever(() => mockHistoryRepository.add(any()));
      });

      test('should notify listeners after equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');

        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.equals();

        expect(notified, true);
      });
    });

    group('clear', () {
      test('should reset display to 0.00', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.clear();

        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should clear expression', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.clear();

        expect(viewModel.expression, '');
      });

      test('should clear current operator', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.clear();

        expect(viewModel.currentOperator, isNull);
      });

      test('should clear preview result', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.clear();

        expect(viewModel.previewResult, isNull);
      });

      test('should not clear timeline', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.equals();
        viewModel.clear();

        expect(viewModel.timelineEntries, isNotEmpty);
      });

      test('should notify listeners on clear', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.clear();

        expect(notified, true);
      });
    });

    group('backspace', () {
      test('should remove last digit from current input', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.backspace();

        expect(viewModel.currentDisplayValue, '0.12');
      });

      test(
        'should update preview when deleting digits from second operand',
        () {
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.inputDigit('3');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.backspace();

          // 100.00 + 0.30 preview
          expect(viewModel.previewResult, isNotNull);
        },
      );

      test('should notify listeners on backspace', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.backspace();

        expect(notified, true);
      });
    });

    group('timeline', () {
      test('should add entry to timeline after each equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // First calculation
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries.length, 1);
      });

      test('should accumulate timeline entries across calculations', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // First calculation
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.equals();

        // Second calculation
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.equals();

        expect(viewModel.timelineEntries.length, 2);
      });

      test('should have expression and result in timeline entry', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        final entry = viewModel.timelineEntries.first;
        expect(entry.expression, contains('+'));
        expect(entry.result, isNotEmpty);
      });

      test('should limit visible timeline entries', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // Perform many calculations to exceed visible limit
        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.equals();
        }

        expect(
          viewModel.visibleTimelineEntries.length,
          lessThanOrEqualTo(viewModel.maxVisibleEntries),
        );
      });

      test('should have more entries available beyond visible', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.equals();
        }

        expect(viewModel.hasMoreTimelineEntries, true);
      });

      test('should load more timeline entries', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.equals();
        }

        final initialVisible = viewModel.visibleTimelineEntries.length;
        viewModel.loadMoreTimelineEntries();

        expect(
          viewModel.visibleTimelineEntries.length,
          greaterThan(initialVisible),
        );
      });
    });

    group('loadSession', () {
      test('should load history entries into timeline', () {
        final entries = [HistoryFixtures.entry1, HistoryFixtures.entry2];
        viewModel.loadSession(entries);

        expect(viewModel.timelineEntries.length, 2);
      });

      test('should set result as current display value', () {
        viewModel.loadSession([HistoryFixtures.entry1]);

        expect(viewModel.currentDisplayValue, '15.50');
      });

      test('should clear current expression when loading session', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.loadSession([HistoryFixtures.entry1]);

        expect(viewModel.expression, '');
        expect(viewModel.currentOperator, isNull);
      });

      test('should notify listeners when session is loaded', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.loadSession([HistoryFixtures.entry1]);

        expect(notified, true);
      });
    });

    group('dispose', () {
      test('should dispose without errors', () {
        expect(() => viewModel.dispose(), returnsNormally);
      });
    });
  });
}
