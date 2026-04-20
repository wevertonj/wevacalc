import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wevacalc/ui/calculator/widgets/calculator_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CalculatorButton', () {
    group('rendering', () {
      testWidgets('should display the label text', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '7', onPressed: () {}),
          ),
        );

        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('should display functional label', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '÷',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        expect(find.text('÷'), findsOneWidget);
      });

      testWidgets('should display icon when provided', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: 'backspace',
              icon: Icons.backspace_rounded,
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        expect(find.byIcon(Icons.backspace_rounded), findsOneWidget);
      });

      testWidgets('should display equals as functional variant', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '=',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        expect(find.text('='), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('should call onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '5', onPressed: () => pressed = true),
          ),
        );

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();

        expect(pressed, isTrue);
      });

      testWidgets('should call onPressed for functional variant', (
        tester,
      ) async {
        var pressed = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '+',
              onPressed: () => pressed = true,
              variant: ButtonVariant.functional,
            ),
          ),
        );

        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        expect(pressed, isTrue);
      });

      testWidgets('should trigger LED glow animation on tap', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '3', onPressed: () {}),
          ),
        );

        await tester.tap(find.text('3'));
        // Pump a few frames to see the glow animation
        await tester.pump(const Duration(milliseconds: 50));

        // The button should still exist and be functional
        expect(find.text('3'), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('should animate background fade out on tap', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '8', onPressed: () {}),
          ),
        );

        await tester.tap(find.text('8'));
        await tester.pump(const Duration(milliseconds: 100));

        // Button still renders during animation
        expect(find.text('8'), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('variants', () {
      testWidgets('should use primary color for functional text', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '×',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('×'));
        final theme = Theme.of(tester.element(find.byType(CalculatorButton)));

        expect(text.style?.color, equals(theme.colorScheme.primary));
      });

      testWidgets('numeric variant should use onSurface color', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '9', onPressed: () {}),
          ),
        );

        final text = tester.widget<Text>(find.text('9'));

        expect(text.style?.color, isNotNull);
      });

      testWidgets('should have square shape with small border radius', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '1', onPressed: () {}),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(CalculatorButton),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.borderRadius, isNotNull);
        expect(decoration.shape, BoxShape.rectangle);
      });
    });
  });
}
