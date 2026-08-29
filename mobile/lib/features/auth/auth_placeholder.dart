/// PLACEHOLDER auth. Real slice will use Supabase email/OTP.
class AuthSession {
  const AuthSession({required this.userId, required this.accessToken});

  final String userId;
  final String accessToken;

  static const demo = AuthSession(
    userId: '00000000-0000-0000-0000-000000000001',
    accessToken: 'demo-bearer-token',
  );
}
