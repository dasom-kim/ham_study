class DdayEvent {
  const DdayEvent({
    required this.id,
    required this.title,
    required this.date,
  });

  final String id;
  final String title;
  final DateTime date;

  int daysLeft(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }
}
