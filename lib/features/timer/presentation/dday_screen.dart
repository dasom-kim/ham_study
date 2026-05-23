import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/study_provider.dart';

class DdayScreen extends ConsumerWidget {
  const DdayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ddays = ref.watch(ddaysProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    if (ddays.isEmpty) {
      return Scaffold(
        backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📅🐹', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                '아직 등록된 디데이가 없어요!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '중요한 시험이나 목표를 추가하고 관리해보세요!',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showDdayDialog(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('새 디데이 추가하기',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            ...ddays.map((dday) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final targetDate =
                  DateTime(dday.date.year, dday.date.month, dday.date.day);
              final diff = targetDate.difference(today).inDays;

              String ddayText = '';
              if (diff > 0) {
                ddayText = 'D-$diff';
              } else if (diff == 0) {
                ddayText = 'D-Day';
              } else {
                ddayText = 'D+${-diff}';
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        dday.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: dday.isFavorite
                            ? Colors.amber
                            : Colors.grey.shade400,
                        size: 28,
                      ),
                      onPressed: () => ref
                          .read(ddaysProvider.notifier)
                          .toggleFavorite(dday.id),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dday.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(DateFormat('yyyy.MM.dd').format(dday.date),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(ddayText,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.deepOrange)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _showDdayDialog(context, ref, dday),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: CircleAvatar(
                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                child: Icon(Icons.add,
                    color: isDarkMode ? Colors.white54 : Colors.black54),
              ),
              title: const Text('새 디데이 추가하기',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _showDdayDialog(context, ref, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDdayDialog(
      BuildContext context, WidgetRef ref, Dday? dday) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DdayEditDialog(dday: dday),
    );

    if (result != null) {
      final title = result['title'] as String;
      final date = result['date'] as DateTime;

      if (dday == null) {
        ref.read(ddaysProvider.notifier).addDday(title, date);
      } else {
        ref.read(ddaysProvider.notifier).updateDday(dday.id, title, date);
      }
    }
  }
}

class _DdayEditDialog extends StatefulWidget {
  final Dday? dday;
  const _DdayEditDialog({this.dday});

  @override
  State<_DdayEditDialog> createState() => _DdayEditDialogState();
}

class _DdayEditDialogState extends State<_DdayEditDialog> {
  late TextEditingController _titleController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.dday?.title ?? '');
    _selectedDate = widget.dday?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(widget.dday == null ? '디데이 추가' : '디데이 수정',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
                labelText: '시험/목표 이름', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text('날짜 선택', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: isDarkMode
                          ? const ColorScheme.dark(primary: Colors.deepOrange)
                          : const ColorScheme.light(
                              primary: Colors.deepOrange,
                              onPrimary: Colors.white,
                              onSurface: Colors.black87,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('yyyy년 MM월 dd일').format(_selectedDate)),
                  const Icon(Icons.calendar_today,
                      size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.dday != null)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소')),
                    Consumer(builder: (context, ref, _) {
                      return TextButton(
                        onPressed: () {
                          ref
                              .read(ddaysProvider.notifier)
                              .deleteDday(widget.dday!.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('삭제',
                            style: TextStyle(color: Colors.red)),
                      );
                    }),
                  ],
                ),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(context,
                {'title': _titleController.text.trim(), 'date': _selectedDate});
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
