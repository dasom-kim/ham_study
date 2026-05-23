import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/study_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _rangeStart = DateTime.now();
  DateTime? _rangeEnd = DateTime.now();

  Map<DateTime, Map<String, int>> _dailyStats = {};

  int _getTotalTimeForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final stats = _dailyStats[dateKey];
    if (stats == null || stats.isEmpty) return 0;
    return stats.values.reduce((a, b) => a + b);
  }

  String _formatShortTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      if (_rangeStart != null &&
          _rangeEnd != null &&
          DateUtils.isSameDay(_rangeStart, _rangeEnd)) {
        if (date.isBefore(_rangeStart!)) {
          _rangeStart = date;
        } else {
          _rangeEnd = date;
        }
      } else {
        _rangeStart = date;
        _rangeEnd = date;
      }
    });
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0(Sun) ~ 6(Sat)

    final totalSlots = ((daysInMonth + firstWeekday) / 7).ceil() * 7;

    // 이동 가능한 달의 최소/최대 범위 계산
    DateTime maxDate = DateTime.now();
    DateTime minDate = maxDate;
    if (_dailyStats.isNotEmpty) {
      minDate = _dailyStats.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    }

    bool canGoBack = (_focusedDate.year > minDate.year) ||
        (_focusedDate.year == minDate.year &&
            _focusedDate.month > minDate.month);

    bool canGoForward = (_focusedDate.year < maxDate.year) ||
        (_focusedDate.year == maxDate.year &&
            _focusedDate.month < maxDate.month);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canGoBack
                  ? () => setState(() {
                        _focusedDate = DateTime(
                            _focusedDate.year, _focusedDate.month - 1, 1);
                      })
                  : null, // 비활성화 시 자동으로 회색 처리됨
            ),
            Text(
              DateFormat('yyyy년 M월').format(_focusedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoForward
                  ? () => setState(() {
                        _focusedDate = DateTime(
                            _focusedDate.year, _focusedDate.month + 1, 1);
                      })
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['일', '월', '화', '수', '목', '금', '토']
              .map((day) => Text(day,
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)))
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: totalSlots,
          itemBuilder: (context, index) {
            final dayOffset = index - firstWeekday;
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              return const SizedBox.shrink();
            }
            final date =
                DateTime(_focusedDate.year, _focusedDate.month, dayOffset + 1);

            bool isSelected = false;
            bool isRangeStartOrEnd = false;
            if (_rangeStart != null && _rangeEnd != null) {
              final start = DateUtils.dateOnly(_rangeStart!);
              final end = DateUtils.dateOnly(_rangeEnd!);
              final target = DateUtils.dateOnly(date);
              isSelected =
                  (target.isAtSameMomentAs(start) || target.isAfter(start)) &&
                      (target.isAtSameMomentAs(end) || target.isBefore(end));
              isRangeStartOrEnd = target.isAtSameMomentAs(start) ||
                  target.isAtSameMomentAs(end);
            }
            final totalSeconds = _getTotalTimeForDate(date);

            return GestureDetector(
              onTap: () => _onDateTapped(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepOrange
                          .withValues(alpha: isRangeStartOrEnd ? 0.2 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isRangeStartOrEnd
                      ? Border.all(color: Colors.deepOrange)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontWeight: isRangeStartOrEnd
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isRangeStartOrEnd
                            ? Colors.deepOrange
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87),
                      ),
                      child: Text('${date.day}'),
                    ),
                    const SizedBox(height: 4),
                    if (totalSeconds > 0)
                      FittedBox(
                        child: Text(
                          _formatShortTime(totalSeconds),
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.blueGrey,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDailyDetail(List<Subject> subjects) {
    if (_rangeStart == null) return const SizedBox.shrink();

    final dateKey =
        DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    final stats = _dailyStats[dateKey] ?? {};

    if (stats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Text('이 날은 공부 기록이 없네요!', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats.entries.map((entry) {
        final subject = subjects.firstWhere(
          (s) => s.id == entry.key,
          orElse: () => Subject(id: '', name: '삭제된 과목', color: Colors.grey),
        );
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.circle, color: subject.color, size: 16),
          title: Text(subject.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(entry.value.toTimeFormat(),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()])),
        );
      }).toList(),
    );
  }

  Widget _buildRangeStats(List<Subject> subjects) {
    final Map<String, int> aggregated = {};
    int totalOverall = 0;

    final start = DateUtils.dateOnly(_rangeStart!);
    final end = DateUtils.dateOnly(_rangeEnd!);

    _dailyStats.forEach((date, dailyData) {
      final target = DateUtils.dateOnly(date);
      if ((target.isAtSameMomentAs(start) || target.isAfter(start)) &&
          (target.isAtSameMomentAs(end) || target.isBefore(end))) {
        dailyData.forEach((subjectId, seconds) {
          aggregated[subjectId] = (aggregated[subjectId] ?? 0) + seconds;
          totalOverall += seconds;
        });
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${DateFormat('yyyy.MM.dd').format(start)} ~ ${DateFormat('yyyy.MM.dd').format(end)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text('총 공부 시간', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  totalOverall.toTimeFormat(),
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ],
            )),
        const SizedBox(height: 32),
        const Text('과목별 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (aggregated.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: Text('해당 기간에 공부 기록이 없습니다.',
                    style: TextStyle(color: Colors.grey))),
          )
        else
          ...aggregated.entries.map((entry) {
            final subject = subjects.firstWhere(
              (s) => s.id == entry.key,
              orElse: () => Subject(id: '', name: '삭제된 과목', color: Colors.grey),
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subject.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.menu_book, color: subject.color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(subject.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    entry.value.toTimeFormat(),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCalendarAndDetails(List<Subject> subjects, bool isWide) {
    final calendarWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: _buildCalendar(),
    );

    final isSingleDay = _rangeStart != null &&
        _rangeEnd != null &&
        DateUtils.isSameDay(_rangeStart, _rangeEnd);

    final Key detailsKey = ValueKey(
        '${_rangeStart?.toIso8601String()}_${_rangeEnd?.toIso8601String()}');
    Widget detailsWidget;

    if (_rangeStart == null || _rangeEnd == null) {
      detailsWidget = const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('날짜를 선택해주세요.', style: TextStyle(color: Colors.grey)),
        ),
      );
    } else if (isSingleDay) {
      detailsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_rangeStart!.month}월 ${_rangeStart!.day}일 상세 기록',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: _buildDailyDetail(subjects),
          ),
        ],
      );
    } else {
      detailsWidget = _buildRangeStats(subjects);
    }

    detailsWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SizedBox(
          key: detailsKey, width: double.infinity, child: detailsWidget),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: calendarWidget),
          const SizedBox(width: 30),
          Expanded(flex: 4, child: detailsWidget),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          calendarWidget,
          const SizedBox(height: 30),
          detailsWidget,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final dailyStatsRaw = ref.watch(dailyStatsProvider);

    _dailyStats.clear();
    dailyStatsRaw.forEach((dateStr, data) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final date = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        _dailyStats[date] = data;
      }
    });

    final isDarkMode = ref.watch(isDarkModeProvider);

    // 화면 가로 너비에 따른 반응형 변수 (800px 이상이면 데스크톱/태블릿 모드)
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // 좌우 배치 시 더 넓은 공간을 사용하도록 MaxWidth 동적 조절
            constraints: BoxConstraints(maxWidth: isWide ? 1000 : 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: _buildCalendarAndDetails(subjects, isWide),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
