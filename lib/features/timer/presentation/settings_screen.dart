import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/study_provider.dart';
import '../../../app/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final authState = ref.watch(authStateProvider);
    // authState.value가 null이면 로딩 또는 비로그인, 익명이면 연동필요, 아니면 로그인됨
    final user = authState.value;
    final isSyncing = ref.watch(cloudSyncProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? null : const Color(0xFFFFF9F2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '계정 관리',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            if (user == null || user.isAnonymous) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.login),
                title: const Text('구글 계정으로 동기화하기',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () =>
                    ref.read(authProvider.notifier).linkGoogleAccount(),
              ),
              // 애플 로그인은 애플 개발자 프로그램 가입 필요로 임시 주석 처리
              // ListTile(
              //   contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              //   leading: const Icon(Icons.apple),
              //   title: const Text('애플 계정으로 동기화하기',
              //       style: TextStyle(fontWeight: FontWeight.bold)),
              //   onTap: () => ref.read(authProvider.notifier).linkAppleAccount(),
              // ),
            ] else ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: CircleAvatar(
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child:
                      user.photoURL == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.displayName ?? user.email ?? '사용자',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('안전하게 연동되어 있습니다.'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                title: const Text('클라우드에 데이터 백업'),
                trailing: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: isSyncing
                    ? null
                    : () async {
                        await ref
                            .read(cloudSyncProvider.notifier)
                            .backupToCloud();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('백업이 완료되었습니다.')));
                        }
                      },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.cloud_download, color: Colors.green),
                title: const Text('클라우드에서 데이터 복원'),
                trailing: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: isSyncing
                    ? null
                    : () async {
                        await ref
                            .read(cloudSyncProvider.notifier)
                            .restoreFromCloud();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('복원이 완료되었습니다.')));
                        }
                      },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text('로그아웃'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('로그아웃'),
                      content: const Text(
                          '로그아웃 하시겠습니까?\n로그아웃 후 새로운 연동을 시작할 수 있습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).signOut();
                            Navigator.pop(ctx);
                          },
                          child: const Text('로그아웃',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('계정 탈퇴', style: TextStyle(color: Colors.red)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('계정 탈퇴'),
                      content:
                          const Text('정말로 탈퇴하시겠습니까?\n계정 정보가 삭제되며 되돌릴 수 없습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).deleteAccount();
                            Navigator.pop(ctx);
                          },
                          child: const Text('탈퇴',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '기본 설정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: const Text(
                '다크 모드',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              secondary: CircleAvatar(
                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                child: Icon(
                  Icons.dark_mode,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
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
