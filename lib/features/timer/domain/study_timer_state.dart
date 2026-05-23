import '../../../shared/domain/value_objects/timer_status.dart';
import 'pause_reason.dart';

class StudyTimerState {
  const StudyTimerState({
    required this.status,
    required this.startedAt,
    required this.accumulatedPausedDuration,
    required this.currentPauseStartedAt,
    required this.pauseReason,
    required this.selectedSubjectId,
  });

  const StudyTimerState.initial()
      : status = TimerStatus.idle,
        startedAt = null,
        accumulatedPausedDuration = Duration.zero,
        currentPauseStartedAt = null,
        pauseReason = null,
        selectedSubjectId = null;

  final TimerStatus status;
  final DateTime? startedAt;
  final Duration accumulatedPausedDuration;
  final DateTime? currentPauseStartedAt;
  final PauseReason? pauseReason;
  final String? selectedSubjectId;

  Duration netStudyDuration(DateTime now) {
    final start = startedAt;
    if (start == null) {
      return Duration.zero;
    }

    final gross = now.difference(start);
    final activePause = currentPauseStartedAt == null
        ? Duration.zero
        : now.difference(currentPauseStartedAt!);
    final net = gross - accumulatedPausedDuration - activePause;
    return net.isNegative ? Duration.zero : net;
  }

  StudyTimerState copyWith({
    TimerStatus? status,
    DateTime? startedAt,
    Duration? accumulatedPausedDuration,
    DateTime? currentPauseStartedAt,
    PauseReason? pauseReason,
    String? selectedSubjectId,
    bool clearPause = false,
    bool clearStartedAt = false,
  }) {
    return StudyTimerState(
      status: status ?? this.status,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      accumulatedPausedDuration:
          accumulatedPausedDuration ?? this.accumulatedPausedDuration,
      currentPauseStartedAt:
          clearPause ? null : currentPauseStartedAt ?? this.currentPauseStartedAt,
      pauseReason: clearPause ? null : pauseReason ?? this.pauseReason,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
    );
  }
}
