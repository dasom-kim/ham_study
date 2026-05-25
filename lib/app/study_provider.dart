import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget_service.dart';

// ─── 시간 포맷 헬퍼 ───────────────────────────────────────────────────────────

extension TimeFormat on int {
  String toTimeFormat() {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    final s = this % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Firebase 헬퍼 ────────────────────────────────────────────────────────────

final _db = FirebaseFirestore.instance;
String? _cachedUid;

Future<String> _getUserId() async {
  if (_cachedUid != null) return _cachedUid!;
  var user = FirebaseAuth.instance.currentUser;
  user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
  _cachedUid = user!.uid;
  return _cachedUid!;
}

CollectionReference _userCol(String uid, String name) =>
    _db.collection('users').doc(uid).collection(name);

// ─── Subject ─────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  final String name;
  final Color color;
  final int netSeconds;
  final int sortOrder;

  const Subject({
    required this.id,
    required this.name,
    required this.color,
    this.netSeconds = 0,
    this.sortOrder = 0,
  });

  Subject copyWith({String? name, Color? color, int? netSeconds, int? sortOrder}) =>
      Subject(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        netSeconds: netSeconds ?? this.netSeconds,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'netSeconds': netSeconds,
        'sortOrder': sortOrder,
      };

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Subject(
      id: d['id'] as String? ?? doc.id,
      name: d['name'] as String,
      color: Color(d['color'] as int),
      netSeconds: (d['netSeconds'] as int?) ?? 0,
      sortOrder: (d['sortOrder'] as int?) ?? 0,
    );
  }
}

