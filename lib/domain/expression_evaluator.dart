class ExpressionEvaluator {
  static const _divisionByZeroError = 'Error';

  String? evaluate(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    final tokens = _tokenize(trimmed);
    if (tokens == null || tokens.isEmpty) return null;

    final resolved = _resolvePercentages(tokens);
    if (resolved == null) return null;

    final result = _evaluateTokens(resolved);
    if (result == null) return null;

    return _formatResult(result);
  }

  List<String>? _tokenize(String expression) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (char == ' ') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }

        continue;
      }

      if (_isOperator(char)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      } else if (char == '%') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add('%');
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    // Remove trailing operator
    while (tokens.isNotEmpty && _isOperator(tokens.last)) {
      tokens.removeLast();
    }

    if (tokens.isEmpty) return null;

    // Validate: must start with a number
    if (_isOperator(tokens.first) || tokens.first == '%') return null;

    return tokens;
  }

  bool _isOperator(String token) {
    return token == '+' || token == '−' || token == '×' || token == '÷';
  }

  List<String>? _resolvePercentages(List<String> tokens) {
    final result = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i] == '%') {
        if (result.isEmpty) return null;

        final percentValue = double.tryParse(result.removeLast());
        if (percentValue == null) return null;

        // Find the base value (the number before the operator)
        String? operator;
        double? baseValue;

        for (var j = result.length - 1; j >= 0; j--) {
          if (_isOperator(result[j])) {
            operator = result[j];
            if (j > 0) {
              baseValue = double.tryParse(result[j - 1]);
            }

            break;
          }
        }

        if (operator != null && baseValue != null) {
          if (operator == '+' || operator == '−') {
            // percentage of base: 100 + 10% means 100 + (100 * 10/100)
            final percentAmount = baseValue * percentValue / 100.0;
            result.add(_formatResult(percentAmount));
          } else {
            // For × and ÷, just convert to fraction
            result.add(_formatResult(percentValue / 100.0));
          }
        } else {
          // No context — just convert to fraction
          result.add(_formatResult(percentValue / 100.0));
        }
      } else {
        result.add(tokens[i]);
      }
    }

    return result;
  }

  double? _evaluateTokens(List<String> tokens) {
    if (tokens.isEmpty) return null;

    // Parse into numbers and operators lists
    final numbers = <double>[];
    final operators = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      if (i.isEven) {
        final num = double.tryParse(tokens[i]);
        if (num == null) return null;
        numbers.add(num);
      } else {
        if (!_isOperator(tokens[i])) return null;
        operators.add(tokens[i]);
      }
    }

    if (numbers.isEmpty) return null;

    // First pass: handle × and ÷ (higher precedence)
    var i = 0;
    while (i < operators.length) {
      if (operators[i] == '×' || operators[i] == '÷') {
        final left = numbers[i];
        final right = numbers[i + 1];
        double result;

        if (operators[i] == '×') {
          result = left * right;
        } else {
          if (right == 0) return double.infinity;
          result = left / right;
        }

        numbers[i] = result;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else {
        i++;
      }
    }

    // Second pass: handle + and − (lower precedence)
    var result = numbers[0];
    for (i = 0; i < operators.length; i++) {
      if (operators[i] == '+') {
        result += numbers[i + 1];
      } else if (operators[i] == '−') {
        result -= numbers[i + 1];
      }
    }

    return result;
  }

  String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) return _divisionByZeroError;

    return value.toStringAsFixed(2);
  }
}
