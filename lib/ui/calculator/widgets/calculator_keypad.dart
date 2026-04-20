import 'package:flutter/material.dart';

import 'package:wevacalc/config/theme/app_layout.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_button.dart';

class CalculatorKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onPercent;
  final VoidCallback onDoubleZero;
  final VoidCallback onTripleZero;

  const CalculatorKeypad({
    super.key,
    required this.onDigit,
    required this.onOperator,
    required this.onEquals,
    required this.onClear,
    required this.onBackspace,
    required this.onPercent,
    required this.onDoubleZero,
    required this.onTripleZero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppLayout.padding.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([
            _action('C', onClear),
            _action('%', onPercent),
            _actionIcon(Icons.backspace_rounded, onBackspace),
            _operator('÷'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('7'),
            _numeric('8'),
            _numeric('9'),
            _operator('×'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('4'),
            _numeric('5'),
            _numeric('6'),
            _operator('−'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('1'),
            _numeric('2'),
            _numeric('3'),
            _operator('+'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('000', onPressed: onTripleZero),
            _numeric('00', onPressed: onDoubleZero),
            _numeric('0'),
            _equals(),
          ]),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Widget _numeric(String label, {VoidCallback? onPressed}) {
    return CalculatorButton(
      label: label,
      variant: ButtonVariant.numeric,
      onPressed: onPressed ?? () => onDigit(label),
    );
  }

  Widget _operator(String symbol) {
    return CalculatorButton(
      label: symbol,
      variant: ButtonVariant.functional,
      onPressed: () => onOperator(symbol),
    );
  }

  Widget _action(String label, VoidCallback onPressed) {
    return CalculatorButton(
      label: label,
      variant: ButtonVariant.functional,
      onPressed: onPressed,
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onPressed) {
    return CalculatorButton(
      label: 'backspace',
      icon: icon,
      variant: ButtonVariant.functional,
      onPressed: onPressed,
    );
  }

  Widget _equals() {
    return CalculatorButton(
      label: '=',
      variant: ButtonVariant.functional,
      onPressed: onEquals,
    );
  }
}
