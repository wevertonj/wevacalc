import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/domain/enums/decimal_separator.dart';
import 'package:wevacalc/ui/calculator/calculator_page.dart';
import 'package:wevacalc/ui/calculator/calculator_view_model.dart';
import 'package:wevacalc/ui/calculator/widgets/animated_input_display.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_keypad.dart';
import 'package:wevacalc/ui/calculator/widgets/timeline_display.dart';

import '../../helpers/pump_app.dart';
import '../../mocks/mock_history_repository.dart';
import '../../mocks/mock_settings_repository.dart';

void main() {
  late MockHistoryRepository mockHistoryRepository;
  late MockSettingsRepository mockSettingsRepository;
  late CalculatorViewModel viewModel;

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(expression: '', result: '', createdAt: DateTime.now()),
    );
    registerFallbackValue(DecimalSeparator.dot);
  });

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();
    mockSettingsRepository = MockSettingsRepository();
    when(() => mockHistoryRepository.add(any())).thenAnswer(
      (_) async => HistoryEntry(
        id: 1,
        expression: '',
        result: '',
        createdAt: DateTime.now(),
      ),
    );
    when(
      () => mockSettingsRepository.getDecimalSeparator(),
    ).thenAnswer((_) async => DecimalSeparator.dot);
    viewModel = CalculatorViewModel(
      historyRepository: mockHistoryRepository,
      settingsRepository: mockSettingsRepository,
    );
  });

  group('CalculatorPage', () {
    /// Helper to get the current display text from AnimatedInputDisplay
    String getDisplayText(WidgetTester tester) {
      final display = tester.widget<AnimatedInputDisplay>(
        find.byType(AnimatedInputDisplay),
      );

      return display.text;
    }

    group('rendering', () {
      testWidgets('should display timeline and keypad', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(find.byType(TimelineDisplay), findsOneWidget);
        expect(find.byType(CalculatorKeypad), findsOneWidget);
      });

      testWidgets('should display initial value 0.00', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(getDisplayText(tester), equals('0.00'));
      });

      testWidgets('should display history and settings icons', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(find.byIcon(Icons.history_rounded), findsOneWidget);
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      });
    });

    group('integration', () {
      testWidgets('should update display when digit is tapped', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('12.50'));
      });

      testWidgets('should update display when operator is tapped', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        // Input 1250 → 12.50
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        // Tap operator +
        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('12.50 +'));
      });

      testWidgets('should calculate and show result after equals', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        // Input 10.00 + 5.00 =
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('='));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('15.00'));
      });

      testWidgets('should clear display when C is tapped', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('0.00'));
      });

      testWidgets('should backspace correctly', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        // Input 1250 → 12.50
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('12.50'));

        // Backspace → 1.25
        await tester.tap(find.byIcon(Icons.backspace_rounded));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('1.25'));
      });
    });
  });
}
