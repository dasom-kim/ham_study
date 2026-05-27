import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/study_provider.dart';
import '../../../app/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLoginModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '계정을 연동하고 데이터를 안전하게 백업하세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                // 구글 로그인 버튼
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // 모달 닫기
                    try {
                      await ref.read(authProvider.notifier).linkGoogleAccount();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('구글 계정으로 연동되었습니다.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('연동 실패: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.login, color: Colors.black87),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Google 계정으로 계속하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 추후 애플, 카카오 로그인 버튼 추가를 위한 공간 (예: const SizedBox(height: 12), Apple Login Button...)
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final user =
        ref.watch(authProvider); // authStateProvider 대신 동기화된 authProvider 직접 참조
    final isSyncing = ref.watch(cloudSyncProvider);
    final lastBackupTime = ref.watch(lastBackupTimeProvider);

    // 연동된 계정 정보 추출 로직 (익명 계정 연동 시 기본 user 객체 정보가 비어있을 수 있으므로 providerData 확인)
    String accountDisplay = '';
    if (user != null && !user.isAnonymous) {
      for (final info in user.providerData) {
        if (info.email != null && info.email!.isNotEmpty) {
          accountDisplay = info.email!;
          break;
        } else if (info.displayName != null && info.displayName!.isNotEmpty) {
          accountDisplay = info.displayName!;
          break;
        }
      }
      if (accountDisplay.isEmpty) {
        accountDisplay = user.email ?? user.displayName ?? 'Google 연동 계정';
      }
    }

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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              clipBehavior:
                  Clip.antiAlias, // 클릭 시 물결 효과(Ripple)가 둥근 모서리를 넘어가지 않게 함
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null && !user.isAnonymous) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '연결된 계정',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            accountDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  if (user == null || user.isAnonymous)
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading: const Icon(Icons.login),
                      title: const Text(
                        '로그인',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _showLoginModal(context, ref),
                    )
                  else ...[
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading:
                          const Icon(Icons.cloud_upload, color: Colors.blue),
                      title: const Text('클라우드에 데이터 백업'),
                      subtitle: lastBackupTime != null
                          ? Text(
                              '최근 백업: ${DateFormat('yyyy.MM.dd HH:mm').format(lastBackupTime)}',
                              style: const TextStyle(fontSize: 12),
                            )
                          : const Text('아직 백업된 데이터가 없습니다.',
                              style: TextStyle(fontSize: 12)),
                      trailing: isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: isSyncing
                          ? null
                          : () async {
                              await ref
                                  .read(cloudSyncProvider.notifier)
                                  .backupToCloud();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('백업이 완료되었습니다.')),
                                );
                              }
                            },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading:
                          const Icon(Icons.cloud_download, color: Colors.green),
                      title: const Text('클라우드에서 데이터 복원'),
                      trailing: isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: isSyncing
                          ? null
                          : () async {
                              await ref
                                  .read(cloudSyncProvider.notifier)
                                  .restoreFromCloud();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('복원이 완료되었습니다.')),
                                );
                              }
                            },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
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
            ),
            if (user != null && !user.isAnonymous) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text(
                            '로그아웃 하시겠습니까?\n로그아웃 후 새로운 연동을 시작할 수 있습니다.',
                          ),
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
                    child: const Text('로그아웃',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  const Text('|',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('계정 탈퇴'),
                          content: const Text(
                              '정말로 탈퇴하시겠습니까?\n계정 정보가 삭제되며 되돌릴 수 없습니다.'),
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
                    child: const Text('계정 탈퇴',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
