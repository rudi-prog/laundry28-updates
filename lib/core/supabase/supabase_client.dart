import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_constants.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      publishableKey: SupabaseConstants.publishableKey,
      // Item #15: Konfigurasi OAuth flow untuk web & mobile
      // - authFlowType: pkce (Proof Key for Code Exchange) — lebih aman daripada implicit flow
      // - detectSessionInUri: true — otomatis detect OAuth callback URL dan exchange code ke session
      // Tanpa ini, OAuth callback di web tidak akan bekerja!
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
