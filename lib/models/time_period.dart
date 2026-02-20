enum TimePeriod {
  day('Day'),
  today('Today'),
  week('Week'),
  month('Month'),
  year('Year'),
  all('All');

  final String label;
  const TimePeriod(this.label);

  static TimePeriod? fromString(String label) {
    try {
      return values.firstWhere((e) => e.label == label);
    } catch (_) {
      return null;
    }
  }
}
