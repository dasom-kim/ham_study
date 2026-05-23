import 'package:flutter/material.dart';

import '../../../shared/domain/value_objects/timer_status.dart';
import '../../timer/domain/pause_reason.dart';
import '../../timer/domain/study_timer_state.dart';

class HamsterStatusCard extends StatelessWidget {
  const HamsterStatusCard({
    required this.timerState,
    super.key,
  });

  final StudyTimerState timerState;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (timerState.status) {
      TimerStatus.idle => '오늘도 해바라기씨처럼 차곡차곡',
      TimerStatus.studying => '돋보기를 들고 열공 중',
      TimerStatus.paused => '${timerState.pauseReason?.label ?? '휴식'} 중',
      TimerStatus.finished => '오늘 기록 저장 완료',
    };

    final hamster = switch (timerState.status) {
      TimerStatus.idle => '🐹',
      TimerStatus.studying => '🔎🐹📖',
      TimerStatus.paused => '${timerState.pauseReason?.icon ?? '💤'}🐹',
      TimerStatus.finished => '🎓🐹',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(hamster, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
