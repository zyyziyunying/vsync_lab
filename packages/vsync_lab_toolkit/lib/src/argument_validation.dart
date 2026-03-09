double validateTargetRefreshRate(
  double value, {
  String name = 'targetRefreshRate',
}) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(
      value,
      name,
      'Must be a finite number greater than 0.',
    );
  }

  return value;
}

int validatePositiveInt(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'Must be greater than 0.');
  }

  return value;
}

double frameBudgetMsForRefreshRate(double targetRefreshRate) {
  return 1000 / validateTargetRefreshRate(targetRefreshRate);
}

int expectedFrameIntervalUsForRefreshRate(double targetRefreshRate) {
  return (1000000 / validateTargetRefreshRate(targetRefreshRate)).round();
}
