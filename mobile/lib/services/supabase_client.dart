// PLACEHOLDER Supabase client. Do not put real keys here.
import '../core/constants/app_constants.dart';
import '../core/error/app_exception.dart';

class AppSupabaseClient {
  bool get isConfigured =>
      AppConstants.supabaseUrl.isNotEmpty &&
      AppConstants.supabaseAnonKey.isNotEmpty;

  Future<void> ping() async {
    try {
      if (!isConfigured) {
        throw const NetworkException(
          'Supabase URL/anon key not set (expected via --dart-define).',
        );
      }
      // PLACEHOLDER: real client init happens in a later slice.
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Supabase ping failed', cause: e);
    }
  }
}
