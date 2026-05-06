import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/domain/entities/history_line.dart';
import 'package:wevacalc/domain/entities/history_selection.dart';
import 'package:wevacalc/domain/enums/decimal_separator.dart';
import 'package:wevacalc/ui/calculator/calculator_view_model.dart';

import '../../../mocks/mock_clipboard_service.dart';
import '../../../mocks/mock_history_repository.dart';
import '../../../mocks/mock_settings_repository.dart';
import '../../../fixtures/history_fixtures.dart';

void main() {
  late CalculatorViewModel viewModel;
  late MockHistoryRepository mockHistoryRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockClipboardService mockClipboardService;

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(DecimalSeparator.dot);
  });

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockClipboardService = MockClipboardService();
    when(
      () => mockSettingsRepository.getDecimalSeparator(),
    ).thenAnswer((_) async => DecimalSeparator.dot);
    when(() => mockHistoryRepository.add(any())).thenAnswer(
      (_) async => HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime(2026),
      ),
    );
    when(() => mockHistoryRepository.update(any())).thenAnswer((_) async {});
    when(() => mockClipboardService.copyText(any())).thenAnswer((_) async {});
    when(() => mockClipboardService.readText()).thenAnswer((_) async => null);
    viewModel = CalculatorViewModel(
      historyRepository: mockHistoryRepository,
      settingsRepository: mockSettingsRepository,
      clipboardService: mockClipboardService,
    );
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

      test('should not show preview when operator just pressed', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');

        // "2.45 +" has no valid second operand
        expect(viewModel.previewResult, isNull);
      });

      test('should not show preview after chained operator without value', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('−');

        // "2.45 + 3.00 −" has no valid last operand
        expect(viewModel.previewResult, isNull);
      });

      test('should show preview for chained expression with all operands', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('−');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        // "2.45 + 3.00 − 1.00" = 4.45
        expect(viewModel.previewResult, '4.45');
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

      test('should preserve full expression when chaining operations', () {
        // Type: 2.42 + 0.03 + 0.08 + 0.11
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('2');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.setOperator('+');
        viewModel.inputDigit('8');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('1');

        // Should show full expression, NOT compacted
        expect(viewModel.fullDisplayText, '2.42 + 0.03 + 0.08 + 0.11');
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

    group('fullDisplayText', () {
      test('should return current value when no expression', () {
        expect(viewModel.fullDisplayText, '0.00');
      });

      test('should return expression when operator just pressed', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.fullDisplayText, '12.50 +');
      });

      test(
        'should return full inline expression when typing second number',
        () {
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('5');
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');

          expect(viewModel.fullDisplayText, '12.50 × 52.00');
        },
      );

      test('should return result after equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.fullDisplayText, '15.00');
      });
    });

    group('percentage', () {
      test(
        'should display literal % in expression for addition without changing current value',
        () {
          // 100.00 + 10% → display shows 100.00 + 10.00%, value remains 10.00
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

          expect(viewModel.currentDisplayValue, '10.00');
          expect(viewModel.fullDisplayText, '100.00 + 10.00%');
          expect(viewModel.previewResult, '110.00');
        },
      );

      test(
        'should display literal % in expression for multiplication without changing current value',
        () {
          // 200.00 × 50% → display shows 200.00 × 50.00%, value remains 50.00
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.applyPercentage();

          expect(viewModel.currentDisplayValue, '50.00');
          expect(viewModel.fullDisplayText, '200.00 × 50.00%');
          expect(viewModel.previewResult, '100.00');
        },
      );

      test('should display literal % for subtraction', () {
        // 200.00 − 25% = 150.00
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('−');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        expect(viewModel.fullDisplayText, '200.00 − 25.00%');
        expect(viewModel.previewResult, '150.00');
      });

      test('should display literal % for division', () {
        // 200.00 ÷ 10% = 2000.00
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('÷');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        expect(viewModel.fullDisplayText, '200.00 ÷ 10.00%');
        expect(viewModel.previewResult, '2,000.00');
      });

      test('should not apply percentage without operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        // Should remain unchanged
        expect(viewModel.currentDisplayValue, '10.00');
        expect(viewModel.fullDisplayText, '10.00');
      });

      test(
        'should preserve % literal in timeline entry expression after equals',
        () {
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) async => HistoryFixtures.entry1);

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
          viewModel.equals();

          expect(viewModel.timelineEntries, hasLength(1));
          expect(viewModel.timelineEntries.first.expression, '100.00 + 10.00%');
          expect(viewModel.timelineEntries.first.result, '110.00');
        },
      );

      test('should persist literal % expression to history repository', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

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
        viewModel.equals();
        viewModel.clear();

        final captured = verify(
          () => mockHistoryRepository.add(captureAny()),
        ).captured;
        final entry = captured.single as HistoryEntry;
        expect(entry.lines.first.expression, contains('%'));
      });

      test('should preserve % literal when chaining with another operator', () {
        // 100 + 10% + 5 → expression should keep "100.00 + 10.00% +"
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
        viewModel.setOperator('+');

        expect(viewModel.expression, '100.00 + 10.00% +');
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

      test('should persist session to history repository on clear', () {
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
        viewModel.clear();

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

      test('should clear session timeline', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.equals();
        viewModel.clear();

        expect(viewModel.timelineEntries, isEmpty);
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

      test('should remove a closing parenthesis without resetting engine', () {
        viewModel.inputParenthesis(); // (
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis(); // ) → committed: ( 12.50 + 3.00 )

        expect(viewModel.fullDisplayText, '( 12.50 + 3.00 )');
        expect(viewModel.openParenCount, 0);

        viewModel.backspace();

        expect(viewModel.fullDisplayText, '( 12.50 + 3.00');
        expect(viewModel.openParenCount, 1);
      });

      test(
        'should remove an opening parenthesis when it is the last token',
        () {
          viewModel.inputParenthesis(); // (

          expect(viewModel.openParenCount, 1);

          viewModel.backspace();

          expect(viewModel.openParenCount, 0);
          expect(viewModel.hasContent, false);
        },
      );

      test('should remove an opening parenthesis preceded by an operator '
          'and restore the previous operand for editing', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputParenthesis(); // (

        expect(viewModel.fullDisplayText, '10.00 + (');

        viewModel.backspace(); // remove (

        expect(viewModel.fullDisplayText, '10.00 +');

        viewModel.backspace(); // remove +

        expect(viewModel.fullDisplayText, '10.00');
        expect(viewModel.currentOperator, isNull);
      });

      test('should not replace opening parenthesis with 0.00 when backspacing '
          'a complex expression', () {
        // 4.25 + (36.00 × 2.00) + 3.65
        viewModel.inputDigit('4');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputParenthesis();

        viewModel.inputDigit('3');
        viewModel.inputDigit('6');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');

        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.setOperator('+');

        viewModel.inputDigit('3');
        viewModel.inputDigit('6');
        viewModel.inputDigit('5');

        // Remove 3.65
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();

        // Remove trailing + and then )
        viewModel.backspace();
        viewModel.backspace();

        // Remove 2.00 and operator ×
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();

        // Remove 36.00
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();

        expect(viewModel.fullDisplayText, '4.25 + (');

        viewModel.backspace();

        expect(viewModel.fullDisplayText, '4.25 +');
      });

      test('should remove pending operator after closed parenthesis without '
          'adding ghost 0.00', () {
        // (10.00 × 50.00) +
        viewModel.inputParenthesis();
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.setOperator('+');

        expect(viewModel.fullDisplayText, '( 10.00 × 50.00 ) +');

        viewModel.backspace();

        expect(viewModel.currentOperator, isNull);
        expect(viewModel.fullDisplayText, '( 10.00 × 50.00 )');
      });

      test('should keep closing parenthesis when deleting a trailing operator '
          'in a nested expression', () {
        // (2.50 + 2.56) × 3.00 +
        viewModel.inputParenthesis();
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('6');
        viewModel.inputParenthesis();
        viewModel.setOperator('×');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.fullDisplayText, '( 2.50 + 2.56 ) × 3.00 +');

        viewModel.backspace();

        expect(viewModel.fullDisplayText, '( 2.50 + 2.56 ) × 3.00');
        expect(viewModel.currentOperator, isNull);
      });

      test(
        'should remove only one closing paren at a time in nested close-close sequence',
        () {
          // (10.00 × 50.00) + 30.00 + (48.00 ÷ (18.00 × 1.50%)) +
          viewModel.inputParenthesis();
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputParenthesis();
          viewModel.setOperator('+');

          viewModel.inputDigit('3');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');

          viewModel.inputParenthesis();
          viewModel.inputDigit('4');
          viewModel.inputDigit('8');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('÷');

          viewModel.inputParenthesis();
          viewModel.inputDigit('1');
          viewModel.inputDigit('8');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('1');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.applyPercentage();
          viewModel.inputParenthesis();
          viewModel.inputParenthesis();
          viewModel.setOperator('+');

          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% ) ) +',
          );

          viewModel.backspace(); // remove trailing +
          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% ) )',
          );

          viewModel.backspace(); // remove only the last )
          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% )',
          );
          expect(viewModel.fullDisplayText.contains('% 0.00'), isFalse);
          expect(viewModel.openParenCount, 1);
        },
      );

      test(
        'should backspace into the inner expression after removing close paren',
        () {
          viewModel.inputParenthesis(); // (
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.inputParenthesis(); // ) → ( 12.50 )

          viewModel.backspace(); // remove )
          viewModel.backspace(); // remove last digit of 12.50

          expect(viewModel.fullDisplayText, '( 1.25');
        },
      );

      test('should not leave a dangling operator with 0.00 when engine empties '
          'after restoring an operand from a closed parenthesis', () {
        viewModel.inputParenthesis(); // (
        viewModel.inputDigit('3');
        viewModel.inputDigit('2');
        viewModel.inputDigit('6');
        viewModel.setOperator('−');
        viewModel.inputDigit('0');
        viewModel.inputDigit('4');
        viewModel.inputParenthesis(); // ) → ( 3.26 − 0.04 )

        viewModel.backspace(); // remove )
        viewModel.backspace(); // 0.04 → 0.00 (empty)

        // Display must not include a trailing 0.00 ghost value.
        expect(viewModel.fullDisplayText, '( 3.26 −');
        expect(viewModel.currentOperator, '−');
      });

      test('should promote dangling operator back to pending when deleting '
          'all digits of the right-hand operand', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.setOperator('−'); // commits '+' and '0.05', pending = '−'
        viewModel.inputDigit('2');
        // committed: [1.00, +, 0.05], pendingOp: −, engine: 0.02
        viewModel.backspace(); // 0.02 → 0.00 (empty)

        // After clearing the active operand, we should still display the
        // pending operator without an extra 0.00 token.
        expect(viewModel.fullDisplayText, '1.00 + 0.05 −');
      });
    });

    group('clear with empty state', () {
      test('should be a no-op when there is nothing to clear', () {
        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.clear();

        expect(notified, false);
        expect(viewModel.hasContent, false);
        expect(viewModel.currentDisplayValue, '0.00');
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
        final entry = HistoryFixtures.entry1;
        viewModel.loadSession(HistorySelection(entry: entry, lineIndex: 0));

        expect(viewModel.timelineEntries.length, 1);
      });

      test('should set result as current display value', () {
        viewModel.loadSession(
          HistorySelection(entry: HistoryFixtures.entry1, lineIndex: 0),
        );

        expect(viewModel.currentDisplayValue, '15.50');
      });

      test('should clear current expression when loading session', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.loadSession(
          HistorySelection(entry: HistoryFixtures.entry1, lineIndex: 0),
        );

        expect(viewModel.expression, '');
        expect(viewModel.currentOperator, isNull);
      });

      test('should notify listeners when session is loaded', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.loadSession(
          HistorySelection(entry: HistoryFixtures.entry1, lineIndex: 0),
        );

        expect(notified, true);
      });
    });

    group('dispose', () {
      test('should dispose without errors', () {
        expect(() => viewModel.dispose(), returnsNormally);
      });
    });

    group('thousands separator formatting', () {
      test('should format display with dot separator and thousands', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // Input 1250000 cents = 12,500.00
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.fullDisplayText, '12,500.00');
      });

      test('should format display with comma separator and thousands', () {
        viewModel.decimalSeparator = DecimalSeparator.comma;

        // Input 1250000 cents = 12.500,00
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.fullDisplayText, '12.500,00');
      });

      test('should format expression parts with thousands separator', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 12500.00 +
        for (final d in ['1', '2', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');

        expect(viewModel.expression, '12,500.00 +');
      });

      test('should format full expression with thousands separator', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 12500.00 + 3500.00
        for (final d in ['1', '2', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['3', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }

        expect(viewModel.fullDisplayText, '12,500.00 + 3,500.00');
      });

      test('should evaluate correctly despite display formatting', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 12500.00 + 3500.00 = 16000.00
        for (final d in ['1', '2', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['3', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }

        when(() => mockHistoryRepository.add(any())).thenAnswer(
          (_) async => HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '', result: '')],
            result: '',
            createdAt: DateTime.now(),
          ),
        );
        viewModel.equals();

        expect(viewModel.fullDisplayText, '16,000.00');
      });

      test('should not add thousands separator for small values', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');

        expect(viewModel.fullDisplayText, '1.25');
      });

      test('should format preview result with thousands separator', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 99999.00 + 1.00 => preview 100,000.00... wait, preview uses evaluator
        // Let's use something simpler: 50000.00 + 50000.00
        for (final d in ['5', '0', '0', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['5', '0', '0', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }

        expect(viewModel.previewResult, '100,000.00');
      });
    });

    group('action queue', () {
      test('should process 50 rapid actions without dropping any', () {
        // Arrange — count notifications to verify all actions were processed.
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        // Act — fire 50 actions in burst (digit/operator alternated to avoid
        // Add2Engine integer overflow with a single huge number).
        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
        }

        // Assert — every action triggered a notification (no drops).
        expect(notifications, 50);
      });

      test('should preserve order across mixed actions in burst', () {
        // Arrange
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // Act — simulate user typing "12 + 34 ="
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('4');
        viewModel.equals();

        // Assert — final result must reflect the ordered processing
        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.expression, '0.12 + 0.34');
        expect(viewModel.timelineEntries.first.result, '0.46');
      });

      test(
        'should enqueue actions triggered during processing (reentrancy)',
        () {
          // Arrange — listener that re-dispatches an action while the current
          // one is still being processed (synchronous notifyListeners).
          var fired = false;
          viewModel.addListener(() {
            if (!fired) {
              fired = true;
              viewModel.inputDigit('9');
            }
          });

          // Act
          viewModel.inputDigit('5');

          // Assert — both digits processed in order: '5' then '9'
          expect(viewModel.currentDisplayValue, '0.59');
        },
      );

      test(
        'should not drop actions when 50 operators+digits fire in burst',
        () {
          // Arrange
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) async => HistoryFixtures.entry1);

          // Act — 1 + 1 + 1 + ... 25 times => result should be 0.25
          for (var i = 0; i < 25; i++) {
            viewModel.inputDigit('1');
            if (i < 24) viewModel.setOperator('+');
          }
          viewModel.equals();

          // Assert — exactly one timeline entry; sum is 25 * 0.01 = 0.25
          expect(viewModel.timelineEntries, hasLength(1));
          expect(viewModel.timelineEntries.first.result, '0.25');
        },
      );
    });

    group('hasContent', () {
      test('should be false in initial state', () {
        expect(viewModel.hasContent, isFalse);
      });

      test('should be true when a digit is entered', () {
        viewModel.inputDigit('5');

        expect(viewModel.hasContent, isTrue);
      });

      test('should be true when operator is pressed after a value', () {
        viewModel.inputDigit('5');
        viewModel.setOperator('+');

        expect(viewModel.hasContent, isTrue);
      });

      test('should be false after clear', () {
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.clear();

        expect(viewModel.hasContent, isFalse);
      });

      test('should be true after equals (timeline has entries)', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.equals();

        expect(viewModel.hasContent, isTrue);
      });

      test('should be true after opening a parenthesis', () {
        viewModel.inputParenthesis();

        expect(viewModel.hasContent, isTrue);
      });

      test('should notify listeners when content state changes', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.inputDigit('1');

        expect(notified, isTrue);
        expect(viewModel.hasContent, isTrue);
      });
    });

    group('parentheses', () {
      test('should have openParenCount 0 initially', () {
        expect(viewModel.openParenCount, 0);
      });

      test('should open parenthesis at start of expression', () {
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 1);
        expect(viewModel.expression, '(');
      });

      test('should accept digits inside parentheses', () {
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.currentDisplayValue, '5.00');
        expect(viewModel.fullDisplayText, '( 5.00');
      });

      test('should close parenthesis when balanced and last is value', () {
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 0);
        expect(viewModel.expression, '( 5.00 + 3.00 )');
      });

      test('should evaluate parenthesized expression on equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // (5.00 + 3.00) × 2.00 = 16.00
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.result, '16.00');
      });

      test('should support nested parentheses', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // (10.00 × (2.00 + 3.00)) = 50.00
        viewModel.inputParenthesis();
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 2);

        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 0);
        viewModel.equals();

        expect(viewModel.timelineEntries.first.result, '50.00');
      });

      test('should auto-close unbalanced parentheses on equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // ( 5.00 + 3.00  → equals should auto-close → 8.00
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries.first.result, '8.00');
      });

      test('should open parenthesis after operator', () {
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 1);
        expect(viewModel.expression, '5.00 + (');
      });

      test('should not open parenthesis after a value (without operator)', () {
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();

        // Should be ignored — no implicit multiplication
        expect(viewModel.openParenCount, 0);
        expect(viewModel.expression, '');
      });

      test(
        'should support continuing operations after closing parenthesis',
        () {
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) async => HistoryFixtures.entry1);

          // (2.00 + 3.00) × 4.00 = 20.00
          viewModel.inputParenthesis();
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.inputDigit('3');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputParenthesis();
          viewModel.setOperator('×');
          viewModel.inputDigit('4');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.equals();

          expect(viewModel.timelineEntries.first.result, '20.00');
        },
      );

      test('should preserve open paren expression in fullDisplayText', () {
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputParenthesis();
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.fullDisplayText, '5.00 + ( 2.00');
      });

      test('should notify listeners when parenthesis is inserted', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.inputParenthesis();

        expect(notified, isTrue);
      });
    });

    group('clipboard — derived state', () {
      test('hasExpression should be false on initial state', () {
        expect(viewModel.hasExpression, isFalse);
      });

      test('hasExpression should be true after inputting digits', () {
        viewModel.inputDigit('5');

        expect(viewModel.hasExpression, isTrue);
      });

      test('hasResult should be false on initial state', () {
        expect(viewModel.hasResult, isFalse);
      });

      test('hasResult should be true when previewResult is available', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.previewResult, isNotNull);
        expect(viewModel.hasResult, isTrue);
      });

      test('hasResult should be true after equals', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.hasResult, isTrue);
      });

      test('hasHistory should be false on initial state', () {
        expect(viewModel.hasHistory, isFalse);
      });

      test('hasHistory should be true after a calculation is committed', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.hasHistory, isTrue);
      });
    });

    group('copyExpression', () {
      test('should copy current expression text to clipboard', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');

        await viewModel.copyExpression();

        verify(() => mockClipboardService.copyText('12.50')).called(1);
      });

      test('should copy expression including operator and operand', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        await viewModel.copyExpression();

        verify(() => mockClipboardService.copyText('10.00 + 10.00')).called(1);
      });
    });

    group('copyResult', () {
      test('should copy preview result when available', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        await viewModel.copyResult();

        verify(() => mockClipboardService.copyText('15.00')).called(1);
      });

      test('should copy current display value after equals', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        await viewModel.copyResult();

        verify(() => mockClipboardService.copyText('15.00')).called(1);
      });
    });

    group('copyHistory', () {
      test('should copy all timeline entries as text', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.equals();
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        await viewModel.copyHistory();

        final captured =
            verify(
                  () => mockClipboardService.copyText(captureAny()),
                ).captured.single
                as String;

        expect(captured, contains('1.00 + 0.50 = 1.50'));
        expect(captured, contains('2.00 × 2.00 = 4.00'));
      });
    });

    group('pasteFromClipboard', () {
      test('should paste integer at face value', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '1250');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.currentDisplayValue, '1,250.00');
      });

      test(
        'should paste decimal with dot separator preserving precision',
        () async {
          when(
            () => mockClipboardService.readText(),
          ).thenAnswer((_) async => '12.50');

          final ok = await viewModel.pasteFromClipboard();

          expect(ok, isTrue);
          expect(viewModel.currentDisplayValue, '12.50');
        },
      );

      test('should paste decimal with comma separator', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '12,50');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.currentDisplayValue, '12.50');
      });

      test('should paste full expression and evaluate previewResult', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '10 + 5');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.expression, equals('10.00 +'));
        expect(viewModel.currentDisplayValue, '5.00');
        expect(viewModel.previewResult, '15.00');
      });

      test('should return false when clipboard is empty', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => null);

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should return false for invalid input', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => 'not a number');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should replace existing content', () async {
        viewModel.inputDigit('9');
        viewModel.inputDigit('9');
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '1250');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.currentDisplayValue, '1,250.00');
      });
    });
  });
}
