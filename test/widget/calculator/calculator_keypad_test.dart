import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wevacalc/ui/calculator/widgets/calculator_button.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_keypad.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CalculatorKeypad', () {
    group('rendering', () {
      testWidgets('should display all numeric buttons', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        for (final digit in [
          '0',
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
          '9',
        ]) {
          expect(
            find.text(digit),
            findsOneWidget,
            reason: 'Missing digit $digit',
          );
        }
      });

      testWidgets('should display all operator buttons', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        expect(find.text('÷'), findsOneWidget);
        expect(find.text('×'), findsOneWidget);
        expect(find.text('−'), findsOneWidget);
        expect(find.text('+'), findsOneWidget);
      });

      testWidgets('should display action buttons', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        expect(find.text('C'), findsOneWidget);
        expect(find.text('%'), findsOneWidget);
        expect(find.text('='), findsOneWidget);
        expect(find.byIcon(Icons.backspace_rounded), findsOneWidget);
      });

      testWidgets('should display double zero and triple zero buttons', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        expect(find.text('00'), findsOneWidget);
        expect(find.text('000'), findsOneWidget);
      });

      testWidgets('should have exactly 20 CalculatorButton widgets', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        expect(find.byType(CalculatorButton), findsNWidgets(20));
      });
    });

    group('interaction', () {
      testWidgets('should call onDigit with correct digit', (tester) async {
        String? tappedDigit;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (d) => tappedDigit = d,
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.text('7'));
        await tester.pumpAndSettle();

        expect(tappedDigit, '7');
      });

      testWidgets('should call onOperator with correct operator', (
        tester,
      ) async {
        String? tappedOperator;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (op) => tappedOperator = op,
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        expect(tappedOperator, '+');
      });

      testWidgets('should call onEquals when = tapped', (tester) async {
        var equalsCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () => equalsCalled = true,
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.text('='));
        await tester.pumpAndSettle();

        expect(equalsCalled, isTrue);
      });

      testWidgets('should call onClear when C tapped', (tester) async {
        var clearCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () => clearCalled = true,
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();

        expect(clearCalled, isTrue);
      });

      testWidgets('should call onBackspace when backspace tapped', (
        tester,
      ) async {
        var backspaceCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () => backspaceCalled = true,
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.backspace_rounded));
        await tester.pumpAndSettle();

        expect(backspaceCalled, isTrue);
      });

      testWidgets('should call onPercent when % tapped', (tester) async {
        var percentCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () => percentCalled = true,
              onDoubleZero: () {},
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.text('%'));
        await tester.pumpAndSettle();

        expect(percentCalled, isTrue);
      });

      testWidgets('should call onDoubleZero when 00 tapped', (tester) async {
        var doubleZeroCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () => doubleZeroCalled = true,
              onTripleZero: () {},
            ),
          ),
        );

        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();

        expect(doubleZeroCalled, isTrue);
      });

      testWidgets('should call onTripleZero when 000 tapped', (tester) async {
        var tripleZeroCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorKeypad(
              onDigit: (_) {},
              onOperator: (_) {},
              onEquals: () {},
              onClear: () {},
              onBackspace: () {},
              onPercent: () {},
              onDoubleZero: () {},
              onTripleZero: () => tripleZeroCalled = true,
            ),
          ),
        );

        await tester.tap(find.text('000'));
        await tester.pumpAndSettle();

        expect(tripleZeroCalled, isTrue);
      });
    });
  });
}