class SubjectsNotifier extends Notifier<List<Subject>> {
  @override
  List<Subject> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final uid = await _getUserId();
    final snap = await _userCol(uid, 'subjects').orderBy('sortOrder').get();
    state = snap.docs.map(Subject.fromFirestore).toList();
  }

  // 매초 호출 — Firestore 쓰기 없이 메모리만 수정
  void updateTime(String id, int additionalSeconds) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(netSeconds: s.netSeconds + additionalSeconds) else s,
    ];
    ref.read(dailyStatsProvider.notifier).updateTime(id, additionalSeconds);
  }

  // 일시정지/백그라운드/종료 시 Firestore에 flush
  Future<void> saveCurrentState() async {
    final uid = await _getUserId();
    final batch = _db.batch();
    for (final s in state) {
      batch.set(
        _userCol(uid, 'subjects').doc(s.id),
        {'netSeconds': s.netSeconds},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    ref.read(dailyStatsProvider.notifier).saveCurrentState();
  }

  Future<void> addSubject(String name, Color color) async {
    final uid = await _getUserId();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final subject = Subject(id: id, name: name, color: color, sortOrder: state.length);
    state = [...state, subject];
    await _userCol(uid, 'subjects').doc(id).set(subject.toFirestore());
  }

  Future<void> updateSubject(String id, String name, Color color) async {
    final uid = await _getUserId();
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(name: name, color: color) else s,
    ];
    await _userCol(uid, 'subjects').doc(id).set(
      {'name': name, 'color': color.toARGB32()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteSubject(String id) async {
    final uid = await _getUserId();
    state = state.where((s) => s.id != id).toList();
    await _userCol(uid, 'subjects').doc(id).delete();
    _syncStudyWidget(); // 삭제 후 위젯 동기화
  }

  /// 공부시간 위젯 동기화 (현재 첫 번째 과목 기준, 과목 없으면 기본값)
  void _syncStudyWidget() {
    if (state.isEmpty) {
      WidgetService.updateStudyWidget(
        subjectName: '과목 없음',
        totalTime: '00:00:00',
        subjectColor: '#FF9800',
      );
    } else {
      final s = state.first;
      final colorHex =
          '#${s.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      WidgetService.updateStudyWidget(
        subjectName: s.name,
        totalTime: s.netSeconds.toTimeFormat(),
        subjectColor: colorHex,
      );
    }
  }

  Future<void> reorderSubjects(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final items = List<Subject>.from(state);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    state = [
      for (var i = 0; i < items.length; i++) items[i].copyWith(sortOrder: i),
    ];

    final uid = await _getUserId();
    final batch = _db.batch();
    for (var i = 0; i < state.length; i++) {
      batch.set(
        _userCol(uid, 'subjects').doc(state[i].id),
        {'sortOrder': i},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}

final subjectsProvider =
    NotifierProvider<SubjectsNotifier, List<Subject>>(SubjectsNotifier.new);

// ─── DailyStats ───────────────────────────────────────────────────────────────

class DailyStatsNotifier extends Notifier<Map<String, Map<String, int>>> {
  @override
  Map<String, Map<String, int>> build() {
    _load();
    return {};
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final uid = await _getUserId();
    final snap = await _userCol(uid, 'daily_stats').get();
    final loaded = <String, Map<String, int>>{};
    for (final doc in snap.docs) {
      final raw = doc.data()! as Map<String, dynamic>;
      loaded[doc.id] = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    state = loaded;
  }

  // 매초 호출 — 메모리만 수정
  void updateTime(String subjectId, int additionalSeconds) {
    if (subjectId.isEmpty) return; // 과목 없을 때 빈 키 저장 방지
    final key = _todayKey();
    final next = Map<String, Map<String, int>>.from(state);
    final today = Map<String, int>.from(next[key] ?? {});
    today[subjectId] = (today[subjectId] ?? 0) + additionalSeconds;
    next[key] = today;
    state = next;
  }

  // 모든 통계를 Firestore에 저장 (자정 넘김 안전 처리)
  Future<void> saveCurrentState() async {
    final uid = await _getUserId();
    final batch = _db.batch();

    for (final entry in state.entries) {
      // 빈 키 필드 제거 후 저장 (안전 처리)
      final filtered = Map<String, int>.from(entry.value)
        ..removeWhere((k, v) => k.isEmpty);
      if (filtered.isNotEmpty) {
        batch.set(
          _userCol(uid, 'daily_stats').doc(entry.key),
          filtered,
        );
      }
    }

    await batch.commit();
  }
}

final dailyStatsProvider =
    NotifierProvider<DailyStatsNotifier, Map<String, Map<String, int>>>(
        DailyStatsNotifier.new);

// ─── Dday ────────────────────────────────────────────────────────────────────

class Dday {
  final String id;
  final String title;
  final DateTime date;
  final bool isFavorite;

  const Dday({
    required this.id,
    required this.title,
    required this.date,
    this.isFavorite = false,
  });

  Dday copyWith({String? title, DateTime? date, bool? isFavorite}) => Dday(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'date': Timestamp.fromDate(date),
        'isFavorite': isFavorite,
      };

  factory Dday.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Dday(
      id: d['id'] as String? ?? doc.id,
      title: d['title'] as String,
      date: (d['date'] as Timestamp).toDate(),
      isFavorite: d['isFavorite'] == true,
    );
  }
}

class DdaysNotifier extends Notifier<List<Dday>> {
  @override
  List<Dday> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final uid = await _getUserId();
    final snap = await _userCol(uid, 'ddays').get();
    state = snap.docs.map(Dday.fromFirestore).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> addDday(String title, DateTime date) async {
    final uid = await _getUserId();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dday = Dday(id: id, title: title, date: date);
    state = [...state, dday]..sort((a, b) => a.date.compareTo(b.date));
    await _userCol(uid, 'ddays').doc(id).set(dday.toFirestore());
  }

  Future<void> updateDday(String id, String title, DateTime date) async {
    final uid = await _getUserId();
    state = state
        .map((d) => d.id == id ? d.copyWith(title: title, date: date) : d)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    await _userCol(uid, 'ddays').doc(id).set(
      {'title': title, 'date': Timestamp.fromDate(date)},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteDday(String id) async {
    final uid = await _getUserId();
    state = state.where((d) => d.id != id).toList();
    await _userCol(uid, 'ddays').doc(id).delete();
  }

  Future<void> toggleFavorite(String id) async {
    final uid = await _getUserId();
    final current = state.firstWhere((d) => d.id == id).isFavorite;
    state = state
        .map((d) => d.id == id ? d.copyWith(isFavorite: !current) : d)
        .toList();
    await _userCol(uid, 'ddays').doc(id).set(
      {'isFavorite': !current},
      SetOptions(merge: true),
    );
    _syncDdayWidget();
  }

  void _syncDdayWidget() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final favorites = state.where((d) => d.isFavorite).map((d) {
      final target = DateTime(d.date.year, d.date.month, d.date.day);
      final diff = target.difference(today).inDays;
      final ddayText = diff > 0
          ? 'D-$diff'
          : diff == 0
              ? 'D-Day'
              : 'D+${-diff}';
      return {'title': d.title, 'dday': ddayText};
    }).toList();
    WidgetService.updateDdayWidget(favorites);
  }
}

final ddaysProvider =
    NotifierProvider<DdaysNotifier, List<Dday>>(DdaysNotifier.new);

// ─── SavedTimer ───────────────────────────────────────────────────────────────

class SavedTimer {
  final String id;
  final String title;
  final int seconds;
  final int sortOrder;

  const SavedTimer({
    required this.id,
    required this.title,
    required this.seconds,
    this.sortOrder = 0,
  });

  SavedTimer copyWith({String? title, int? seconds, int? sortOrder}) => SavedTimer(
        id: id,
        title: title ?? this.title,
        seconds: seconds ?? this.seconds,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'seconds': seconds,
        'sortOrder': sortOrder,
      };

  factory SavedTimer.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return SavedTimer(
      id: d['id'] as String? ?? doc.id,
      title: d['title'] as String,
      seconds: d['seconds'] as int,
      sortOrder: (d['sortOrder'] as int?) ?? 0,
    );
  }
}

class SavedTimersNotifier extends Notifier<List<SavedTimer>> {
  @override
  List<SavedTimer> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final uid = await _getUserId();
    final snap = await _userCol(uid, 'saved_timers').orderBy('sortOrder').get();
    state = snap.docs.map(SavedTimer.fromFirestore).toList();
  }

  Future<void> addTimer(String title, int seconds) async {
    final uid = await _getUserId();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final timer = SavedTimer(id: id, title: title, seconds: seconds, sortOrder: state.length);
    state = [...state, timer];
    await _userCol(uid, 'saved_timers').doc(id).set(timer.toFirestore());
  }

  Future<void> updateTimer(String id, String title, int seconds) async {
    final uid = await _getUserId();
    state = state
        .map((t) => t.id == id ? t.copyWith(title: title, seconds: seconds) : t)
        .toList();
    await _userCol(uid, 'saved_timers').doc(id).set(
      {'title': title, 'seconds': seconds},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteTimer(String id) async {
    final uid = await _getUserId();
    state = state.where((t) => t.id != id).toList();
    await _userCol(uid, 'saved_timers').doc(id).delete();
  }

  Future<void> reorderTimers(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final items = List<SavedTimer>.from(state);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    state = [
      for (var i = 0; i < items.length; i++) items[i].copyWith(sortOrder: i),
    ];

    final uid = await _getUserId();
    final batch = _db.batch();
    for (var i = 0; i < state.length; i++) {
      batch.set(
        _userCol(uid, 'saved_timers').doc(state[i].id),
        {'sortOrder': i},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}

final savedTimersProvider =
    NotifierProvider<SavedTimersNotifier, List<SavedTimer>>(
        SavedTimersNotifier.new);

// ─── DarkMode (기기별 설정이므로 SharedPreferences 유지) ─────────────────────

class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isDarkMode') ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }
}

final isDarkModeProvider =
    NotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);
