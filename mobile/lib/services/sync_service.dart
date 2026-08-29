// PLACEHOLDER upload of trajectory points to FastAPI.
import '../core/error/app_exception.dart';
import '../features/auth/auth_placeholder.dart';
import '../features/trips/domain/trip.dart';

class SyncService {
  SyncService({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<void> uploadPoints({
    required String tripId,
    required List<TrajectoryPoint> points,
    AuthSession session = AuthSession.demo,
  }) async {
    try {
      // PLACEHOLDER: real http POST in a later slice.
      if (points.isEmpty) return;
      if (session.accessToken.isEmpty) {
        throw const AuthException('Missing access token');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Failed to sync trip points', cause: e);
    }
  }
}
