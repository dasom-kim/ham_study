import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../dday/application/dday_provider.dart';
import '../../subjects/application/subjects_provider.dart';
import '../../timer/application/study_timer_controller.dart';
import '../../timer/domain/pause_reason.dart';
import '../widgets/hamster_status_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final dday = ref.watch(mainDdayProvider);
    final timerState = ref.watch(studyTimerControllerProvider);
    final timerController = ref.read(studyTimerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: '통계',
            onPressed: () => context.go('/statistics'),
            icon: const Icon(Icons.donut_large_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HamsterStatusCard(timerState: timerState),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dday.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'D-${dday.daysLeft(DateTime.now())}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('과목', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subject in subjects)
                ActionChip(
                  avatar: CircleAvatar(backgroundColor: subject.color),
                  label: Text(subject.name),
                  onPressed: () {
                    timerController.start(subjectId: subject.id);
                    context.go('/timer');
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/timer'),
            icon: const Icon(Icons.timer_rounded),
            label: const Text('타이머 열기'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in PauseReason.values)
                OutlinedButton(
                  onPressed: () => timerController.pause(reason),
                  child: Text('${reason.icon} ${reason.label}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
