import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/error/app_exception.dart';

class AppSupabaseClient {
  bool get isConfigured =>
      AppConstants.supabaseUrl.isNotEmpty &&
      AppConstants.supabaseAnonKey.isNotEmpty;

  Future<void> init() async {
    if (!isConfigured) {
      throw const NetworkException(
        'Supabase URL/anon key not set (expected via --dart-define).',
      );
    }
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  Future<void> ping() async {
    try {
      if (!isConfigured) {
        throw const NetworkException(
          'Supabase URL/anon key not set (expected via --dart-define).',
        );
      }
      // Lightweight connectivity check — reads model_versions, which has
      // an open "authenticated users can read" policy, so this also
      // proves auth/session wiring works once auth is added.
      await client.from('model_versions').select('id').limit(1);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Supabase ping failed', cause: e);
    }
  }
}