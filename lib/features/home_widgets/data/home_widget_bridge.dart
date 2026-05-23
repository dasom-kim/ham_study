import '../../timer/domain/pause_reason.dart';

abstract interface class HomeWidgetBridge {
  Future<void> updateTodayStudyWidget();
  Future<void> updateTimerControlWidget();
  Future<void> updateDdayWidget();
  Future<void> handlePauseIntent(PauseReason reason);
}
