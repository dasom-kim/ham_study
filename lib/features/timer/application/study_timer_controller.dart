import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/value_objects/timer_status.dart';
import '../domain/pause_reason.dart';
import '../domain/study_timer_state.dart';

final studyTimerControllerProvider =
    NotifierProvider<StudyTimerController, StudyTimerState>(
  StudyTimerController.new,
);

class StudyTimerController extends Notifier<StudyTimerState> {
  @override
  StudyTimerState build() => const StudyTimerState.initial();

  void start({required String subjectId}) {
    state = StudyTimerState(
      status: TimerStatus.studying,
      startedAt: DateTime.now(),
      accumulatedPausedDuration: Duration.zero,
      currentPauseStartedAt: null,
      pauseReason: null,
      selectedSubjectId: subjectId,
    );
  }

  void pause(PauseReason reason) {
    if (state.status != TimerStatus.studying) {
      return;
    }

    state = state.copyWith(
      status: TimerStatus.paused,
      currentPauseStartedAt: DateTime.now(),
      pauseReason: reason,
    );
  }

  void resume() {
    if (state.status != TimerStatus.paused) {
      return;
    }

    final pauseStartedAt = state.currentPauseStartedAt;
    final addedPause = pauseStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(pauseStartedAt);

    state = state.copyWith(
      status: TimerStatus.studying,
      accumulatedPausedDuration: state.accumulatedPausedDuration + addedPause,
      clearPause: true,
    );
  }

  void finish() {
    state = state.copyWith(
      status: TimerStatus.finished,
      clearPause: true,
    );
  }

  void reset() {
    state = const StudyTimerState.initial();
  }
}
