import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_constants.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      publishableKey: SupabaseConstants.publishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
