import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // iOS CocoaPods 호환성 문제로 임시 제거
// import 'package:live_activities/live_activities.dart';  // iOS CocoaPods 호환성 문제로 임시 제거
// import 'package:home_widget/home_widget.dart';  // 나중에 사용할 수 있으니 임시 주석 처리

import '../../../app/study_provider.dart';
import '../../../app/widget_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isStudying = false;
  String _characterState = '기본';

  Timer? _timer;
  String? _currentSubjectId;
  DateTime? _pauseStartTime; // 일시정지 시작 시각
  String? _pauseReason;      // 일시정지 이유
  DateTime? _backgroundTime;
  bool _isTimerMode = false;
  bool _isCountdownRunning = false;
  bool _isCountdownPaused = false;
  int _countdownSeconds = 0; // 기본 0초 (00:00:00)
  int _timerSelectionCount = 0;

  // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();  // iOS CocoaPods 호환성 문제로 임시 제거
  // final LiveActivities _liveActivitiesPlugin = LiveActivities();  // iOS CocoaPods 호환성 문제로 임시 제거
  // String? _activityId;  // iOS CocoaPods 호환성 문제로 임시 제거

  late final AnimationController _breatheController;
  late final Animation<Offset> _breatheAnimation;
  late final AnimationController _particleController;

  late FixedExtentScrollController _hController;
  late FixedExtentScrollController _mController;
  late FixedExtentScrollController _sController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 감지기 등록
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.04), // 위로 살짝 올라가며 숨을 들이쉬는 효과
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOutSine,
    ),);

    _hController =
        FixedExtentScrollController(initialItem: _countdownSeconds ~/ 3600);
    _mController = FixedExtentScrollController(
        initialItem: (_countdownSeconds % 3600) ~/ 60,);
    _sController =
        FixedExtentScrollController(initialItem: _countdownSeconds % 60);

    _restoreState(); // 앱 시작 시 강제 종료 전 상태 복구
    _initNotifications();
    _initLiveActivities();
    // _initHomeWidget();  // 나중에 사용할 수 있으니 임시 주석 처리
  }

  void _initLiveActivities() {
    // iOS CocoaPods 호환성 문제로 임시 제거
  }

  // 홈 위젯에 현재 공부 상태를 전달하는 함수
  Future<void> _updateStudyWidget() async {
    final subjects = ref.read(subjectsProvider);
    final activeId = _getActiveId(subjects);
    final currentSubject = subjects.firstWhere((e) => e.id == activeId);
    final colorHex =
        '#${currentSubject.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    await WidgetService.updateStudyWidget(
      subjectName: currentSubject.name,
      totalTime: currentSubject.netSeconds.toTimeFormat(),
      subjectColor: colorHex,
    );
  }

  Future<void> _initNotifications() async {
    // flutter_local_notifications는 iOS CocoaPods 호환성 문제로 임시 제거됨
    // 나중에 업데이트 후 다시 활성화 가능
  }

  Future<void> _updateNotification(bool isPlaying) async {
    // flutter_local_notifications는 iOS CocoaPods 호환성 문제로 임시 제거됨
    // 나중에 업데이트 후 다시 활성화 가능
  }

  // 앱이 강제 종료되었을 때를 대비해 저장해둔 타이머 상태를 복구하는 함수
  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final wasStudying = prefs.getBool('was_studying') ?? false;
    final lastBgTime = prefs.getInt('last_bg_time');
    final bgSubjectId = prefs.getString('bg_subject_id');
    final wasTimerMode = prefs.getBool('was_timer_mode') ?? false;
    final bgCountdown = prefs.getInt('bg_countdown') ?? 0;
    final wasCountdownRunning = prefs.getBool('was_countdown_running') ?? false;
    final wasCountdownPaused = prefs.getBool('was_countdown_paused') ?? false;

    setState(() {
      _isTimerMode = wasTimerMode;
      _isCountdownRunning = wasCountdownRunning;
      _isCountdownPaused = wasCountdownPaused;
    });
    _setCountdown(bgCountdown);

    if ((wasStudying || wasCountdownRunning) &&
        lastBgTime != null &&
        bgSubjectId != null) {
      final missedSeconds = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastBgTime))
          .inSeconds;
      if (missedSeconds > 0) {
        if (wasStudying) {
          ref
              .read(subjectsProvider.notifier)
              .updateTime(bgSubjectId, missedSeconds);
        }
        if (_isCountdownRunning) {
          _countdownSeconds -= missedSeconds;
          if (_countdownSeconds <= 0) {
            _setCountdown(0);
            _isCountdownRunning = false;
            _isCountdownPaused = false;
          }
        }
      }

      setState(() {
        if (wasStudying) {
          _isStudying = true;
          _characterState = '기본';
          _currentSubjectId = bgSubjectId;
        }
      });
      if (wasStudying) {
        _breatheController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut,);
      }
      _startPeriodicTimer();
    }

    // 복구 후 임시 저장 데이터 삭제
    prefs.remove('was_studying');
    prefs.remove('last_bg_time');
    prefs.remove('bg_subject_id');
    prefs.remove('was_timer_mode');
    prefs.remove('bg_countdown');
    prefs.remove('was_countdown_running');
    prefs.remove('was_countdown_paused');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 앱 상태 감지기 해제
    _particleController.dispose();
    _timer?.cancel();
    _breatheController.dispose();
    _hController.dispose();
    _mController.dispose();
    _sController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // 앱이 백그라운드로 내려가거나 화면이 꺼질 때
      if (_backgroundTime == null) {
        _backgroundTime = DateTime.now(); // 시간 기록
        _timer?.cancel(); // 불필요한 백그라운드 타이머 작동 중지 (배터리 절약)
        _timer = null;

        // 강제 종료에 대비해 로컬 DB에 현재 상태를 실시간 임시 저장
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('was_studying', _isStudying);
          prefs.setInt('last_bg_time', _backgroundTime!.millisecondsSinceEpoch);
          prefs.setString('bg_subject_id', _activeSubjectId);
          prefs.setBool('was_timer_mode', _isTimerMode);
          prefs.setInt('bg_countdown', _countdownSeconds);
          prefs.setBool('was_countdown_running', _isCountdownRunning);
          prefs.setBool('was_countdown_paused', _isCountdownPaused);
        });

        ref
            .read(subjectsProvider.notifier)
            .saveCurrentState(); // 백그라운드 전환 시 DB 저장
      }
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 올라올 때
      if (_backgroundTime != null && (_isStudying || _isCountdownRunning)) {
        // 백그라운드에 머물렀던 '실제 흐른 시간' 계산
        final missedSeconds =
            DateTime.now().difference(_backgroundTime!).inSeconds;
        if (missedSeconds > 0) {
          if (_isStudying) {
            ref
                .read(subjectsProvider.notifier)
                .updateTime(_activeSubjectId, missedSeconds);
          }
          if (_isCountdownRunning) {
            setState(() {
              _countdownSeconds -= missedSeconds;
              if (_countdownSeconds <= 0) {
                _setCountdown(0);
                _isCountdownRunning = false;
                _isCountdownPaused = false;
                _updateNotification(true);
              }
            });
          }
        }
        if (_isStudying || _isCountdownRunning) {
          _startPeriodicTimer(); // 화면에 돌아왔으므로 타이머 재시작
        }
      }
      _backgroundTime = null;

      // 화면에 정상 복귀 시 임시 저장된 데이터 삭제
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('was_studying');
        prefs.remove('last_bg_time');
        prefs.remove('bg_subject_id');
        prefs.remove('was_timer_mode');
        prefs.remove('bg_countdown');
        prefs.remove('was_countdown_running');
        prefs.remove('was_countdown_paused');
      });
    }
  }

  Widget _buildHamsterCharacter() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String imagePath = 'assets/images/ham_pure.png';
    String description = '대기 중';

    if (_isStudying) {
      imagePath = 'assets/images/ham_study.png';
      description = '열심히 공부 중!';
    } else {
      switch (_characterState) {
        case '밥':
          imagePath = 'assets/images/ham_meal.png';
          description = '든든하게 배 채우는 중...';
        case '커피':
          imagePath = 'assets/images/ham_coffee.png';
          description = '에스프레소 수혈 중...';
        case '화장실':
          imagePath = 'assets/images/ham_toilet.png';
          description = '안절부절 못하는 중...';
        case '딴짓':
          imagePath = 'assets/images/ham_phone.png';
          description = 'SNS 뒹굴뒹굴...';
        case '휴식':
          imagePath = 'assets/images/ham_sleep.png';
          description = '꿀잠 자는 중...';
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, width: 120, height: 120),
        const SizedBox(height: 16),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerHamsterCharacter() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String imagePath = 'assets/images/ham_pure.png';
    String description = '타이머 설정 중';

    if (_isCountdownRunning) {
      imagePath = 'assets/images/ham_timer.png';
      description = '타이머 집중 중!';
    } else if (_isCountdownPaused) {
      imagePath = 'assets/images/ham_pause.png';
      description = '타이머 일시정지';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, width: 120, height: 120),
        const SizedBox(height: 16),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  void _pauseCountdown() {
    HapticFeedback.lightImpact();
    _setCountdown(_countdownSeconds); // 휠 UI 값을 현재 멈춘 시간으로 동기화
    setState(() {
      _isCountdownRunning = false;
      _isCountdownPaused = true;
    });
    if (!_isStudying) {
      _timer?.cancel();
      _timer = null;
    }
    _updateNotification(true);
  }

  void _stopCountdown() {
    HapticFeedback.mediumImpact();
    _setCountdown(0);
    setState(() {
      _isCountdownRunning = false;
      _isCountdownPaused = false;
    });
    if (!_isStudying) {
      _timer?.cancel();
      _timer = null;
    }
    _updateNotification(true);
    // _updateHomeWidget(); // 정지 시 위젯 업데이트 (나중에 사용할 수 있으니 임시 주석 처리)
  }

  void _pauseTimer(String reason) {
    HapticFeedback.lightImpact();
    setState(() {
      _isStudying = false;
      _characterState = reason;
    });
    // 일시정지 시작 시각 기록
    _pauseStartTime = DateTime.now();
    _pauseReason = reason;
    if (!_isCountdownRunning) {
      _timer?.cancel(); // 일시정지 시 타이머 확실히 제거
      _timer = null;
    }
    _breatheController.repeat(reverse: true); // 일시정지 시 호흡 애니메이션 재개
    _updateNotification(false);
    _stopLiveActivity();
    ref.read(subjectsProvider.notifier).saveCurrentState(); // 일시정지 시 DB 저장
    // _updateHomeWidget(); // 일시정지 시 위젯 업데이트 (나중에 사용할 수 있으니 임시 주석 처리)
  }

  /// 일시정지 시간을 계산해 저장하고 초기화
  void _flushPauseTime() {
    if (_pauseStartTime == null || _pauseReason == null) return;
    final elapsed = DateTime.now().difference(_pauseStartTime!).inSeconds;
    if (elapsed > 0) {
      ref.read(dailyPauseStatsProvider.notifier).updateTime(_pauseReason!, elapsed);
      ref.read(dailyPauseStatsProvider.notifier).saveCurrentState();
    }
    _pauseStartTime = null;
    _pauseReason = null;
  }

  void _startTimer() {
    if (_isTimerMode && _countdownSeconds <= 0) return; // 시간이 0이면 시작 방지

    if (_isTimerMode && _countdownSeconds > 12 * 3600) {
      _setCountdown(12 * 3600);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('타이머는 최대 12시간까지만 작동합니다.')),
      );
    }

    // 일시정지 상태에서 재개할 때 휴식 시간 저장
    _flushPauseTime();

    HapticFeedback.mediumImpact();
    setState(() {
      if (_isTimerMode) {
        _isCountdownRunning = true;
        _isCountdownPaused = false;
      } else {
        _isStudying = true;
        _characterState = '기본';
      }
    });
    if (!_isTimerMode) {
      _breatheController.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,); // 공부 시작 시 원래 위치로 부드럽게 복귀
    }

    _startPeriodicTimer();
    _updateNotification(true);
    _startLiveActivity();
    _updateStudyWidget();
  }

  void _startPeriodicTimer() {
    // 타이머가 없을 때만 새로 생성 (중복 실행 방지)
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isStudying) {
        ref.read(subjectsProvider.notifier).updateTime(_activeSubjectId, 1);
        // 60초마다 위젯 업데이트
        if (timer.tick % 60 == 0) _updateStudyWidget();
      }
      if (_isCountdownRunning) {
        setState(() {
          if (_countdownSeconds > 0) _countdownSeconds--;
          if (_countdownSeconds <= 0) {
            _setCountdown(0);
            _isCountdownRunning = false;
            _isCountdownPaused = false;
            _updateNotification(true);
          }
        });
      }
      if (!_isStudying && !_isCountdownRunning) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  Future<void> _startLiveActivity() async {
    // iOS CocoaPods 호환성 문제로 임시 제거
  }

  Future<void> _stopLiveActivity() async {
    // iOS CocoaPods 호환성 문제로 임시 제거
  }

  // 현재 활성화된 과목 ID 반환 (선택된 ID가 지워졌거나 없으면 리스트 첫번째 반환)
  String get _activeSubjectId {
    final subjects = ref.read(subjectsProvider);
    return _getActiveId(subjects);
  }

  // 상태(subjects)를 기반으로 활성화된 과목 ID 도출 (select 내부 용도)
  String _getActiveId(List<Subject> subjects) {
    if (subjects.isEmpty) return '';
    if (_currentSubjectId == null ||
        !subjects.any((s) => s.id == _currentSubjectId)) {
      return subjects.first.id;
    }
    return _currentSubjectId!;
  }

  // 과목 선택 바텀 시트 호출
  void _showSubjectSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              final subjects = ref.watch(subjectsProvider);
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('과목 선택',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16,),),
                  ),
                  Flexible(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(subjectsProvider.notifier)
                            .reorderSubjects(oldIndex, newIndex);
                      },
                      children: subjects.map((subject) {
                        final isActive = _activeSubjectId == subject.id;
                        return ListTile(
                          key: ValueKey(subject.id),
                          leading: CircleAvatar(
                            backgroundColor:
                                subject.color.withValues(alpha: 0.2),
                            child: Icon(Icons.circle,
                                color: subject.color, size: 16,),
                          ),
                          title: Text(subject.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isActive)
                                Icon(Icons.check,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,),
                              if (isActive) const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 20, color: Colors.grey,),
                                onPressed: () => _showSubjectDialog(subject),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _currentSubjectId = subject.id;
                            });
                            Navigator.pop(context); // 시트 닫기
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.grey),
                    title: const Text('새 과목 추가하기',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey,),),
                    onTap: () => _showSubjectDialog(null),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _setCountdown(int seconds) {
    final oldH = _hController;
    final oldM = _mController;
    final oldS = _sController;

    _hController = FixedExtentScrollController(initialItem: seconds ~/ 3600);
    _mController =
        FixedExtentScrollController(initialItem: (seconds % 3600) ~/ 60);
    _sController = FixedExtentScrollController(initialItem: seconds % 60);

    setState(() {
      _countdownSeconds = seconds;
      _timerSelectionCount++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldH.dispose();
      oldM.dispose();
      oldS.dispose();
    });
  }

  void _showTimerSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      builder: (context) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              final savedTimers = ref.watch(savedTimersProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('타이머 선택',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16,),),),
                  Flexible(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(savedTimersProvider.notifier)
                            .reorderTimers(oldIndex, newIndex);
                      },
                      children: savedTimers
                          .map((timer) => ListTile(
                                key: ValueKey(timer.id),
                                leading: const Icon(Icons.bookmark,
                                    color: Colors.amber,),
                                title: Text(timer.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,),),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(timer.seconds.toTimeFormat(),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,),),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20, color: Colors.grey,),
                                      onPressed: () {
                                        _showTimerEditDialog(timer: timer);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _isCountdownPaused = false;
                                  });
                                  _setCountdown(timer.seconds);
                                  Navigator.pop(context);
                                },
                              ),)
                          .toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.grey),
                    title: const Text('새 즐겨찾기 타이머 추가',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey,),),
                    onTap: () {
                      _showTimerEditDialog();
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showTimerEditDialog({SavedTimer? timer}) async {
    final titleController = TextEditingController(text: timer?.title ?? '');
    final hController = TextEditingController(
        text: timer != null ? (timer.seconds ~/ 3600).toString() : '0',);
    final mController = TextEditingController(
        text: timer != null ? ((timer.seconds % 3600) ~/ 60).toString() : '0',);
    final sController = TextEditingController(
        text: timer != null ? (timer.seconds % 60).toString() : '0',);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(timer == null ? '타이머 추가' : '타이머 수정',
              style: const TextStyle(fontWeight: FontWeight.bold),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: '타이머 이름 (예: 모의고사)'),),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: hController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '시'),),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                        controller: mController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '분'),),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                        controller: sController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '초'),),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (timer != null)
              TextButton(
                  onPressed: () {
                    ref
                        .read(savedTimersProvider.notifier)
                        .deleteTimer(timer.id);
                    Navigator.pop(context);
                  },
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),),
            FilledButton(
                onPressed: () {
                  final h = int.tryParse(hController.text) ?? 0;
                  final m = int.tryParse(mController.text) ?? 0;
                  final s = int.tryParse(sController.text) ?? 0;
                  final seconds = h * 3600 + m * 60 + s;

                  if (seconds > 12 * 3600) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('타이머는 최대 12시간까지만 설정할 수 있습니다.'),),
                    );
                    return;
                  }

                  if (seconds == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('시간을 설정해주세요.')),
                    );
                    return;
                  }

                  Navigator.pop(context,
                      {'title': titleController.text, 'seconds': seconds},);
                },
                child: const Text('확인'),),
          ],
        );
      },
    );

    if (result != null) {
      final seconds = result['seconds'] as int;
      final title = result['title'] as String;
      if (timer == null) {
        ref.read(savedTimersProvider.notifier).addTimer(title, seconds);
      } else {
        ref
            .read(savedTimersProvider.notifier)
            .updateTimer(timer.id, title, seconds);
      }
    }
  }

  // 스크롤 방식으로 타이머 설정하는 위젯
  Widget _buildScrollableTimer() {
    return SizedBox(
      height: 90,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTimeWheel(
              13, // 최대 12시간
              _hController,
              (val) => setState(() {
                    _countdownSeconds = val * 3600 + (_countdownSeconds % 3600);
                    _isCountdownPaused = false;
                  }),),
          const Text(':',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900),),
          _buildTimeWheel(
              60,
              _mController,
              (val) => setState(() {
                    _countdownSeconds = (_countdownSeconds ~/ 3600) * 3600 +
                        val * 60 +
                        (_countdownSeconds % 60);
                    _isCountdownPaused = false;
                  }),),
          const Text(':',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900),),
          _buildTimeWheel(
              60,
              _sController,
              (val) => setState(() {
                    _countdownSeconds = (_countdownSeconds ~/ 60) * 60 + val;
                    _isCountdownPaused = false;
                  }),),
        ],
      ),
    );
  }

  // 타이머 실행 중에 보여줄 고정형 스크롤 휠 위젯 (휠과 100% 동일한 렌더링 파이프라인 사용)
  Widget _buildStaticTimeWheel(String text) {
    return SizedBox(
      width: 90,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListWheelScrollView.useDelegate(
          itemExtent: 75,
          physics: const NeverScrollableScrollPhysics(), // 스크롤 잠금
          overAndUnderCenterOpacity: 0.3,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              return Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
            childCount: 1, // 단일 항목
          ),
        ),
      ),
    );
  }

  // 타이머 실행 중에 휠 스크롤 대신 보여줄 레이아웃 고정형 타이머
  Widget _buildStaticTimer() {
    return SizedBox(
      height: 90,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStaticTimeWheel(
              (_countdownSeconds ~/ 3600).toString().padLeft(2, '0'),),
          const Text(':',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900),),
          _buildStaticTimeWheel(
              ((_countdownSeconds % 3600) ~/ 60).toString().padLeft(2, '0'),),
          const Text(':',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900),),
          _buildStaticTimeWheel(
              (_countdownSeconds % 60).toString().padLeft(2, '0'),),
        ],
      ),
    );
  }

  Widget _buildTimeWheel(int max, FixedExtentScrollController controller,
      ValueChanged<int> onChanged,) {
    return SizedBox(
      width: 90,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListWheelScrollView.useDelegate(
          key: ValueKey('wheel_${max}_$_timerSelectionCount'),
          controller: controller,
          itemExtent: 75,
          physics: const FixedExtentScrollPhysics(),
          overAndUnderCenterOpacity: 0.3,
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              return Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
            childCount: max,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 과목이 비어있는지 여부만 구독 (타이머 진행과 무관)
    final isSubjectsEmpty =
        ref.watch(subjectsProvider.select((s) => s.isEmpty));
    final isDarkMode = ref.watch(isDarkModeProvider);

    if (isSubjectsEmpty) {
      return Scaffold(
        backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/ham_pure.png', width: 120, height: 120),
              const SizedBox(height: 24),
              const Text(
                '아직 등록된 과목이 없어요!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '첫 번째 과목을 추가하고 공부를 시작해볼까요?',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showSubjectDialog(null),
                icon: const Icon(Icons.add),
                label: const Text('새 과목 추가하기',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. 화면 전체 렌더링에 필요한 '색상'과 '이름'만 선택적 구독 (시간이 흘러도 재빌드 무시됨)
    final subjectColor = ref.watch(subjectsProvider
        .select((s) => s.firstWhere((e) => e.id == _getActiveId(s)).color),);
    final subjectName = ref.watch(subjectsProvider
        .select((s) => s.firstWhere((e) => e.id == _getActiveId(s)).name),);

    return Scaffold(
      backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Switch(
                              value: _isTimerMode,
                              onChanged: (v) {
                                setState(() {
                                  _isTimerMode = v;
                                });
                                if (!_isStudying && !_isCountdownRunning) {
                                  _timer?.cancel();
                                  _timer = null;
                                  _updateNotification(false);
                                } else {
                                  _updateNotification(true);
                                }
                              },
                              activeThumbColor: Colors.deepOrange,
                            ),
                            const SizedBox(width: 8),
                            if (_isTimerMode)
                              Consumer(
                                builder: (context, ref, child) {
                                  final subjects = ref.watch(subjectsProvider);
                                  final activeId = _getActiveId(subjects);
                                  final currentSubject = subjects
                                      .firstWhere((e) => e.id == activeId);
                                  final todaySeconds = ref.watch(
                                      todaySubjectSecondsProvider(activeId));

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4,),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle,
                                            color: currentSubject.color,
                                            size: 8,),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            currentSubject.name,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: currentSubject.color,),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 4,),
                                          decoration: BoxDecoration(
                                            color: currentSubject.color
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            todaySeconds.toTimeFormat(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            else if (_countdownSeconds > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4,),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isCountdownRunning
                                          ? Icons.timer
                                          : Icons.timer_off,
                                      color: isDarkMode
                                          ? Colors.orangeAccent
                                          : Colors.deepOrange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _countdownSeconds.toTimeFormat(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: isDarkMode
                                            ? Colors.orangeAccent
                                            : Colors.deepOrange,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 화면 중앙의 반응형 메인 영역
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 600), // 가로 최대 너비 제한
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Column(
                      children: [
                        // 1. 햄스터 캐릭터 영역 (가용 공간의 비율 유지하며 가장 크게 표시)
                        Expanded(
                          flex: 10,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 320,
                                maxHeight: 320,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.0, // 항상 완벽한 원형 유지
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isTimerMode
                                            ? (_isCountdownRunning
                                                ? Colors.orange
                                                    .withValues(alpha: 0.15)
                                                : Colors.grey
                                                    .withValues(alpha: 0.1))
                                            : (_isStudying
                                                ? subjectColor.withValues(
                                                    alpha: 0.15,)
                                                : Colors.grey
                                                    .withValues(alpha: 0.1)),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: SlideTransition(
                                        position: _breatheAnimation,
                                        child: _isTimerMode
                                            ? _buildTimerHamsterCharacter()
                                            : _buildHamsterCharacter(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                        // 2. 과목 선택 영역 (타이머 모드일 때는 숨김)
                        if (!_isTimerMode) ...[
                          Flexible(
                            flex: 2,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: GestureDetector(
                                onTap: _showSubjectSelector, // 공부 중에도 전환 가능
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8,),
                                  decoration: BoxDecoration(
                                    color: subjectColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle,
                                          color: subjectColor, size: 12,),
                                      const SizedBox(width: 8),
                                      Text(
                                        subjectName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: subjectColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down,
                                          color: subjectColor, size: 16,),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                        // 3. 타이머 텍스트
                        Flexible(
                          flex: 4,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final subjects = ref.watch(subjectsProvider);
                              final activeId = _getActiveId(subjects);
                              final todaySeconds = ref.watch(
                                  todaySubjectSecondsProvider(activeId));
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _isTimerMode
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isCountdownRunning)
                                            _buildStaticTimer()
                                          else
                                            _buildScrollableTimer(),
                                          if (!_isCountdownRunning) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: _showTimerSelectionSheet,
                                              child: const Icon(
                                                  Icons.arrow_drop_down_circle,
                                                  color: Colors.grey,
                                                  size: 32,),
                                            ),
                                          ],
                                        ],
                                      )
                                    : Text(
                                        todaySeconds.toTimeFormat(),
                                        style: const TextStyle(
                                          fontSize: 80,
                                          fontWeight: FontWeight.w900,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const Spacer(flex: 1),
                        // 4. 하단 버튼 영역
                        Flexible(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _isTimerMode
                                ? SizedBox(
                                    width: 320,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isCountdownRunning
                                                ? _pauseCountdown
                                                : _startTimer,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _isCountdownRunning
                                                      ? Colors.orange
                                                      : subjectColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20,),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              elevation: 4,
                                            ),
                                            child: Icon(
                                              _isCountdownRunning
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 38,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (_countdownSeconds > 0 ||
                                            _isCountdownRunning) ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _stopCountdown,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.redAccent,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20,),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                                elevation: 4,
                                              ),
                                              child: const Icon(
                                                Icons.stop,
                                                size: 38,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : (_isStudying
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildPauseButton('밥', '🍚', Colors.orange),
                                          const SizedBox(width: 16),
                                          _buildPauseButton('커피', '☕', Colors.brown),
                                          const SizedBox(width: 16),
                                          _buildPauseButton('화장실', '🚽', Colors.blueGrey),
                                          const SizedBox(width: 16),
                                          _buildPauseButton('딴짓', '📱', Colors.purple),
                                          const SizedBox(width: 16),
                                          _buildPauseButton('휴식', '😴', Colors.indigo),
                                        ],
                                      )
                                    : SizedBox(
                                        width: 320,
                                        child: ElevatedButton(
                                          onPressed: _startTimer,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: subjectColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20,),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: const Text(
                                            '공부 시작하기',
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,),
                                          ),
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseButton(String reason, String emoji, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _pauseTimer(reason),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }

  Future<void> _showSubjectDialog(Subject? subject) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SubjectEditDialog(subject: subject),
    );

    if (result != null) {
      final name = result['name'] as String;
      final color = result['color'] as Color;

      if (subject == null) {
        ref.read(subjectsProvider.notifier).addSubject(name, color);
      } else {
        ref
            .read(subjectsProvider.notifier)
            .updateSubject(subject.id, name, color);
      }
    }
  }
}

class _SubjectEditDialog extends StatefulWidget {
  final Subject? subject;
  const _SubjectEditDialog({this.subject});

  @override
  State<_SubjectEditDialog> createState() => _SubjectEditDialogState();
}

class _SubjectEditDialogState extends State<_SubjectEditDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _selectedColor = widget.subject?.color ?? Colors.deepOrangeAccent;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(widget.subject == null ? '과목 추가' : '과목 수정',
          style: const TextStyle(fontWeight: FontWeight.bold),),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '과목 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('색상 선택', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _SimpleColorPicker(
              initialColor: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.subject != null)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제하시겠습니까?'),
                  content: const Text('기록된 타이머 시간이 모두 사라집니다.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소'),),
                    Consumer(builder: (context, ref, child) {
                      return TextButton(
                        onPressed: () {
                          ref
                              .read(subjectsProvider.notifier)
                              .deleteSubject(widget.subject!.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('삭제',
                            style: TextStyle(color: Colors.red),),
                      );
                    },),
                  ],
                ),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소'),),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.pop(context,
                {'name': _nameController.text.trim(), 'color': _selectedColor},);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

// 의존성 패키지 없이 직접 구현한 예쁜 커스텀 컬러 피커 (HSV 기반)
class _SimpleColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const _SimpleColorPicker(
      {required this.initialColor, required this.onColorChanged,});

  @override
  State<_SimpleColorPicker> createState() => _SimpleColorPickerState();
}

class _SimpleColorPickerState extends State<_SimpleColorPicker> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  @override
  Widget build(BuildContext context) {
    final currentColor =
        HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    final textColor = _value < 0.6 || _saturation > 0.7 && _value < 0.8
        ? Colors.white
        : Colors.black87;

    return Column(
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text('색상 미리보기',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,),),
          ),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          value: _hue,
          min: 0,
          max: 360,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
          onChanged: (v) {
            setState(() => _hue = v);
            widget.onColorChanged(
                HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),);
          },
        ),
        const SizedBox(height: 12),
        _buildSlider(
          value: _saturation,
          min: 0,
          max: 1,
          gradient: LinearGradient(
            colors: [
              HSVColor.fromAHSV(1.0, _hue, 0.0, _value).toColor(),
              HSVColor.fromAHSV(1.0, _hue, 1.0, _value).toColor(),
            ],
          ),
          onChanged: (v) {
            setState(() => _saturation = v);
            widget.onColorChanged(
                HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),);
          },
        ),
        const SizedBox(height: 12),
        _buildSlider(
          value: _value,
          min: 0,
          max: 1,
          gradient: LinearGradient(
            colors: [
              Colors.black,
              HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
            ],
          ),
          onChanged: (v) {
            setState(() => _value = v);
            widget.onColorChanged(
                HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),);
          },
        ),
      ],
    );
  }

  Widget _buildSlider(
      {required double value,
      required double min,
      required double max,
      required Gradient gradient,
      required ValueChanged<double> onChanged,}) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.white,
          overlayColor: Colors.white.withValues(alpha: 0.3),
          trackHeight: 36,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    );
  }
}