import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:wevacalc/data/repositories/history_repository.dart';
import 'package:wevacalc/data/repositories/settings_repository.dart';
import 'package:wevacalc/domain/add2_engine.dart';
import 'package:wevacalc/domain/entities/calculation.dart';
import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/domain/enums/decimal_separator.dart';
import 'package:wevacalc/domain/expression_evaluator.dart';
import 'package:wevacalc/utils/formatters/number_formatter.dart';

class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel({
    required HistoryRepository historyRepository,
    required SettingsRepository settingsRepository,
  }) : _historyRepository = historyRepository,
       _settingsRepository = settingsRepository;

  final HistoryRepository _historyRepository;
  final SettingsRepository _settingsRepository;
  final Add2Engine _add2Engine = Add2Engine();
  final ExpressionEvaluator _evaluator = ExpressionEvaluator();

  final List<Calculation> _timelineEntries = [];
  final List<_ExpressionPart> _expressionParts = [];

  /// Fila de ações do usuário.
  ///
  /// Garante que toques disparados durante o processamento de outra ação
  /// (por exemplo, via `notifyListeners` que reentra na ViewModel) sejam
  /// processados em ordem, sem perda. Dart é single-threaded, então a fila
  /// serve apenas como proteção contra reentrância síncrona.
  final Queue<VoidCallback> _actionQueue = Queue<VoidCallback>();
  bool _isProcessingActions = false;

  String? _currentOperator;
  bool _isNewInput = true;
  bool _shouldResetOnInput = false;
  bool _currentIsPercentage = false;
  int _visibleCount = 20;
  DecimalSeparator _decimalSeparator = DecimalSeparator.dot;

  static const int _loadMoreCount = 20;

  int get maxVisibleEntries => _visibleCount;

  DecimalSeparator get decimalSeparator => _decimalSeparator;

  set decimalSeparator(DecimalSeparator value) {
    if (_decimalSeparator == value) return;
    _decimalSeparator = value;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    _decimalSeparator = await _settingsRepository.getDecimalSeparator();
    notifyListeners();
  }

  String get currentDisplayValue => _formatValue(_add2Engine.formattedValue);

  String? get currentOperator => _currentOperator;

  /// Full display text — the entire expression on a single line.
  /// e.g., "7856.00", "7856.00 ×", "7856.00 × 52.00", "100.00 + 10.00%"
  String get fullDisplayText {
    if (expression.isEmpty) {
      return currentDisplayValue;
    }

    if (_isNewInput) {
      return expression;
    }

    final percentSuffix = _currentIsPercentage ? '%' : '';

    return '$expression $currentDisplayValue$percentSuffix';
  }

  String get expression {
    if (_expressionParts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final part in _expressionParts) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(_formatPart(part.value));
    }

    if (_currentOperator != null) {
      buffer.write(' $_currentOperator');
    }

    return buffer.toString();
  }

  /// Formats a stored part value for display. Operators pass through.
  /// Numeric values are formatted; values ending with `%` keep the literal
  /// percentage suffix appended after the formatted number.
  String _formatPart(String value) {
    if (_isOperator(value)) return value;

    if (value.endsWith('%')) {
      final numeric = value.substring(0, value.length - 1);

      return '${_formatValue(numeric)}%';
    }

    return _formatValue(value);
  }

  String? get previewResult {
    if (_expressionParts.isEmpty || _currentOperator == null) return null;
    if (_isNewInput) return null;

    final fullExpression = _buildFullExpression();
    final rawResult = _evaluator.evaluate(fullExpression);
    if (rawResult == null) return null;

    return _formatValue(rawResult);
  }

  List<Calculation> get timelineEntries => List.unmodifiable(_timelineEntries);

  List<Calculation> get visibleTimelineEntries {
    if (_timelineEntries.length <= _visibleCount) {
      return List.unmodifiable(_timelineEntries);
    }

    final start = _timelineEntries.length - _visibleCount;

    return List.unmodifiable(_timelineEntries.sublist(start));
  }

  bool get hasMoreTimelineEntries => _timelineEntries.length > _visibleCount;

  /// Despacha uma ação do usuário. Se já houver outra ação em execução
  /// (cenário de reentrância síncrona via listener), enfileira para ser
  /// processada logo após a atual terminar, preservando a ordem dos toques.
  void _runAction(VoidCallback action) {
    if (_isProcessingActions) {
      _actionQueue.add(action);

      return;
    }

    _isProcessingActions = true;
    try {
      action();
      while (_actionQueue.isNotEmpty) {
        _actionQueue.removeFirst()();
      }
    } finally {
      _isProcessingActions = false;
    }
  }

  void inputDigit(String digit) {
    _runAction(() {
      _prepareForDigitInput();
      _add2Engine.inputDigit(digit);
      notifyListeners();
    });
  }

  void inputDoubleZero() {
    _runAction(() {
      _prepareForDigitInput();
      _add2Engine.inputDoubleZero();
      notifyListeners();
    });
  }

  void inputTripleZero() {
    _runAction(() {
      _prepareForDigitInput();
      _add2Engine.inputTripleZero();
      notifyListeners();
    });
  }

  void _prepareForDigitInput() {
    if (_currentIsPercentage) {
      // Typing a digit after applying % cancels the literal percentage marker
      // and starts a fresh value for the same operand position.
      _add2Engine.reset();
      _currentIsPercentage = false;

      return;
    }

    if (_shouldResetOnInput) {
      _add2Engine.reset();
      _shouldResetOnInput = false;
    } else if (_isNewInput && _currentOperator != null) {
      _add2Engine.reset();
      _isNewInput = false;
    }
  }

  void setOperator(String operator) {
    _runAction(() {
      _shouldResetOnInput = false;

      if (_currentOperator != null && !_isNewInput && !_add2Engine.isEmpty) {
        // Accumulate current value and operator into expression parts
        _expressionParts.add(_ExpressionPart(_currentOperator!));
        _expressionParts.add(_ExpressionPart(_currentValueAsPart()));
      } else if (_currentOperator != null && _isNewInput) {
        // Just replace the operator (no new digits entered)
      } else if (_expressionParts.isEmpty || (_currentOperator == null)) {
        // First operator — save current value
        _expressionParts.clear();
        _expressionParts.add(_ExpressionPart(_currentValueAsPart()));
      }

      _currentIsPercentage = false;
      _currentOperator = operator;
      _isNewInput = true;
      notifyListeners();
    });
  }

  /// Returns the current engine value with a `%` suffix appended
  /// when the percentage marker is active.
  String _currentValueAsPart() {
    final value = _add2Engine.formattedValue;

    return _currentIsPercentage ? '$value%' : value;
  }

  void applyPercentage() {
    _runAction(() {
      if (_currentOperator == null || _expressionParts.isEmpty) return;
      if (_isNewInput) return;
      if (_add2Engine.isEmpty) return;
      if (_currentIsPercentage) return;

      _currentIsPercentage = true;
      notifyListeners();
    });
  }

  void equals() {
    _runAction(() {
      if (_currentOperator == null || _expressionParts.isEmpty) return;
      if (_isNewInput && _add2Engine.isEmpty) return;

      final fullExpression = _buildFullExpression();
      final result = _evaluator.evaluate(fullExpression);

      if (result == null) return;

      final formattedExpression = _formatExpression(fullExpression);
      final formattedResult = _formatValue(result);

      final calculation = Calculation(
        expression: formattedExpression,
        result: formattedResult,
        timestamp: DateTime.now(),
      );

      _timelineEntries.add(calculation);

      // Persist to history (raw values for portability)
      _historyRepository.add(
        HistoryEntry(
          expression: fullExpression,
          result: result,
          createdAt: DateTime.now(),
        ),
      );

      // Set result as current value for potential chaining
      _expressionParts.clear();
      _currentOperator = null;
      _isNewInput = true;
      _shouldResetOnInput = true;
      _currentIsPercentage = false;
      _add2Engine.setValue(_parseToInt(result));

      notifyListeners();
    });
  }

  void clear() {
    _runAction(() {
      _add2Engine.reset();
      _expressionParts.clear();
      _currentOperator = null;
      _isNewInput = true;
      _shouldResetOnInput = false;
      _currentIsPercentage = false;
      _timelineEntries.clear();
      notifyListeners();
    });
  }

  void backspace() {
    _runAction(() {
      // If a literal % marker is active on the current value, drop it first.
      if (_currentIsPercentage) {
        _currentIsPercentage = false;
        notifyListeners();

        return;
      }

      // When a trailing operator is shown but no new digits entered yet,
      // remove the operator first (e.g., "3.00 + 5.00 +" → "3.00 + 5.00")
      if (_isNewInput && _currentOperator != null) {
        _currentOperator = null;
        _isNewInput = false;

        // Restore engine to the last value in expression parts
        if (_expressionParts.isNotEmpty) {
          final lastPart = _expressionParts.removeLast();
          _restoreEngineFromPart(lastPart.value);

          if (_expressionParts.isNotEmpty) {
            final operatorPart = _expressionParts.removeLast();
            _currentOperator = operatorPart.value;
          }
        }

        notifyListeners();

        return;
      }

      if (!_add2Engine.isEmpty) {
        _add2Engine.deleteLastDigit();
        notifyListeners();

        return;
      }

      // Engine is empty — backspace into the expression
      if (_currentOperator != null) {
        _currentOperator = null;
        _isNewInput = false;

        if (_expressionParts.isNotEmpty) {
          final lastPart = _expressionParts.removeLast();
          _restoreEngineFromPart(lastPart.value);

          if (_expressionParts.isNotEmpty) {
            final operatorPart = _expressionParts.removeLast();
            _currentOperator = operatorPart.value;
          }
        }

        notifyListeners();

        return;
      }

      // No operator, but expression parts exist (e.g., after removing operator)
      if (_expressionParts.isNotEmpty) {
        final lastPart = _expressionParts.removeLast();

        // If it's an operator, restore the value before it
        if (_isOperator(lastPart.value) && _expressionParts.isNotEmpty) {
          final valuePart = _expressionParts.removeLast();
          _restoreEngineFromPart(valuePart.value);
        } else {
          _restoreEngineFromPart(lastPart.value);
        }

        notifyListeners();
      }
    });
  }

  /// Restores the engine state (and the percentage flag) from a stored
  /// expression part value, which may carry a literal `%` suffix.
  void _restoreEngineFromPart(String partValue) {
    if (partValue.endsWith('%')) {
      final numeric = partValue.substring(0, partValue.length - 1);
      _add2Engine.setValue(_parseToInt(numeric));
      _currentIsPercentage = true;
    } else {
      _add2Engine.setValue(_parseToInt(partValue));
      _currentIsPercentage = false;
    }
  }

  bool _isOperator(String value) {
    return value == '+' || value == '−' || value == '×' || value == '÷';
  }

  void loadMoreTimelineEntries() {
    _visibleCount += _loadMoreCount;
    notifyListeners();
  }

  void loadSession(List<HistoryEntry> entries) {
    _timelineEntries.clear();

    for (final entry in entries) {
      _timelineEntries.add(
        Calculation(
          expression: _formatExpression(entry.expression),
          result: _formatValue(entry.result),
          timestamp: entry.createdAt,
        ),
      );
    }

    // Set last result as current display
    if (entries.isNotEmpty) {
      final lastResult = entries.last.result;
      _add2Engine.setValue(_parseToInt(lastResult));
    }

    _expressionParts.clear();
    _currentOperator = null;
    _isNewInput = true;
    _currentIsPercentage = false;
    notifyListeners();
  }

  String _buildFullExpression() {
    final buffer = StringBuffer();

    for (final part in _expressionParts) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(part.value);
    }

    if (_currentOperator != null) {
      buffer.write(' $_currentOperator');
      buffer.write(' ${_add2Engine.formattedValue}');
      if (_currentIsPercentage) buffer.write('%');
    }

    return buffer.toString();
  }

  int _parseToInt(String formattedValue) {
    final parsed = double.tryParse(formattedValue);
    if (parsed == null) return 0;

    return (parsed * 100).round();
  }

  /// Formats a plain value (e.g., "12500.00") using the current
  /// decimal separator and thousands grouping.
  String _formatValue(String plainValue) {
    final parsed = double.tryParse(plainValue);
    if (parsed == null) return plainValue;

    return NumberFormatter.formatDouble(
      parsed,
      separator: _decimalSeparator,
      useThousandsSeparator: true,
    );
  }

  /// Formats a full plain expression (e.g., "12500.00 + 3500.00" or
  /// "100.00 + 10.00%") by formatting each numeric token while preserving
  /// any trailing literal `%` suffix.
  String _formatExpression(String plainExpression) {
    final tokens = plainExpression.split(' ');
    final formatted = tokens.map((token) {
      if (_isOperator(token)) return token;

      if (token.endsWith('%')) {
        final numeric = token.substring(0, token.length - 1);

        return '${_formatValue(numeric)}%';
      }

      return _formatValue(token);
    });

    return formatted.join(' ');
  }
}

class _ExpressionPart {
  final String value;

  const _ExpressionPart(this.value);
}
