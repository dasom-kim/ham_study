abstract interface class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signInWithKakao();
  Future<void> signOut();
}
