import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:wevacalc/data/repositories/history_repository.dart';
import 'package:wevacalc/data/repositories/settings_repository.dart';
import 'package:wevacalc/domain/add2_engine.dart';
import 'package:wevacalc/domain/entities/calculation.dart';
import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/domain/entities/history_line.dart';
import 'package:wevacalc/domain/entities/history_selection.dart';
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

  /// Raw expression/result pairs accumulated during the current session.
  /// These are persisted as a single [HistoryEntry] on each `=` press
  /// (created the first time, updated on subsequent presses) and on `clear()`.
  final List<HistoryLine> _sessionLines = [];

  /// Committed tokens of the in-progress expression. Each entry is one of:
  /// a numeric value (optionally suffixed with `%`), an operator
  /// (`+`, `−`, `×`, `÷`), or a parenthesis (`(`, `)`).
  final List<String> _committed = [];

  /// Fila de ações do usuário.
  ///
  /// Garante que toques disparados durante o processamento de outra ação
  /// (por exemplo, via `notifyListeners` que reentra na ViewModel) sejam
  /// processados em ordem, sem perda. Dart é single-threaded, então a fila
  /// serve apenas como proteção contra reentrância síncrona.
  final Queue<VoidCallback> _actionQueue = Queue<VoidCallback>();
  bool _isProcessingActions = false;

  /// Database ID of the current session. `null` when no session has been
  /// persisted yet. Set after the first `=` press and reset on `clear()`.
  int? _currentSessionId;

  /// Number of session lines already persisted. Used to skip redundant
  /// save calls (e.g., `clear()` right after `=` should not re-add).
  int _persistedLineCount = 0;

  /// True once an `add` has been issued for the current session, even before
  /// the asynchronous future resolves with the new id. Prevents duplicate
  /// `add` calls when subsequent persistence happens synchronously after `=`.
  bool _addInFlight = false;

  /// Operator typed but not yet committed (waiting for the right-hand side).
  String? _pendingOperator;

  /// True while the value held by [_add2Engine] represents the operand
  /// currently being typed (uncommitted).
  bool _engineActive = false;

  /// Indicates the engine value is a stale result (post `=` or session load)
  /// and the next digit input should reset the engine to start fresh.
  bool _shouldResetOnInput = false;

  /// Marks the active engine value as a literal percentage operand.
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

  String? get currentOperator => _pendingOperator;

  /// Number of unmatched opening parentheses in the committed expression.
  int get openParenCount {
    var n = 0;
    for (final t in _committed) {
      if (t == '(') {
        n++;
      } else if (t == ')') {
        n--;
      }
    }

    return n;
  }

  /// True when there is anything in the calculator that the user could clear:
  /// committed tokens, an active operand, a pending operator, an in-flight
  /// post-equals result, or session timeline entries.
  bool get hasContent {
    if (_committed.isNotEmpty) return true;
    if (_engineActive) return true;
    if (_pendingOperator != null) return true;
    if (_timelineEntries.isNotEmpty) return true;
    if (_shouldResetOnInput) return true;

    return false;
  }

  /// Full display text — the entire expression on a single line.
  /// e.g., "7856.00", "7856.00 ×", "7856.00 × 52.00", "100.00 + 10.00%".
  String get fullDisplayText {
    final parts = <String>[];
    for (final t in _committed) {
      parts.add(_formatPart(t));
    }
    if (_pendingOperator != null) {
      parts.add(_pendingOperator!);
    }
    if (_engineActive) {
      parts.add(_formatPart(_engineToken()));
    } else if (_pendingOperator == null) {
      final last = _committed.isNotEmpty ? _committed.last : null;
      if (last != null && last != '(' && last != ')' && !_isOperator(last)) {
        parts.add(currentDisplayValue);
      }
    }

    if (parts.isEmpty) return currentDisplayValue;

    return parts.join(' ');
  }

  /// In-progress expression without the active engine value.
  /// Used by widgets that show the typed expression separately.
  String get expression {
    final parts = <String>[];
    for (final t in _committed) {
      parts.add(_formatPart(t));
    }
    if (_pendingOperator != null) {
      parts.add(_pendingOperator!);
    }

    return parts.join(' ');
  }

  String? get previewResult {
    if (_committed.isEmpty) return null;

    final hasActiveInput = _engineActive && _pendingOperator != null;
    final hasClosedExpression =
        !_engineActive && _pendingOperator == null && _lastIsClosingParen();

    if (!hasActiveInput && !hasClosedExpression) return null;

    final raw = _buildFullExpression();
    final result = _evaluator.evaluate(raw);
    if (result == null) return null;

    return _formatValue(result);
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
      if (!_canInputDigit()) return;
      _prepareForDigitInput();
      _add2Engine.inputDigit(digit);
      _engineActive = true;
      notifyListeners();
    });
  }

  void inputDoubleZero() {
    _runAction(() {
      if (!_canInputDigit()) return;
      _prepareForDigitInput();
      _add2Engine.inputDoubleZero();
      _engineActive = true;
      notifyListeners();
    });
  }

  void inputTripleZero() {
    _runAction(() {
      if (!_canInputDigit()) return;
      _prepareForDigitInput();
      _add2Engine.inputTripleZero();
      _engineActive = true;
      notifyListeners();
    });
  }

  bool _canInputDigit() {
    // After ')' with no pending operator, digits are ignored — the user must
    // press an operator first (no implicit multiplication).
    if (!_engineActive && _pendingOperator == null && _lastIsClosingParen()) {
      return false;
    }

    return true;
  }

  void _prepareForDigitInput() {
    if (_currentIsPercentage) {
      _add2Engine.reset();
      _currentIsPercentage = false;

      return;
    }

    if (_shouldResetOnInput) {
      _add2Engine.reset();
      _shouldResetOnInput = false;

      return;
    }

    if (!_engineActive) {
      _add2Engine.reset();
    }
  }

  void setOperator(String operator) {
    _runAction(() {
      _shouldResetOnInput = false;

      if (_engineActive) {
        if (_pendingOperator != null) {
          _committed.add(_pendingOperator!);
        }
        _committed.add(_engineToken());
        _engineActive = false;
      } else if (_pendingOperator == null && _committed.isEmpty) {
        // No content yet — commit current engine value (e.g., 0.00) so the
        // expression starts with an operand.
        _committed.add(_engineToken());
      }

      _currentIsPercentage = false;
      _pendingOperator = operator;
      notifyListeners();
    });
  }

  void applyPercentage() {
    _runAction(() {
      if (_pendingOperator == null) return;
      if (!_engineActive) return;
      if (_add2Engine.isEmpty) return;
      if (_currentIsPercentage) return;

      _currentIsPercentage = true;
      notifyListeners();
    });
  }

  /// Toggle insertion of an opening or closing parenthesis depending on
  /// the current state. Inserts `(` when at start, after an operator, or
  /// after another `(`. Inserts `)` when there is at least one unmatched
  /// `(` and the last token is a complete operand.
  void inputParenthesis() {
    _runAction(() {
      if (_canCloseParen()) {
        _insertCloseParen();
        notifyListeners();

        return;
      }

      if (_canOpenParen()) {
        _insertOpenParen();
        notifyListeners();
      }
    });
  }

  bool _canCloseParen() {
    if (openParenCount <= 0) return false;
    if (_pendingOperator != null && !_engineActive) return false;
    if (_engineActive) return true;
    if (_committed.isEmpty) return false;

    final last = _committed.last;

    return last != '(' && !_isOperator(last);
  }

  bool _canOpenParen() {
    if (_engineActive) return false;
    if (_pendingOperator != null) return true;
    if (_committed.isEmpty) return true;
    if (_committed.last == '(') return true;

    return false;
  }

  void _insertOpenParen() {
    if (_pendingOperator != null) {
      _committed.add(_pendingOperator!);
      _pendingOperator = null;
    }
    _committed.add('(');
    _add2Engine.reset();
    _engineActive = false;
    _currentIsPercentage = false;
    _shouldResetOnInput = false;
  }

  void _insertCloseParen() {
    if (_engineActive) {
      if (_pendingOperator != null) {
        _committed.add(_pendingOperator!);
        _pendingOperator = null;
      }
      _committed.add(_engineToken());
      _engineActive = false;
    }
    _committed.add(')');
    _currentIsPercentage = false;
    _shouldResetOnInput = false;
  }

  void equals() {
    _runAction(() {
      // Need at least one operator anywhere to be evaluable.
      final hasOperator =
          _pendingOperator != null || _committed.any(_isOperator);
      if (!hasOperator) return;

      if (_pendingOperator != null && !_engineActive) {
        // "12.50 +" with no RHS — evaluator handles trailing operator
        // gracefully, so we still proceed.
      }

      var raw = _buildFullExpression();
      // Auto-close any unbalanced parentheses before evaluation.
      final open = openParenCount;
      if (open > 0) {
        raw = '$raw${' )' * open}';
      }

      final result = _evaluator.evaluate(raw);
      if (result == null) return;

      final formattedExpression = _formatExpression(raw);
      final formattedResult = _formatValue(result);

      final calculation = Calculation(
        expression: formattedExpression,
        result: formattedResult,
        timestamp: DateTime.now(),
      );

      _timelineEntries.add(calculation);

      // Store the raw expression/result pair for session-based saving.
      _sessionLines.add(HistoryLine(expression: raw, result: result));

      // Persist the session: create on first =, update on subsequent.
      _saveOrUpdateSession();

      _committed.clear();
      _pendingOperator = null;
      _engineActive = false;
      _shouldResetOnInput = true;
      _currentIsPercentage = false;
      _add2Engine.setValue(_parseToInt(result));

      notifyListeners();
    });
  }

  void clear() {
    _runAction(() {
      if (!hasContent) return;

      // Save/update the current session to history before clearing.
      _saveOrUpdateSession();

      _add2Engine.reset();
      _committed.clear();
      _pendingOperator = null;
      _engineActive = false;
      _shouldResetOnInput = false;
      _currentIsPercentage = false;
      _timelineEntries.clear();
      _sessionLines.clear();
      _currentSessionId = null;
      _persistedLineCount = 0;
      notifyListeners();
    });
  }

  void backspace() {
    _runAction(() {
      // Drop the literal `%` marker first if active.
      if (_currentIsPercentage) {
        _currentIsPercentage = false;
        notifyListeners();

        return;
      }

      // Pending operator with no new digits — remove the operator first.
      if (_pendingOperator != null && !_engineActive) {
        _pendingOperator = null;
        if (_committed.isNotEmpty) {
          final last = _committed.last;
          // Keep structural expression tokens intact when the trailing
          // operator is deleted after a closed group, e.g. "( ... ) +".
          if (last != '(' && last != ')' && !_isOperator(last)) {
            _committed.removeLast();
            _restoreEngineFromToken(last);
          }
        }
        notifyListeners();

        return;
      }

      if (_engineActive && !_add2Engine.isEmpty) {
        _add2Engine.deleteLastDigit();
        if (_add2Engine.isEmpty) {
          _engineActive = false;
          // If we just emptied the right-hand operand AND there is no
          // pending operator, promote a dangling committed operator back
          // to `_pendingOperator`. Otherwise the display would show an
          // orphan "0.00" after the operator.
          if (_pendingOperator == null &&
              _committed.isNotEmpty &&
              _isOperator(_committed.last)) {
            _pendingOperator = _committed.removeLast();
          }
        }
        notifyListeners();

        return;
      }

      // Engine empty — backspace into committed tokens.
      if (_committed.isNotEmpty) {
        final last = _committed.removeLast();
        if (last == ')') {
          // Removing a closing paren: restore the operand just inside the
          // group (if any) to the engine so the user can keep editing it.
          if (_committed.isNotEmpty && _isValueToken(_committed.last)) {
            final value = _committed.removeLast();
            _restoreEngineFromToken(value);
          } else {
            _add2Engine.reset();
            _engineActive = false;
            _currentIsPercentage = false;
          }
        } else if (last == '(') {
          // Opening paren removed structurally — engine stays empty.
          _add2Engine.reset();
          _engineActive = false;
          _currentIsPercentage = false;
        } else if (_isOperator(last)) {
          if (_committed.isNotEmpty) {
            final value = _committed.removeLast();
            if (value == '(' || value == ')') {
              // Don't pop a paren when removing an operator — put it back.
              _committed.add(value);
              _add2Engine.reset();
              _engineActive = false;
              _currentIsPercentage = false;
            } else {
              _restoreEngineFromToken(value);
            }
          }
        } else {
          _restoreEngineFromToken(last);
        }
        notifyListeners();
      }
    });
  }

  void loadMoreTimelineEntries() {
    _visibleCount += _loadMoreCount;
    notifyListeners();
  }

  /// Loads a history session into the calculator, restoring the timeline
  /// up to (and including) the specified [selection.lineIndex].
  ///
  /// The last loaded line's expression is placed into the display field
  /// as if the user had just typed it, ready for editing or continuation.
  void loadSession(HistorySelection selection) {
    // Save any existing session before overwriting.
    _saveOrUpdateSession();

    _timelineEntries.clear();
    _sessionLines.clear();

    final entry = selection.entry;
    final upToIndex = selection.lineIndex.clamp(0, entry.lines.length - 1);

    // Track the loaded session so subsequent = presses update it.
    _currentSessionId = entry.id;
    _persistedLineCount = 0; // Updated after lines are added below.

    // Load all lines up to (but not including) the selected line into timeline.
    for (var i = 0; i < upToIndex; i++) {
      final line = entry.lines[i];
      _timelineEntries.add(
        Calculation(
          expression: _formatExpression(line.expression),
          result: _formatValue(line.result),
          timestamp: entry.createdAt,
        ),
      );
      _sessionLines.add(line);
    }

    // The selected line: put its expression into the display field
    // and its result into the engine.
    final selectedLine = entry.lines[upToIndex];
    _timelineEntries.add(
      Calculation(
        expression: _formatExpression(selectedLine.expression),
        result: _formatValue(selectedLine.result),
        timestamp: entry.createdAt,
      ),
    );
    _sessionLines.add(selectedLine);
    _add2Engine.setValue(_parseToInt(selectedLine.result));

    // Loaded lines are already persisted in the database, so subsequent
    // saves should hit the update branch (or no-op if no new lines).
    _persistedLineCount = _sessionLines.length;

    _committed.clear();
    _pendingOperator = null;
    _engineActive = false;
    _currentIsPercentage = false;
    _shouldResetOnInput = true;
    notifyListeners();
  }

  // ----- Helpers --------------------------------------------------------

  /// Persists or updates the current session lines as a single [HistoryEntry].
  ///
  /// On the first call within a session, creates a new row in the database
  /// and stores its ID in [_currentSessionId]. Subsequent calls update the
  /// existing row with the latest lines and result. No-op when there are
  /// no new lines since the last persist.
  void _saveOrUpdateSession() {
    if (_sessionLines.isEmpty) return;
    if (_sessionLines.length == _persistedLineCount) return;

    final lastResult = _sessionLines.last.result;
    final linesSnapshot = List.of(_sessionLines);

    if (_currentSessionId != null) {
      _historyRepository.update(
        HistoryEntry(
          id: _currentSessionId,
          lines: linesSnapshot,
          result: lastResult,
          createdAt: DateTime.now(),
        ),
      );
      _persistedLineCount = linesSnapshot.length;

      return;
    }

    if (_addInFlight) {
      // First add already issued but id not yet returned. Do not issue
      // another add; the in-flight future will set the id and the next
      // persist call will go through the update branch.
      _persistedLineCount = linesSnapshot.length;

      return;
    }

    _addInFlight = true;
    _persistedLineCount = linesSnapshot.length;
    _historyRepository
        .add(
          HistoryEntry(
            lines: linesSnapshot,
            result: lastResult,
            createdAt: DateTime.now(),
          ),
        )
        .then((saved) {
          _addInFlight = false;
          // Only adopt the id if the session wasn't reset in the meantime.
          if (_persistedLineCount > 0) {
            _currentSessionId = saved.id;
          }
        });
  }

  String _engineToken() {
    final value = _add2Engine.formattedValue;

    return _currentIsPercentage ? '$value%' : value;
  }

  bool _lastIsClosingParen() {
    return _committed.isNotEmpty && _committed.last == ')';
  }

  bool _isOperator(String value) {
    return value == '+' || value == '−' || value == '×' || value == '÷';
  }

  bool _isValueToken(String value) {
    if (value == '(' || value == ')') return false;

    return !_isOperator(value);
  }

  /// Formats a single committed (or active) token for display: numbers go
  /// through the configured number formatter, operators and parentheses pass
  /// through, and `%`-suffixed values keep the literal percent sign.
  String _formatPart(String value) {
    if (_isOperator(value)) return value;
    if (value == '(' || value == ')') return value;

    if (value.endsWith('%')) {
      final numeric = value.substring(0, value.length - 1);

      return '${_formatValue(numeric)}%';
    }

    return _formatValue(value);
  }

  /// Restores the engine state (and the percentage flag) from a committed
  /// token, which may carry a literal `%` suffix. Operators and parens are
  /// not restorable as engine values; the caller is responsible for filtering.
  void _restoreEngineFromToken(String token) {
    if (token == '(' || token == ')') {
      _add2Engine.reset();
      _engineActive = false;
      _currentIsPercentage = false;

      return;
    }

    if (token.endsWith('%')) {
      final numeric = token.substring(0, token.length - 1);
      _add2Engine.setValue(_parseToInt(numeric));
      _currentIsPercentage = true;
    } else {
      _add2Engine.setValue(_parseToInt(token));
      _currentIsPercentage = false;
    }
    _engineActive = true;
  }

  String _buildFullExpression() {
    final parts = <String>[..._committed];
    if (_pendingOperator != null) parts.add(_pendingOperator!);
    if (_engineActive) parts.add(_engineToken());

    return parts.join(' ');
  }

  int _parseToInt(String formattedValue) {
    final parsed = double.tryParse(formattedValue);
    if (parsed == null) return 0;

    return (parsed * 100).round();
  }

  String _formatValue(String plainValue) {
    final parsed = double.tryParse(plainValue);
    if (parsed == null) return plainValue;

    return NumberFormatter.formatDouble(
      parsed,
      separator: _decimalSeparator,
      useThousandsSeparator: true,
    );
  }

  String _formatExpression(String plainExpression) {
    final tokens = plainExpression.split(' ');
    final formatted = tokens.map(_formatPart);

    return formatted.join(' ');
  }
}
