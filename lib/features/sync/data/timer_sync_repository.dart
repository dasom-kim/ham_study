import '../../timer/domain/study_timer_state.dart';

abstract interface class TimerSyncRepository {
  Future<void> pushTimerState(StudyTimerState state);
  Stream<StudyTimerState> watchTimerState();
}
