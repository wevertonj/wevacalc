class Calculation {
  final String expression;
  final String result;
  final DateTime timestamp;

  const Calculation({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Calculation &&
          runtimeType == other.runtimeType &&
          expression == other.expression &&
          result == other.result &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(expression, result, timestamp);
}
