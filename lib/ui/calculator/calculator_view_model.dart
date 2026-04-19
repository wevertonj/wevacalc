import 'package:flutter/foundation.dart';

import 'package:wevacalc/data/repositories/history_repository.dart';
import 'package:wevacalc/domain/add2_engine.dart';
import 'package:wevacalc/domain/entities/calculation.dart';
import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/domain/expression_evaluator.dart';

class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel({required HistoryRepository historyRepository})
    : _historyRepository = historyRepository;

  final HistoryRepository _historyRepository;
  final Add2Engine _add2Engine = Add2Engine();
  final ExpressionEvaluator _evaluator = ExpressionEvaluator();

  final List<Calculation> _timelineEntries = [];
  final List<_ExpressionPart> _expressionParts = [];

  String? _currentOperator;
  bool _isNewInput = true;
  bool _shouldResetOnInput = false;
  bool _hasPercentage = false;
  int _visibleCount = 20;

  static const int _loadMoreCount = 20;

  int get maxVisibleEntries => _visibleCount;

  String get currentDisplayValue => _add2Engine.formattedValue;

  String? get currentOperator => _currentOperator;

  String get expression {
    if (_expressionParts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final part in _expressionParts) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(part.value);
    }

    if (_currentOperator != null) {
      buffer.write(' $_currentOperator');
    }

    return buffer.toString();
  }

  String? get previewResult {
    if (_expressionParts.isEmpty || _currentOperator == null) return null;
    if (_add2Engine.isEmpty && _isNewInput) return null;

    final fullExpression = _buildFullExpression();
    if (_hasPercentage) {
      return _evaluator.evaluate('$fullExpression %');
    }

    return _evaluator.evaluate(fullExpression);
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

  void inputDigit(String digit) {
    if (_shouldResetOnInput) {
      _add2Engine.reset();
      _shouldResetOnInput = false;
    } else if (_isNewInput && _currentOperator != null) {
      _add2Engine.reset();
      _isNewInput = false;
    }

    _add2Engine.inputDigit(digit);
    notifyListeners();
  }

  void inputDoubleZero() {
    if (_shouldResetOnInput) {
      _add2Engine.reset();
      _shouldResetOnInput = false;
    } else if (_isNewInput && _currentOperator != null) {
      _add2Engine.reset();
      _isNewInput = false;
    }

    _add2Engine.inputDoubleZero();
    notifyListeners();
  }

  void inputTripleZero() {
    if (_shouldResetOnInput) {
      _add2Engine.reset();
      _shouldResetOnInput = false;
    } else if (_isNewInput && _currentOperator != null) {
      _add2Engine.reset();
      _isNewInput = false;
    }

    _add2Engine.inputTripleZero();
    notifyListeners();
  }

  void setOperator(String operator) {
    _shouldResetOnInput = false;

    if (_currentOperator != null && !_isNewInput && !_add2Engine.isEmpty) {
      // There's a pending operation — evaluate it first and chain
      final fullExpression = _buildFullExpression();
      final exprToEvaluate = _hasPercentage
          ? '$fullExpression %'
          : fullExpression;
      final result = _evaluator.evaluate(exprToEvaluate);
      if (result != null) {
        _expressionParts.clear();
        _expressionParts.add(_ExpressionPart(result));
        _add2Engine.setValue(_parseToInt(result));
        _hasPercentage = false;
      }
    } else if (_expressionParts.isEmpty || (_currentOperator == null)) {
      // First operator — save current value
      _expressionParts.clear();
      _expressionParts.add(_ExpressionPart(_add2Engine.formattedValue));
    }

    _currentOperator = operator;
    _isNewInput = true;
    notifyListeners();
  }

  void applyPercentage() {
    if (_currentOperator == null || _expressionParts.isEmpty) return;

    _hasPercentage = true;
    notifyListeners();
  }

  void equals() {
    if (_currentOperator == null || _expressionParts.isEmpty) return;
    if (_isNewInput && _add2Engine.isEmpty) return;

    final fullExpression = _buildFullExpression();
    final exprToEvaluate = _hasPercentage
        ? '$fullExpression %'
        : fullExpression;
    final result = _evaluator.evaluate(exprToEvaluate);

    if (result == null) return;

    final calculation = Calculation(
      expression: fullExpression,
      result: result,
      timestamp: DateTime.now(),
    );

    _timelineEntries.add(calculation);

    // Persist to history
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
    _hasPercentage = false;
    _add2Engine.setValue(_parseToInt(result));

    notifyListeners();
  }

  void clear() {
    _add2Engine.reset();
    _expressionParts.clear();
    _currentOperator = null;
    _isNewInput = true;
    _shouldResetOnInput = false;
    _hasPercentage = false;
    notifyListeners();
  }

  void backspace() {
    _add2Engine.deleteLastDigit();
    notifyListeners();
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
          expression: entry.expression,
          result: entry.result,
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
    }

    return buffer.toString();
  }

  int _parseToInt(String formattedValue) {
    final parsed = double.tryParse(formattedValue);
    if (parsed == null) return 0;

    return (parsed * 100).round();
  }
}

class _ExpressionPart {
  final String value;

  const _ExpressionPart(this.value);
}
