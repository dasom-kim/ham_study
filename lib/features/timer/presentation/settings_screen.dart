import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/study_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '기본 설정',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: const Text('다크 모드',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: CircleAvatar(
                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                child: Icon(Icons.dark_mode,
                    color: isDarkMode ? Colors.white54 : Colors.black54),
              ),
              value: isDarkMode,
              onChanged: (value) =>
                  ref.read(isDarkModeProvider.notifier).toggle(value),
            ),
          ],
        ),
      ),
    );
  }
}
