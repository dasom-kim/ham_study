import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/timer/presentation/dday_screen.dart';
import '../features/timer/presentation/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/timer/presentation/timer_screen.dart';
import 'study_provider.dart';
import 'widget_service.dart';

class HamStudyApp extends ConsumerWidget {
  const HamStudyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'HamStudy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _HamStudyMainScreen(),
    );
  }
}

class _HamStudyMainScreen extends StatefulWidget {
  const _HamStudyMainScreen();

  @override
  State<_HamStudyMainScreen> createState() => _HamStudyMainScreenState();
}

class _HamStudyMainScreenState extends State<_HamStudyMainScreen> {
  int _currentIndex = 0; // 하단바 탭 인덱스

  @override
  void initState() {
    super.initState();
    _initWidgetNavigation();
  }

  /// 위젯 클릭으로 앱 진입 시 해당 탭으로 이동
  Future<void> _initWidgetNavigation() async {
    // 콜드 스타트: 위젯 클릭으로 앱이 새로 열렸을 때
    final tab = await WidgetService.getInitialTab();
    if (tab != null && mounted) {
      setState(() => _currentIndex = tab);
    }

    // 핫 스타트: 앱이 이미 실행 중일 때 위젯 클릭
    WidgetService.listenForNavigation((tab) {
      if (mounted) setState(() => _currentIndex = tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimerScreen(),
          DdayScreen(),
          StatisticsScreen(), // 만들어둔 통계 화면 위젯 연동
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: '타이머'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: '디데이'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
