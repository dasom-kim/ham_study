import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 시간 포맷팅을 위한 헬퍼 확장(Extension) 함수
extension TimeFormat on int {
  String toTimeFormat() {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    final s = this % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class Subject {
  final String id;
  final String name;
  final Color color;
  final int netSeconds;

  Subject(
      {required this.id,
      required this.name,
      required this.color,
      this.netSeconds = 0});

  Subject copyWith({String? name, Color? color, int? netSeconds}) {
    return Subject(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      netSeconds: netSeconds ?? this.netSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'netSeconds': netSeconds,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        netSeconds: json['netSeconds'] as int,
      );
}

class SubjectsNotifier extends Notifier<List<Subject>> {
  @override
  List<Subject> build() {
    _loadData();
    return [];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('subjects');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((e) => Subject.fromJson(e)).toList();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('subjects', encoded);
  }

  void updateTime(String id, int additionalSeconds) {
    state = state
        .map((s) => s.id == id
            ? s.copyWith(netSeconds: s.netSeconds + additionalSeconds)
            : s)
        .toList();
    ref.read(dailyStatsProvider.notifier).updateTime(id, additionalSeconds);
  }

  void saveCurrentState() {
    _saveData();
    ref.read(dailyStatsProvider.notifier).saveCurrentState();
  }

  void addSubject(String name, Color color) {
    state = [
      ...state,
      Subject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          color: color)
    ];
    _saveData();
  }

  void updateSubject(String id, String name, Color color) {
    state = state
        .map((s) => s.id == id ? s.copyWith(name: name, color: color) : s)
        .toList();
    _saveData();
  }

  void deleteSubject(String id) {
    state = state.where((s) => s.id != id).toList();
    _saveData();
  }

  void reorderSubjects(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<Subject> items = List.from(state);
    final Subject item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    _saveData();
  }
}

final subjectsProvider =
    NotifierProvider<SubjectsNotifier, List<Subject>>(SubjectsNotifier.new);

// 날짜별 통계 기록 관리
class DailyStatsNotifier extends Notifier<Map<String, Map<String, int>>> {
  @override
  Map<String, Map<String, int>> build() {
    _loadData();
    return {};
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('daily_stats');
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final Map<String, Map<String, int>> loaded = {};
      decoded.forEach((dateStr, subjectData) {
        final Map<String, int> subjects = {};
        (subjectData as Map<String, dynamic>).forEach((subjId, sec) {
          subjects[subjId] = sec as int;
        });
        loaded[dateStr] = subjects;
      });
      state = loaded;
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('daily_stats', jsonEncode(state));
  }

  void updateTime(String subjectId, int additionalSeconds) {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final currentStats = Map<String, Map<String, int>>.from(state);
    final todayStats = Map<String, int>.from(currentStats[dateKey] ?? {});

    todayStats[subjectId] = (todayStats[subjectId] ?? 0) + additionalSeconds;
    currentStats[dateKey] = todayStats;

    state = currentStats;
  }

  void saveCurrentState() {
    _saveData();
  }
}

final dailyStatsProvider =
    NotifierProvider<DailyStatsNotifier, Map<String, Map<String, int>>>(
        DailyStatsNotifier.new);

class Dday {
  final String id;
  final String title;
  final DateTime date;
  final bool isFavorite;

  Dday(
      {required this.id,
      required this.title,
      required this.date,
      this.isFavorite = false});

  Dday copyWith({String? title, DateTime? date, bool? isFavorite}) {
    return Dday(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory Dday.fromJson(Map<String, dynamic> json) => Dday(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        isFavorite: json['isFavorite'] == true, // 완전히 안전한 불리언 판별
      );
}

class DdaysNotifier extends Notifier<List<Dday>> {
  @override
  List<Dday> build() {
    _loadData();
    return [];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('ddays');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((e) => Dday.fromJson(e)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('ddays', encoded);
  }

  void addDday(String title, DateTime date) {
    state = [
      ...state,
      Dday(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          date: date)
    ]..sort((a, b) => a.date.compareTo(b.date));
    _saveData();
  }

  void updateDday(String id, String title, DateTime date) {
    state = state
        .map((d) => d.id == id ? d.copyWith(title: title, date: date) : d)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    _saveData();
  }

  void deleteDday(String id) {
    state = state.where((d) => d.id != id).toList();
    _saveData();
  }

  void toggleFavorite(String id) {
    state = state
        .map((d) => d.id == id ? d.copyWith(isFavorite: !d.isFavorite) : d)
        .toList();
    _saveData();
  }
}

final ddaysProvider =
    NotifierProvider<DdaysNotifier, List<Dday>>(DdaysNotifier.new);

// 즐겨찾기 타이머 데이터 모델
class SavedTimer {
  final String id;
  final String title;
  final int seconds;

  SavedTimer({required this.id, required this.title, required this.seconds});

  SavedTimer copyWith({String? title, int? seconds}) {
    return SavedTimer(
        id: id, title: title ?? this.title, seconds: seconds ?? this.seconds);
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'seconds': seconds};

  factory SavedTimer.fromJson(Map<String, dynamic> json) => SavedTimer(
      id: json['id'] as String,
      title: json['title'] as String,
      seconds: json['seconds'] as int);
}

class SavedTimersNotifier extends Notifier<List<SavedTimer>> {
  @override
  List<SavedTimer> build() {
    _loadData();
    return [];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_timers');
    if (data != null) {
      state = (jsonDecode(data) as List<dynamic>)
          .map((e) => SavedTimer.fromJson(e))
          .toList();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'saved_timers', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void addTimer(String title, int seconds) {
    state = [
      ...state,
      SavedTimer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          seconds: seconds)
    ];
    _saveData();
  }

  void updateTimer(String id, String title, int seconds) {
    state = state
        .map((t) => t.id == id ? t.copyWith(title: title, seconds: seconds) : t)
        .toList();
    _saveData();
  }

  void deleteTimer(String id) {
    state = state.where((t) => t.id != id).toList();
    _saveData();
  }

  void reorderTimers(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<SavedTimer> items = List.from(state);
    final SavedTimer item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    _saveData();
  }
}

final savedTimersProvider =
    NotifierProvider<SavedTimersNotifier, List<SavedTimer>>(
        SavedTimersNotifier.new);

// 다크 모드 상태 관리
class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadData();
    return false;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isDarkMode') ?? false;
  }

  void toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }
}

final isDarkModeProvider =
    NotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);
