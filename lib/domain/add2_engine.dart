class Add2Engine {
  String _rawDigits = '';

  String get rawDigits => _rawDigits;

  bool get isEmpty => _rawDigits.isEmpty;

  int get intValue {
    if (_rawDigits.isEmpty) return 0;

    return int.tryParse(_rawDigits) ?? 0;
  }

  double get doubleValue => intValue / 100.0;

  String get formattedValue {
    final cents = intValue;
    final isNegative = cents < 0;
    final absCents = cents.abs();
    final wholePart = absCents ~/ 100;
    final decimalPart = absCents % 100;
    final sign = isNegative ? '-' : '';

    return '$sign$wholePart.${decimalPart.toString().padLeft(2, '0')}';
  }

  void inputDigit(String digit) {
    if (digit.length != 1 || !RegExp(r'^[0-9]$').hasMatch(digit)) return;

    _rawDigits += digit;
  }

  void inputDoubleZero() {
    _rawDigits += '00';
  }

  void inputTripleZero() {
    _rawDigits += '000';
  }

  void deleteLastDigit() {
    if (_rawDigits.isEmpty) return;

    _rawDigits = _rawDigits.substring(0, _rawDigits.length - 1);
  }

  void reset() {
    _rawDigits = '';
  }

  void setValue(int cents) {
    if (cents == 0) {
      _rawDigits = '';

      return;
    }

    _rawDigits = cents.toString();
  }
}
