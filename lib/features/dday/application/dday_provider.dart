import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dday_event.dart';

final mainDdayProvider = Provider<DdayEvent>((ref) {
  final now = DateTime.now();
  return DdayEvent(
    id: 'sample-exam',
    title: '목표 시험',
    date: DateTime(now.year, now.month + 1, now.day),
  );
});
