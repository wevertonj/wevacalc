enum OperationType {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  final String symbol;

  const OperationType(this.symbol);
}
