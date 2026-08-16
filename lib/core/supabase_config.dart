import 'package:supabase_flutter/supabase_flutter.dart';

/// URL et clé passées au build, jamais en dur dans le code :
/// flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY manquants. '
        'Lancez avec --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
