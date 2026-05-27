import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// 로그인 상태를 감지하는 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    // Firebase Auth 상태 변화를 구독하여 상태 동기화 (앱 재시작 시 정보 누락 방지)
    final sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      state = user;
    });
    ref.onDispose(sub.cancel);

    return FirebaseAuth.instance.currentUser;
  }

  // 익명 로그인 (앱 최초 진입 시, 예를 들어 main.dart 등에서 호출 필요)
  Future<void> signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      state = userCredential.user;
    } catch (e) {
      print('익명 로그인 실패: $e');
    }
  }

  // 구글 계정 연동 / 로그인 — 실패 시 예외를 throw해 호출부에서 처리
  Future<void> linkGoogleAccount() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // 사용자가 취소

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Google ID 토큰을 가져오지 못했습니다. 잠시 후 다시 시도해주세요.');
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _linkOrSignIn(credential);
  }

  // 애플 계정 연동 / 로그인
  // Future<void> linkAppleAccount() async {
  //   try {
  //     final appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     final AuthCredential credential = OAuthProvider('apple.com').credential(
  //       idToken: appleCredential.identityToken,
  //       accessToken: appleCredential.authorizationCode,
  //     );

  //     await _linkOrSignIn(credential);
  //   } catch (e) {
  //     print("애플 로그인/연동 실패: $e");
  //   }
  // }

  Future<void> _linkOrSignIn(AuthCredential credential) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        // 기존 익명 계정에 구글/애플 인증 정보를 연결 (데이터 유지 핵심 로직)
        final userCredential = await currentUser.linkWithCredential(credential);
        state = userCredential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          // 이미 가입/연동된 구글 계정인 경우, 에러 없이 해당 계정으로 바로 로그인 처리
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          state = userCredential.user;
        } else {
          rethrow; // 다른 에러는 위로 던져서 catch에서 출력하게 함
        }
      }
    } else {
      // 익명 로그인이 아닌 상태이거나 로컬 세션이 없는 경우 일반 로그인 처리
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      state = userCredential.user;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut(); // 다음에 다른 구글 계정으로 로그인할 수 있도록 세션 초기화
      await FirebaseAuth.instance.signOut();

      // 로그아웃 후에도 앱을 사용할 수 있도록 바로 새로운 익명 계정 발급
      await signInAnonymously();
    } catch (e) {
      print('로그아웃 실패: $e');
    }
  }

  // 계정 탈퇴
  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete(); // Firebase 서버에서 유저 정보 삭제
        await GoogleSignIn().signOut();

        // 탈퇴 후 빈 화면 방지를 위해 새로운 익명 계정 발급
        await signInAnonymously();
      }
    } catch (e) {
      print('계정 삭제 실패: $e');
      // 참고: 보안상 '최근 로그인(requires-recent-login)'이 안 되어 있으면 에러가 날 수 있습니다.
      // 실제 출시할 때는 에러 발생 시 재로그인을 요구하는 로직이 추가로 필요할 수 있습니다.
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
