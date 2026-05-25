import 'dart:convert';
import 'package:flutter/services.dart';

/// iOS/Android 홈 위젯 데이터 전달 및 위젯 탭 네비게이션 서비스
class WidgetService {
  static const _channel = MethodChannel('com.hamstudy/widget');

  /// 공부시간 위젯 데이터 업데이트
  static Future<void> updateStudyWidget({
    required String subjectName,
    required String totalTime,
    required String subjectColor,
  }) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'widget_subjectName': subjectName,
        'widget_totalTime': totalTime,
        'widget_subjectColor': subjectColor,
      });
    } catch (_) {}
  }

  /// 즐겨찾기 디데이 위젯 데이터 업데이트
  static Future<void> updateDdayWidget(
      List<Map<String, String>> ddayList) async {
    try {
      final json = jsonEncode(ddayList);
      await _channel.invokeMethod('updateWidget', {
        'widget_ddayList': json,
      });
    } catch (_) {}
  }

  /// 앱 시작 시 위젯 클릭으로 열렸는지 확인 (콜드 스타트)
  /// 반환값: 이동할 탭 인덱스 (null = 위젯 클릭 아님)
  static Future<int?> getInitialTab() async {
    try {
      final tab = await _channel.invokeMethod<int>('getInitialTab');
      return tab;
    } catch (_) {
      return null;
    }
  }

  /// 위젯 클릭으로 탭 이동 명령 수신 리스너 등록 (앱 실행 중일 때)
  static void listenForNavigation(void Function(int tab) onNavigate) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'navigateToTab') {
        final tab = call.arguments as int?;
        if (tab != null) onNavigate(tab);
      }
    });
  }
}
